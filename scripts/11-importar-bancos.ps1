. "$PSScriptRoot\Common.ps1"
$run = Get-KitPath 'servidor/run'
$dbimport = Join-Path $run 'dbimport.exe'
if (-not (Test-Path $dbimport)) { throw 'dbimport.exe ausente. Compile novamente com scripts/02-compilar-servidor.ps1.' }
if (-not (Test-Path (Join-Path $run 'configs/dbimport.conf'))) { throw 'Configuração do dbimport ausente. Execute scripts/04-configurar-servidor.ps1.' }
& (Join-Path $PSScriptRoot '10-configurar-mysql.ps1')
Invoke-External $dbimport @('--config', (Join-Path $run 'configs/dbimport.conf')) $run
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'dbimport encontrou falhas. Confira os logs do run e corrija antes de iniciar.' }
Write-Host 'Bases auth, characters, world e SQL dos módulos atualizadas.' -ForegroundColor Green
