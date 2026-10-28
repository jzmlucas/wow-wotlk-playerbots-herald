Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:KitRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:ServerRoot = Join-Path $script:KitRoot 'servidor'
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path = (@($machinePath -split ';') + @($userPath -split ';') + @($env:Path -split ';') | Where-Object { $_ } | Select-Object -Unique) -join ';'
$cmakeBin = 'C:\Program Files\CMake\bin'
$mysqlRootForPath = $env:SOLOREALM_MYSQL_ROOT
if (-not $mysqlRootForPath) { $mysqlRootForPath = [Environment]::GetEnvironmentVariable('SOLOREALM_MYSQL_ROOT', 'User') }
if (-not $mysqlRootForPath -or -not (Test-Path (Join-Path $mysqlRootForPath 'bin/mysqld.exe'))) { $mysqlRootForPath = Join-Path $script:ServerRoot 'tools/mysql-8.4.13-winx64' }
if (-not (Test-Path (Join-Path $mysqlRootForPath 'bin/mysqld.exe'))) { $mysqlRootForPath = 'C:\Program Files\MySQL\MySQL Server 8.4' }
$mysqlBin = Join-Path $mysqlRootForPath 'bin'
foreach ($bin in @($cmakeBin,$mysqlBin)) {
    if ((Test-Path $bin) -and $env:PATH -notlike "*$bin*") { $env:PATH = "$bin;$env:PATH" }
}

function Get-MySqlRoot {
    foreach ($candidate in @(
        $env:SOLOREALM_MYSQL_ROOT,
        [Environment]::GetEnvironmentVariable('SOLOREALM_MYSQL_ROOT', 'User'),
        (Join-Path $script:ServerRoot 'tools/mysql-8.4.13-winx64'),
        'C:\Program Files\MySQL\MySQL Server 8.4'
    ) | Where-Object { $_ }) {
        if (Test-Path (Join-Path $candidate 'bin/mysqld.exe')) { return $candidate }
    }
    return (Join-Path $script:ServerRoot 'tools/mysql-8.4.13-winx64')
}
if (-not $env:BOOST_ROOT) {
    $boostCandidates = @([Environment]::GetEnvironmentVariable('BOOST_ROOT', 'User'), (Join-Path $script:ServerRoot 'deps/boost_1_83_0'), 'C:\local\boost_1_83_0', 'C:\Boost\boost_1_83_0')
    foreach ($localBoost in $boostCandidates) {
        if ($localBoost -and (Test-Path (Join-Path $localBoost 'boost/version.hpp'))) { $env:BOOST_ROOT = $localBoost; break }
    }
}
if (-not $env:OPENSSL_ROOT_DIR) {
    foreach ($candidate in @([Environment]::GetEnvironmentVariable('OPENSSL_ROOT_DIR', 'User'), (Join-Path $script:ServerRoot 'tools/vcpkg/installed/x64-windows'),'C:\OpenSSL-Win64','C:\Program Files\OpenSSL-Win64','C:\Program Files\OpenSSL')) {
        if (Test-Path (Join-Path $candidate 'include/openssl/ssl.h')) { $env:OPENSSL_ROOT_DIR = $candidate; break }
    }
}

function Get-KitPath([string]$RelativePath) {
    return [IO.Path]::GetFullPath((Join-Path $script:KitRoot $RelativePath))
}

function Assert-UnderKit([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($script:KitRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Caminho fora do kit recusado: $full"
    }
}

function Invoke-External([string]$File, [string[]]$Arguments, [string]$WorkingDirectory = $script:KitRoot) {
    Write-Host "> $File $($Arguments -join ' ')" -ForegroundColor DarkGray
    Push-Location $WorkingDirectory
    try {
        & $File @Arguments
        if ($LASTEXITCODE -ne 0) { throw "Comando terminou com código ${LASTEXITCODE}: $File" }
    }
    finally { Pop-Location }
}

function Read-JsonFile([string]$Path) {
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-ServerProcesses {
    $names = @('authserver', 'worldserver')
    return @(Get-Process -Name $names -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and $_.Path.StartsWith($script:ServerRoot, [StringComparison]::OrdinalIgnoreCase)
    } | ForEach-Object {
        [pscustomobject]@{ ProcessId=$_.Id; Name=$_.ProcessName; ExecutablePath=$_.Path }
    })
}

function Write-Section([string]$Message) {
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}
