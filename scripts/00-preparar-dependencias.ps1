$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"
Add-Type -AssemblyName System.Windows.Forms

function Confirm-Install([string]$Name, [string]$Details) {
    Write-Host "Dependência ausente: $Name. O launcher vai baixar o instalador e pedir que você conclua a instalação."
    $answer = [Windows.Forms.MessageBox]::Show(
        "$Name está ausente ou incompleto.`r`n`r`n$Details`r`n`r`nO launcher baixará os arquivos necessários e abrirá a instalação. Confirma para prosseguir?",
        "Instalar dependência — $Name", 'YesNo', 'Information')
    if ($answer -ne [Windows.Forms.DialogResult]::Yes) { throw "Instalação de $Name cancelada pelo usuário." }
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Install-WinGetPackage([string]$Name, [string]$PackageId) {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) { throw 'O Windows Package Manager (winget) não foi encontrado. Instale o App Installer da Microsoft pela Microsoft Store e execute a verificação novamente.' }
    Confirm-Install $Name "Pacote: $PackageId (catálogo do Windows Package Manager)."
    Write-Host "Baixando e iniciando a instalação de $Name ($PackageId)…"
    $process = Start-Process -FilePath $winget.Source -ArgumentList @(
        'install', '--exact', '--id', $PackageId, '--source', 'winget',
        '--interactive', '--accept-source-agreements', '--accept-package-agreements'
    ) -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) { throw "A instalação de $Name falhou (winget código $($process.ExitCode))." }
    Refresh-Path
}

function Set-UserDependencyPath([string]$Name, [string]$Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
    Write-Host "$Name definido para esta conta: $Value"
}

function Find-BoostRoot {
    $candidates = @(
        $env:BOOST_ROOT,
        [Environment]::GetEnvironmentVariable('BOOST_ROOT', 'User'),
        (Join-Path $script:ServerRoot 'deps/boost_1_83_0'),
        'C:\local\boost_1_83_0', 'C:\Boost\boost_1_83_0',
        'C:\Program Files\Boost\boost_1_83_0'
    ) | Where-Object { $_ }
    foreach ($candidate in $candidates) {
        $versionFile = Join-Path $candidate 'boost/version.hpp'
        if (Test-Path $versionFile) {
            $versionText = Get-Content -LiteralPath $versionFile -Raw
            if ($versionText -match '(?m)^\s*#\s*define\s+BOOST_VERSION\s+(\d+)') {
                $version = [int]$Matches[1]
                if ($version -ge 107800 -and $version -le 108300) { return (Resolve-Path $candidate).Path }
            }
        }
    }
    return $null
}

function Find-OpenSslRoot {
    $candidates = @(
        $env:OPENSSL_ROOT_DIR,
        [Environment]::GetEnvironmentVariable('OPENSSL_ROOT_DIR', 'User'),
        (Join-Path $script:ServerRoot 'tools/vcpkg/installed/x64-windows'),
        'C:\OpenSSL-Win64', 'C:\Program Files\OpenSSL-Win64',
        'C:\Program Files\OpenSSL'
    ) | Where-Object { $_ }
    foreach ($candidate in $candidates) {
        $versionHeader = Join-Path $candidate 'include/openssl/opensslv.h'
        if ((Test-Path (Join-Path $candidate 'include/openssl/ssl.h')) -and
            (Test-Path $versionHeader) -and
            (Select-String -LiteralPath $versionHeader -Pattern '^#\s*define\s+OPENSSL_VERSION_MAJOR\s+3\b' -Quiet)) {
            return (Resolve-Path $candidate).Path
        }
    }
    return $null
}

function Get-VsWhere {
    return (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe')
}

function Test-VsCpp {
    $vswhere = Get-VsWhere
    if (-not (Test-Path $vswhere)) { return $false }
    $vsPath = & $vswhere -latest -products '*' -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    return [bool]$vsPath
}

function Install-VisualStudioCpp {
    Confirm-Install 'Visual Studio Community 2022 — C++' 'Instala o compilador C++ de 64 bits e as ferramentas exigidas para compilar o servidor. O instalador da Microsoft pode solicitar elevação do Windows.'
    $vswhere = Get-VsWhere
    $existingVs = $null
    if (Test-Path $vswhere) { $existingVs = & $vswhere -latest -products '*' -version '[17.0,18.0)' -property installationPath }
    if ($existingVs) {
        $installer = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vs_installer.exe'
        if (-not (Test-Path $installer)) { throw 'Visual Studio 2022 existe, mas o Visual Studio Installer não foi encontrado para adicionar o workload C++.' }
        Write-Host 'Abrindo o Visual Studio Installer para adicionar Desenvolvimento para desktop com C++…'
        $process = Start-Process -FilePath $installer -ArgumentList @('modify', '--installPath', $existingVs, '--add', 'Microsoft.VisualStudio.Workload.NativeDesktop', '--includeRecommended', '--wait') -Wait -PassThru
        if ($process.ExitCode -ne 0 -or -not (Test-VsCpp)) { throw 'Não foi possível adicionar o workload C++ ao Visual Studio 2022.' }
        return
    }
    $downloadRoot = Join-Path $env:LOCALAPPDATA 'SoloRealm\downloads'
    New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null
    $bootstrapper = Join-Path $downloadRoot 'vs_Community.exe'
    Write-Host 'Baixando o instalador oficial do Visual Studio 2022 da Microsoft…'
    Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_Community.exe' -OutFile $bootstrapper -UseBasicParsing
    Write-Host 'Abrindo a instalação do Visual Studio com a carga Desenvolvimento para desktop com C++…'
    $process = Start-Process -FilePath $bootstrapper -ArgumentList @('--add', 'Microsoft.VisualStudio.Workload.NativeDesktop', '--includeRecommended', '--wait') -Wait -PassThru
    if ($process.ExitCode -ne 0 -or -not (Test-VsCpp)) { throw 'O workload C++ do Visual Studio não foi instalado. Conclua a instalação no Visual Studio Installer e tente novamente.' }
}

function Install-MySqlZip {
    $mysqlVersion = '8.4.13'
    $mysqlName = "MySQL Community Server $mysqlVersion (arquivo portátil, sem serviço do Windows)"
    Confirm-Install $mysqlName 'O arquivo oficial da Oracle será baixado e extraído dentro da pasta ignorada servidor/tools deste kit. A instalação não cria nem inicia um serviço global do MySQL.'
    $downloadRoot = Join-Path $env:LOCALAPPDATA 'SoloRealm\downloads'
    $destination = Join-Path $script:ServerRoot "tools/mysql-$mysqlVersion-winx64"
    $archive = Join-Path $downloadRoot "mysql-$mysqlVersion-winx64.zip"
    New-Item -ItemType Directory -Force -Path $downloadRoot,(Split-Path -Parent $destination) | Out-Null
    Write-Host "Baixando MySQL $mysqlVersion da Oracle (ZIP para Windows x64)…"
    Invoke-WebRequest -Uri "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-$mysqlVersion-winx64.zip" -OutFile $archive -UseBasicParsing
    Write-Host 'Extraindo MySQL para servidor/tools…'
    Expand-Archive -LiteralPath $archive -DestinationPath (Split-Path -Parent $destination) -Force
    if (-not (Test-Path (Join-Path $destination 'bin/mysqld.exe'))) { throw "MySQL não foi extraído corretamente em $destination." }
    $env:SOLOREALM_MYSQL_ROOT = $destination
    [Environment]::SetEnvironmentVariable('SOLOREALM_MYSQL_ROOT', $destination, 'User')
}

function Install-BoostBinary {
    Confirm-Install 'Boost 1.83.0 para Visual Studio 2022 x64' 'O instalador binário (aprox. 200 MB) será baixado. Ao final, selecione a pasta instalada que contém boost\version.hpp. O caminho ficará configurado para as próximas execuções.'
    $downloadRoot = Join-Path $env:LOCALAPPDATA 'SoloRealm\downloads'
    New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null
    $installer = Join-Path $downloadRoot 'boost_1_83_0-msvc-14.3-64.exe'
    Write-Host 'Baixando Boost 1.83.0, binário compatível com o toolset MSVC do Visual Studio 2022…'
    Invoke-WebRequest -Uri 'https://boost.teeks99.com/bin/1.83.0/boost_1_83_0-msvc-14.3-64.exe' -OutFile $installer -UseBasicParsing
    Write-Host 'Abrindo o instalador do Boost. Conclua a instalação para continuar…'
    $process = Start-Process -FilePath $installer -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "O instalador do Boost terminou com código $($process.ExitCode)." }
    $boostRoot = Find-BoostRoot
    if (-not $boostRoot) {
        $dialog = [Windows.Forms.FolderBrowserDialog]::new()
        $dialog.Description = 'Selecione a pasta do Boost 1.83.0 que contém a subpasta boost e o arquivo boost\version.hpp.'
        $dialog.ShowNewFolderButton = $false
        if ($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw 'Seleção da pasta do Boost cancelada.' }
        $boostRoot = $dialog.SelectedPath
    }
    $versionFile = Join-Path $boostRoot 'boost/version.hpp'
    $versionText = if (Test-Path $versionFile) { Get-Content -LiteralPath $versionFile -Raw } else { '' }
    if ($versionText -notmatch '(?m)^\s*#\s*define\s+BOOST_VERSION\s+(\d+)') { throw "Pasta Boost inválida: $boostRoot" }
    $version = [int]$Matches[1]
    if ($version -lt 107800 -or $version -gt 108300) { throw "Boost incompatível. Use a versão 1.78–1.83; pasta selecionada: $boostRoot" }
    Set-UserDependencyPath 'BOOST_ROOT' $boostRoot
}

function Set-OpenSslRoot {
    $root = Find-OpenSslRoot
    if ($root) { Set-UserDependencyPath 'OPENSSL_ROOT_DIR' $root; return }
    $dialog = [Windows.Forms.FolderBrowserDialog]::new()
    $dialog.Description = 'Selecione a pasta do OpenSSL 3.x que contém include\openssl\ssl.h.'
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw 'Seleção da pasta do OpenSSL cancelada.' }
    $versionHeader = Join-Path $dialog.SelectedPath 'include/openssl/opensslv.h'
    if (-not (Test-Path (Join-Path $dialog.SelectedPath 'include/openssl/ssl.h')) -or
        -not (Test-Path $versionHeader) -or
        -not (Select-String -LiteralPath $versionHeader -Pattern '^#\s*define\s+OPENSSL_VERSION_MAJOR\s+3\b' -Quiet)) {
        throw "Selecione a pasta de uma instalação OpenSSL 3.x x64 válida: $($dialog.SelectedPath)"
    }
    Set-UserDependencyPath 'OPENSSL_ROOT_DIR' $dialog.SelectedPath
}

function Test-MySql {
    $mysqlRoot = Get-MySqlRoot
    return (Test-Path (Join-Path $mysqlRoot 'bin/mysql.exe')) -and (Test-Path (Join-Path $mysqlRoot 'bin/mysqld.exe')) -and (Test-Path (Join-Path $mysqlRoot 'bin/mysqldump.exe'))
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Este launcher e este servidor são somente para Windows 10/11 x64.' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Section 'Detectar, baixar e instalar dependências do Windows'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Install-WinGetPackage 'Git for Windows' 'Git.Git' }
if (-not (Get-Command cmake -ErrorAction SilentlyContinue) -and -not (Test-Path 'C:\Program Files\CMake\bin\cmake.exe')) { Install-WinGetPackage 'CMake x64' 'Kitware.CMake' }
if (-not (Test-VsCpp)) { Install-VisualStudioCpp }
if (-not (Test-MySql)) { Install-MySqlZip }
if (-not (Find-OpenSslRoot)) {
    Install-WinGetPackage 'OpenSSL 3.x completo x64' 'ShiningLight.OpenSSL.Dev'
    Set-OpenSslRoot
} elseif (-not $env:OPENSSL_ROOT_DIR) { Set-OpenSslRoot }
if (-not (Find-BoostRoot)) { Install-BoostBinary }
else { Set-UserDependencyPath 'BOOST_ROOT' (Find-BoostRoot) }

Write-Host 'Conferindo os pré-requisitos instalados…'
& (Join-Path $PSScriptRoot '00-verificar-pre-requisitos.ps1')
Write-Host 'Todas as dependências necessárias estão prontas.' -ForegroundColor Green
