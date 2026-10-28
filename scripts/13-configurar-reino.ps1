. "$PSScriptRoot\Common.ps1"
$clientIni = Get-KitPath 'servidor/mysql/acore-client.ini'
$sqlFile = Get-KitPath 'sql/01-reino-local.sql'
$mysql = Join-Path (Join-Path (Get-MySqlRoot) 'bin') 'mysql.exe'
foreach ($path in @($clientIni,$sqlFile,$mysql)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Arquivo necessário ausente: $path" }
}

$connection = "--defaults-extra-file=$clientIni"
$sql = [IO.File]::ReadAllText($sqlFile)
$output = & $mysql $connection '--protocol=TCP' '--host=127.0.0.1' '--database=acore_auth' '--batch' '--skip-column-names' "--execute=$sql"
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível aplicar a configuração do reino local.' }

$verifySql = "SELECT COUNT(*) FROM realmlist WHERE id=1 AND name='Reino Local' AND address='127.0.0.1' AND localAddress='127.0.0.1' AND gamebuild=12340"
$result = & $mysql $connection '--protocol=TCP' '--host=127.0.0.1' '--database=acore_auth' '--batch' '--skip-column-names' "--execute=$verifySql"
if ($LASTEXITCODE -ne 0 -or (($result | Select-Object -Last 1).Trim() -ne '1')) { throw 'O reino local id=1 não foi confirmado no banco acore_auth.' }
Write-Host 'Reino Local configurado em 127.0.0.1 para o cliente 3.3.5a build 12340.' -ForegroundColor Green
