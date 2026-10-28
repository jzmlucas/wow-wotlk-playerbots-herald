param([Parameter(Mandatory=$true)][string]$JobFile)

$ErrorActionPreference = 'Stop'
try {
    $job = Get-Content -LiteralPath $JobFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Set-Location -LiteralPath $job.WorkingDirectory
    $scriptPath = (Resolve-Path -LiteralPath $job.Script).Path
    $arguments = @($job.Arguments | ForEach-Object { [string]$_ })
    $namedArguments = @{}
    for ($index = 0; $index -lt $arguments.Count; $index++) {
        $argument = $arguments[$index]
        if ($argument -notmatch '^-([A-Za-z][A-Za-z0-9-]*)$') {
            throw "Argumento de tarefa deve ser nomeado no formato -Nome: $argument"
        }

        $name = $Matches[1]
        if ($index + 1 -lt $arguments.Count -and $arguments[$index + 1] -notmatch '^-([A-Za-z][A-Za-z0-9-]*)$') {
            $index++
            $namedArguments[$name] = $arguments[$index]
        } else {
            $namedArguments[$name] = $true
        }
    }

    if ($namedArguments.ContainsKey('ClientPath') -and [string]::IsNullOrWhiteSpace([string]$namedArguments['ClientPath'])) {
        throw 'Selecione a pasta do cliente WotLK antes de executar esta tarefa.'
    }

    & $scriptPath @namedArguments
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    exit 0
} catch {
    Write-Error $_
    exit 1
} finally {
    Remove-Item -LiteralPath $JobFile -Force -ErrorAction SilentlyContinue
}
