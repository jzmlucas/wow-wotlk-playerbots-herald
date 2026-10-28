param(
    [Parameter(Mandatory)][ValidateSet('authserver','worldserver')][string]$ServerName,
    [Parameter(Mandatory)][string]$LogPath
)

$ErrorActionPreference = 'Continue'
$run = (Resolve-Path (Join-Path $PSScriptRoot '..\servidor\run')).Path
$serverExecutable = Join-Path $run ($ServerName + '.exe')

function Write-ServerConsoleLog([string]$Message) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

Write-ServerConsoleLog "Iniciando $ServerName (PID do console: $PID)."
try {
    & $serverExecutable 2>&1 | Tee-Object -FilePath $LogPath -Append
    $serverExitCode = $LASTEXITCODE
    if ($null -eq $serverExitCode) { $serverExitCode = 0 }
} catch {
    Write-ServerConsoleLog "Erro ao executar $serverExecutable : $($_.Exception.Message)"
    $serverExitCode = 1
}

Write-ServerConsoleLog "SERVER_EXIT_CODE=$serverExitCode"
if ($serverExitCode -ne 0) {
    Write-Host "`n$ServerName encerrou com erro. O log está em: $LogPath" -ForegroundColor Red
    [void](Read-Host 'Pressione Enter para fechar esta janela')
}

exit $serverExitCode
