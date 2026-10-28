. "$PSScriptRoot\Common.ps1"
$running = Get-ServerProcesses
if (-not $running.Count) { Write-Host 'Authserver e worldserver já estão encerrados.' }
Write-Host 'Encerre primeiro o worldserver pelo próprio console com: server shutdown 1'
Write-Host 'Quando ele parar, feche o console do authserver normalmente.'
Write-Host 'Este verificador não força o término dos processos.'
Start-Sleep -Seconds 2
$left = Get-ServerProcesses
if ($left.Count) { $left | Select-Object ProcessId,Name,ExecutablePath | Format-Table -AutoSize; exit 1 }
Write-Host 'Authserver e worldserver encerrados.' -ForegroundColor Green
$mysqlAdmin = 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqladmin.exe'
$mysqlConfig = Get-KitPath 'servidor/mysql/root-client.ini'
if ((Test-Path $mysqlAdmin) -and (Test-Path $mysqlConfig)) {
    & $mysqlAdmin "--defaults-extra-file=$mysqlConfig" --protocol=TCP --host=127.0.0.1 shutdown
    if ($LASTEXITCODE -ne 0) { throw 'MySQL não encerrou pelo comando seguro; confira se a instância local está ativa.' }
    Write-Host 'MySQL local encerrou com shutdown seguro.' -ForegroundColor Green
}
