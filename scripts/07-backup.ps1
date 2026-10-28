. "$PSScriptRoot\Common.ps1"
if (Get-ServerProcesses) { throw 'Encerre authserver e worldserver antes do backup para consistência.' }
if (-not (Get-Command mysqldump -ErrorAction SilentlyContinue)) { throw 'mysqldump não está no PATH.' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dest = Get-KitPath "servidor/backups/$stamp"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$clientIni = Get-KitPath 'servidor/mysql/acore-client.ini'
if (-not (Test-Path $clientIni)) { throw 'Credencial local MySQL ausente. Execute scripts/10-configurar-mysql.ps1.' }
$dbs = @('acore_auth','acore_characters','acore_world','acore_playerbots')
foreach ($db in $dbs) {
    $file = Join-Path $dest "$db.sql"
    Write-Host "Dump de $db..."
    Invoke-External mysqldump @("--defaults-extra-file=$clientIni", '--single-transaction', '--routines', '--triggers', '--hex-blob', '--databases', $db, "--result-file=$file")
    if (-not (Test-Path $file) -or (Get-Item $file).Length -lt 128) { throw "Dump não foi gerado corretamente: $db" }
}
$cfg = Get-KitPath 'servidor/run/configs'
if (Test-Path $cfg) { Copy-Item $cfg (Join-Path $dest 'configs') -Recurse -Force }
$lock = Get-KitPath 'servidor/fontes.lock.json'
if (Test-Path $lock) { Copy-Item $lock $dest }
Write-Host "Backup criado em $dest. Ele contém configurações privadas; armazene com cuidado." -ForegroundColor Green
