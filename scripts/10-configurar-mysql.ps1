. "$PSScriptRoot\Common.ps1"
$mysqlRoot = 'C:\Program Files\MySQL\MySQL Server 8.4'
$mysqld = Join-Path $mysqlRoot 'bin/mysqld.exe'
$mysql = Join-Path $mysqlRoot 'bin/mysql.exe'
if (-not (Test-Path $mysqld) -or -not (Test-Path $mysql)) { throw 'MySQL Server 8.4 não encontrado. Instale pelo guia de dependências.' }
$mysqlDir = Get-KitPath 'servidor/mysql'
$data = Get-KitPath 'servidor/mysql-data'
New-Item -ItemType Directory -Force -Path $mysqlDir,$data,(Join-Path $mysqlDir 'secure-files') | Out-Null
$ini = Join-Path $mysqlDir 'my.ini'
if (-not (Test-Path $ini)) {
    $iniContent = @"
[mysqld]
basedir=$($mysqlRoot -replace '\\','/')
datadir=$($data -replace '\\','/')
port=3306
bind-address=127.0.0.1
mysqlx=0
character-set-server=utf8mb4
collation-server=utf8mb4_0900_ai_ci
innodb_buffer_pool_size=8G
innodb_redo_log_capacity=1G
innodb_flush_log_at_trx_commit=2
skip-log-bin
secure-file-priv=$((Join-Path $mysqlDir 'secure-files') -replace '\\','/')
log-error=$((Join-Path $mysqlDir 'mysql.err') -replace '\\','/')
"@
    [IO.File]::WriteAllText($ini,$iniContent,[Text.UTF8Encoding]::new($false))
}
if (-not (Get-ChildItem $data -Force -ErrorAction SilentlyContinue)) {
    Write-Host 'Inicializando os dados locais do MySQL...'
    $p = Start-Process -FilePath $mysqld -ArgumentList @("--defaults-file=$ini",'--initialize-insecure') -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) { throw "Inicialização do MySQL falhou ($($p.ExitCode)); consulte $mysqlDir\mysql.err" }
}
$running = Get-Process -Name mysqld -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.Equals($mysqld,[StringComparison]::OrdinalIgnoreCase) }
if (-not $running) {
    Write-Host 'Iniciando MySQL local em background (127.0.0.1)...'
    $proc = Start-Process -FilePath $mysqld -ArgumentList "--defaults-file=`"$ini`"" -WorkingDirectory $mysqlDir -WindowStyle Hidden -PassThru
    [pscustomobject]@{pid=$proc.Id;startedAt=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $mysqlDir 'process.json') -Encoding UTF8
}
$mysqladmin = Join-Path $mysqlRoot 'bin/mysqladmin.exe'
$ready = $false
for ($attempt=0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Seconds 2
    if (Test-Path (Join-Path $mysqlDir 'root-client.ini')) {
        & $mysqladmin "--defaults-extra-file=$(Join-Path $mysqlDir 'root-client.ini')" --protocol=TCP --host=127.0.0.1 ping 2>$null | Out-Null
    } else { & $mysqladmin --protocol=TCP --host=127.0.0.1 --user=root ping 2>$null | Out-Null }
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
}
if (-not $ready) { throw "MySQL não respondeu em 127.0.0.1:3306. Consulte $mysqlDir\mysql.err" }
$rootPasswordFile = Join-Path $mysqlDir 'root-password.dpapi'
$dbPasswordFile = Join-Path $mysqlDir 'acore-password.dpapi'
if (-not (Test-Path $rootPasswordFile)) {
    function New-RandomPassword {
        $bytes = [byte[]]::new(36)
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        return [Convert]::ToBase64String($bytes)
    }
    $rootPassword = New-RandomPassword
    $dbPassword = New-RandomPassword
    $sql = @"
ALTER USER 'root'@'localhost' IDENTIFIED BY '$rootPassword';
CREATE DATABASE IF NOT EXISTS acore_auth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS acore_characters CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS acore_world CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS acore_playerbots CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'acore'@'localhost' IDENTIFIED BY '$dbPassword';
ALTER USER 'acore'@'localhost' IDENTIFIED BY '$dbPassword';
GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON acore_playerbots.* TO 'acore'@'localhost';
FLUSH PRIVILEGES;
"@
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $mysql
    $start.Arguments = '--protocol=TCP --host=127.0.0.1 --user=root --batch --skip-column-names'
    $start.WorkingDirectory = $mysqlDir
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $proc = [Diagnostics.Process]::Start($start)
    $proc.StandardInput.WriteLine($sql)
    $proc.StandardInput.Close()
    $stdout = $proc.StandardOutput.ReadToEnd(); $stderr = $proc.StandardError.ReadToEnd(); $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) { throw "Criação das bases/usuário falhou: $stderr $stdout" }
    ConvertTo-SecureString $rootPassword -AsPlainText -Force | ConvertFrom-SecureString | Set-Content -LiteralPath $rootPasswordFile -Encoding ASCII
    ConvertTo-SecureString $dbPassword -AsPlainText -Force | ConvertFrom-SecureString | Set-Content -LiteralPath $dbPasswordFile -Encoding ASCII
    $clientIni = "[client]`r`nuser=acore`r`npassword=$dbPassword`r`nhost=127.0.0.1`r`nport=3306`r`n"
    [IO.File]::WriteAllText((Join-Path $mysqlDir 'acore-client.ini'),$clientIni,[Text.UTF8Encoding]::new($false))
    $rootClientIni = "[client]`r`nuser=root`r`npassword=$rootPassword`r`nhost=127.0.0.1`r`nport=3306`r`n"
    [IO.File]::WriteAllText((Join-Path $mysqlDir 'root-client.ini'),$rootClientIni,[Text.UTF8Encoding]::new($false))
    $rootPassword=$null; $dbPassword=$null
}
if (-not (Test-Path (Join-Path $mysqlDir 'acore-client.ini'))) { throw 'Credencial local do usuário acore ausente; remova a instância WoWLocalMySQL e inicialize de novo.' }
Write-Host "MySQL ativo em 127.0.0.1:3306; bancos e usuário local acore preparados. Dados: $data" -ForegroundColor Green
