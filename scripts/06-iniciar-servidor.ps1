. "$PSScriptRoot\Common.ps1"
$run = Get-KitPath 'servidor/run'
$launchId = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDirectory = Join-Path $run (Join-Path 'startup-logs' $launchId)
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$launcherLog = Join-Path $logDirectory 'launcher.log'
$consoleScript = Join-Path $PSScriptRoot '06-console-servidor.ps1'

function Write-LauncherLog([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message
    Add-Content -LiteralPath $launcherLog -Value $line -Encoding UTF8
}

Write-LauncherLog "Iniciando serviços. Logs desta tentativa: $logDirectory"
try {
    & (Join-Path $PSScriptRoot '10-configurar-mysql.ps1')
    Write-LauncherLog 'MySQL está pronto.'
} catch {
    Write-LauncherLog "Falha ao preparar MySQL: $($_.Exception.Message)"
    throw
}
foreach ($f in @('authserver.exe','worldserver.exe','configs/authserver.conf','configs/worldserver.conf')) {
    if (-not (Test-Path (Join-Path $run $f))) {
        Write-LauncherLog "Arquivo requerido ausente: $f"
        throw "Arquivo requerido ausente: $f"
    }
}
foreach ($f in @('Data/dbc','Data/maps','Data/vmaps','Data/mmaps')) {
    if (-not (Test-Path (Join-Path $run $f))) {
        Write-LauncherLog "Dados extraídos ausentes: $f"
        throw "Dados extraídos ausentes: $f. Execute scripts/03-extrair-dados.ps1."
    }
}
$alreadyRunning = @(Get-ServerProcesses)
if ($alreadyRunning.Count) {
    Write-LauncherLog "Inicialização recusada; já existem processos do kit: $(($alreadyRunning.Name -join ', '))."
    throw 'Já há authserver/worldserver deste kit em execução.'
}
$started = [Collections.Generic.List[object]]::new()
try {
    foreach ($server in @(
        @{ name = 'authserver'; executable = 'authserver.exe' },
        @{ name = 'worldserver'; executable = 'worldserver.exe' }
    )) {
        $name = $server.name
        $consoleLog = Join-Path $logDirectory "$name.console.log"
        Write-LauncherLog "Iniciando $($server.executable) em console visível; log=$consoleLog"
        Write-Host "Abrindo console do $name... Saída: $consoleLog" -ForegroundColor Yellow
        $arguments = @(
            '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', ('"{0}"' -f $consoleScript),
            '-ServerName', $name,
            '-LogPath', ('"{0}"' -f $consoleLog)
        )
        $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments `
            -WorkingDirectory $run -WindowStyle Normal -PassThru
        Start-Sleep -Seconds 3
        if ($proc.HasExited) {
            $exitCode = $proc.ExitCode
            Write-LauncherLog "$name encerrou durante a inicialização com código $exitCode."
            throw "O console de $name encerrou na inicialização (código $exitCode). Consulte $consoleLog."
        }
        $started.Add([pscustomobject]@{
            name = $name
            pid = $proc.Id
            startedAt = (Get-Date).ToString('o')
            consoleLog = $consoleLog
        })
        Write-LauncherLog "$name iniciado (PID $($proc.Id))."
        Write-Host "$name iniciado (PID $($proc.Id)). Log: $consoleLog" -ForegroundColor Green
    }
} catch {
    Write-LauncherLog "Falha ao iniciar os serviços: $($_.Exception.Message)"
    Write-Warning "Falha ao iniciar os serviços. Confira os logs em $logDirectory"
    foreach ($p in $started) {
        Stop-Process -Id $p.pid -ErrorAction SilentlyContinue
        Write-LauncherLog "Processo $($p.name) (PID $($p.pid)) encerrado após falha parcial."
    }
    throw
}
$pidFile = Join-Path $run 'server-processes.json'
@($started) | ConvertTo-Json | Set-Content -LiteralPath $pidFile -Encoding UTF8
Write-LauncherLog 'Os dois servidores permaneceram ativos na verificação inicial.'
Write-LauncherLog 'Arquivos de log nativos do AzerothCore também estão em servidor/run (Server.log, Auth.log e Errors.log).'
Write-Host "Log do inicializador: $launcherLog" -ForegroundColor Cyan
Write-Host 'Os consoles individuais mostram a saída em tempo real e ficam abertos em caso de erro.' -ForegroundColor Cyan
Write-Host 'Para desligar, use "server shutdown 1" no console do worldserver e feche o authserver depois.'
