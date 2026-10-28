param([switch]$RefreshPins)
. "$PSScriptRoot\Common.ps1"
if (-not $RefreshPins) { throw 'Atualização só é executada com -RefreshPins explícito.' }
if (Get-ServerProcesses) { throw 'Encerre os serviços antes de atualizar fontes.' }
$backupScript = Join-Path $PSScriptRoot '07-backup.ps1'
& $backupScript
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Backup falhou; atualização cancelada.' }
& (Join-Path $PSScriptRoot '01-baixar-fontes.ps1') -RefreshPins
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Atualização das fontes falhou.' }
Write-Host 'Fontes atualizadas e lock renovado. Revise changelogs e rode scripts/02-compilar-servidor.ps1.' -ForegroundColor Yellow
