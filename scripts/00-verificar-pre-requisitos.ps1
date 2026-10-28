. "$PSScriptRoot\Common.ps1"
Write-Section 'Pré-requisitos para AzerothCore Playerbots no Windows'
$issues = [Collections.Generic.List[string]]::new()

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { $issues.Add('Windows 10/11 é necessário para estes scripts.') }
foreach ($tool in @('git', 'cmake', 'mysql', 'mysqldump')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { $issues.Add("Não encontrado no PATH: $tool") }
}
if (-not $env:BOOST_ROOT -or -not (Test-Path (Join-Path $env:BOOST_ROOT 'boost/version.hpp'))) {
    $issues.Add('Defina BOOST_ROOT para uma instalação de Boost compatível (1.78–1.83).')
}
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) { $issues.Add('Visual Studio 2022 com workload Desenvolvimento para desktop com C++ é necessário.') }
else {
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { $issues.Add('Workload C++ do Visual Studio não foi encontrado.') }
}
if (-not $env:OPENSSL_ROOT_DIR -or -not (Test-Path (Join-Path $env:OPENSSL_ROOT_DIR 'include/openssl/ssl.h'))) {
    $issues.Add('Instale OpenSSL 3.x e configure OPENSSL_ROOT_DIR ou PATH.')
}
if (-not (Get-Command mysql -ErrorAction SilentlyContinue)) { Write-Host 'MySQL 8.4 LTS Client/Server: instale e adicione bin ao PATH.' }
if ($issues.Count) {
    Write-Host 'Pendências:' -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host " - $_" }
    Write-Host 'Consulte docs/01-preparar-o-windows.md.'
    exit 1
}
Write-Host 'Dependências básicas encontradas. Confirme as versões de Boost, MySQL, OpenSSL e CMake no guia.' -ForegroundColor Green
