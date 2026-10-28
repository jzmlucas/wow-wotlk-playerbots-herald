$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$desktopProject = Join-Path $PSScriptRoot 'SoloRealm.Desktop\SoloRealm.Desktop.csproj'
$startupLog = Join-Path $PSScriptRoot 'logs\launcher-startup.log'
$desktopStdout = Join-Path $PSScriptRoot 'logs\desktop-launch.stdout.log'
$desktopStderr = Join-Path $PSScriptRoot 'logs\desktop-launch.stderr.log'

function Get-DotnetCommand {
    $localDotnet = Join-Path $env:LOCALAPPDATA 'SoloRealm\dotnet\dotnet.exe'
    if (Test-Path -LiteralPath $localDotnet) { return $localDotnet }
    $command = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    return $null
}

function Ensure-DotnetSdk {
    $dotnet = Get-DotnetCommand
    if ($dotnet) {
        $sdks = @(& $dotnet --list-sdks 2>$null)
        if ($LASTEXITCODE -eq 0 -and ($sdks | Where-Object { $_ -match '^\s*9\.' })) { return $dotnet }
    }

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $answer = [Windows.Forms.MessageBox]::Show(
        'Para abrir o launcher, é necessário baixar e instalar o SDK .NET 9 da Microsoft. A instalação será feita só para sua conta do Windows, sem alterar outras contas. Deseja continuar?',
        'Dependência necessária — .NET SDK 9', 'YesNo', 'Information')
    if ($answer -ne [Windows.Forms.DialogResult]::Yes) { throw 'Instalação do .NET SDK 9 cancelada. O launcher precisa dele para continuar.' }

    Write-Host 'Baixando o instalador oficial do .NET SDK 9 da Microsoft…'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $installRoot = Join-Path $env:LOCALAPPDATA 'SoloRealm\dotnet'
    $downloadRoot = Join-Path $env:LOCALAPPDATA 'SoloRealm\downloads'
    New-Item -ItemType Directory -Force -Path $installRoot, $downloadRoot | Out-Null
    $installerScript = Join-Path $downloadRoot 'dotnet-install.ps1'
    Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $installerScript -UseBasicParsing

    Write-Host 'Instalando o .NET SDK 9 para esta conta…'
    & $installerScript -Channel '9.0' -InstallDir $installRoot -NoPath
    $dotnet = Join-Path $installRoot 'dotnet.exe'
    $sdks = @(& $dotnet --list-sdks 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not ($sdks | Where-Object { $_ -match '^\s*9\.' })) { throw 'O SDK .NET 9 não foi localizado após a instalação.' }
    return $dotnet
}

try {
    Set-Location -LiteralPath $root
    if (-not (Test-Path -LiteralPath $desktopProject)) {
        throw "Código-fonte do launcher gráfico não encontrado: $desktopProject"
    }

    $dotnetPath = Ensure-DotnetSdk

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $desktopStdout) | Out-Null
    $projectArgument = '"{0}"' -f $desktopProject
    $process = Start-Process -FilePath $dotnetPath `
        -ArgumentList @('run', '--project', $projectArgument, '--configuration', 'Release', '--no-launch-profile') `
        -WorkingDirectory $root -WindowStyle Hidden -PassThru -Wait `
        -RedirectStandardOutput $desktopStdout -RedirectStandardError $desktopStderr
    if ($process.ExitCode -ne 0) {
        throw "A compilação/inicialização do launcher gráfico falhou (código $($process.ExitCode)). Consulte $desktopStdout e $desktopStderr."
    }
} catch {
    $message = '{0} {1}{2}{3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $_.Exception.Message, [Environment]::NewLine, $_.ScriptStackTrace
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $startupLog) | Out-Null
        [IO.File]::AppendAllText($startupLog, $message + [Environment]::NewLine + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    } catch { }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [Windows.Forms.MessageBox]::Show("O SoloRealm Control Center não conseguiu iniciar.`r`n`r`n$message`r`nLog: $startupLog", 'Falha ao abrir o SoloRealm', 'OK', 'Error') | Out-Null
    } catch {
        try {
            $shell = New-Object -ComObject WScript.Shell
            [void]$shell.Popup("Falha ao abrir o SoloRealm. Consulte o log:`r`n$startupLog", 0, 'Falha ao abrir o SoloRealm', 16)
        } catch { }
    }
    exit 1
}
