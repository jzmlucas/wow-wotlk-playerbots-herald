. "$PSScriptRoot\Common.ps1"
Write-Section 'Pré-requisitos para AzerothCore Playerbots no Windows'
$issues = [Collections.Generic.List[string]]::new()

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { $issues.Add('Windows 10/11 x64 é necessário para estes scripts.') }
foreach ($tool in @('git', 'cmake')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { $issues.Add("Não encontrado no PATH: $tool") }
}
$mysqlRoot = Get-MySqlRoot
foreach ($tool in @('mysql.exe', 'mysqld.exe', 'mysqldump.exe')) {
    if (-not (Test-Path (Join-Path $mysqlRoot "bin/$tool"))) { $issues.Add("MySQL 8.4 incompleto: $mysqlRoot\bin\$tool") }
}
$boostRoot = $env:BOOST_ROOT
if (-not $boostRoot -or -not (Test-Path (Join-Path $boostRoot 'boost/version.hpp'))) {
    $issues.Add('Boost 1.78–1.83 não encontrado. Use Preparar dependências no launcher para baixar e configurar.')
}
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) { $issues.Add('Visual Studio 2022 com workload Desenvolvimento para desktop com C++ é necessário.') }
else {
    $vs = & $vswhere -latest -products '*' -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { $issues.Add('Workload C++ do Visual Studio não foi encontrado.') }
}
if (-not $env:OPENSSL_ROOT_DIR -or -not (Test-Path (Join-Path $env:OPENSSL_ROOT_DIR 'include/openssl/ssl.h'))) {
    $issues.Add('OpenSSL 3.x x64 não encontrado. Use Preparar dependências no launcher para baixar e configurar.')
}
if ($issues.Count) {
    Write-Host 'Pendências:' -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host " - $_" }
    Write-Host 'Execute scripts/00-preparar-dependencias.ps1 pelo launcher para baixar/instalar os componentes ausentes.'
    throw 'Há dependências necessárias ausentes.'
}
Write-Host "Dependências básicas encontradas. MySQL: $mysqlRoot; Boost: $boostRoot; OpenSSL: $env:OPENSSL_ROOT_DIR." -ForegroundColor Green
