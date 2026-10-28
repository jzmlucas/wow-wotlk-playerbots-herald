param([Parameter(Mandatory=$true)][string]$Stage)
. "$PSScriptRoot\Common.ps1"
$stagePath = (Resolve-Path -LiteralPath $Stage).Path
Assert-UnderKit $stagePath
foreach ($name in @('dbc','maps','cameras','vmaps','mmaps')) {
    $sourceRoot = Join-Path $stagePath $name
    if (-not (Test-Path $sourceRoot)) { throw "Diretório extraído ausente: $sourceRoot" }
}
$runData = Get-KitPath 'servidor/run/Data'
New-Item -ItemType Directory -Force -Path $runData | Out-Null
foreach ($name in @('dbc','maps','cameras','vmaps','mmaps')) {
    $sourceRoot = Join-Path $stagePath $name
    $targetRoot = Join-Path $runData $name
    New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null
    Get-ChildItem -LiteralPath $sourceRoot -File -Recurse | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($sourceRoot,$_.FullName)
        $target = Join-Path $targetRoot $relative
        if (-not (Test-Path -LiteralPath $target)) {
            $parent = Split-Path -Parent $target
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $target
        }
    }
}
Write-Host "Dados do cliente sincronizados em $runData. Reinicie o worldserver para carregar o conjunto completo de MMAPs." -ForegroundColor Green
