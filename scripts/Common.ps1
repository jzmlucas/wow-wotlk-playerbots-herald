Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:KitRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:ServerRoot = Join-Path $script:KitRoot 'servidor'
$cmakeBin = 'C:\Program Files\CMake\bin'
$mysqlBin = 'C:\Program Files\MySQL\MySQL Server 8.4\bin'
foreach ($bin in @($cmakeBin,$mysqlBin)) {
    if ((Test-Path $bin) -and $env:PATH -notlike "*$bin*") { $env:PATH = "$bin;$env:PATH" }
}
if (-not $env:BOOST_ROOT) {
    $localBoost = Join-Path $script:ServerRoot 'deps/boost_1_83_0'
    if (Test-Path (Join-Path $localBoost 'boost/version.hpp')) { $env:BOOST_ROOT = $localBoost }
}
if (-not $env:OPENSSL_ROOT_DIR) {
    foreach ($candidate in @((Join-Path $script:ServerRoot 'tools/vcpkg/installed/x64-windows'),'C:\OpenSSL-Win64','C:\Program Files\OpenSSL-Win64')) {
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
