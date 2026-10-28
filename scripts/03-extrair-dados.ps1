param([string]$ClientPath)
. "$PSScriptRoot\Common.ps1"
if (-not $ClientPath) { $ClientPath = Read-Host 'Pasta do cliente WoW 3.3.5a já instalado (com Wow.exe)' }
$client = (Resolve-Path -LiteralPath $ClientPath).Path
if (-not (Test-Path (Join-Path $client 'Wow.exe')) -or -not (Test-Path (Join-Path $client 'Data'))) {
    throw 'A pasta precisa conter Wow.exe e Data. O script não altera nem redistribui o cliente.'
}
$run = Get-KitPath 'servidor/run'
foreach ($tool in @('map_extractor.exe','vmap4_extractor.exe','vmap4_assembler.exe','mmaps_generator.exe')) {
    if (-not (Test-Path (Join-Path $run $tool))) { throw "Extractor $tool ausente. Compile com scripts/02-compilar-servidor.ps1." }
}
$stage = Get-KitPath ("servidor/extracao/{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item (Join-Path $client 'Data') $stage -Recurse
$mmapConfig = Get-KitPath 'servidor/src/azerothcore-wotlk/src/tools/mmaps_generator/mmaps-config.yaml'
if (-not (Test-Path $mmapConfig)) { throw 'mmaps-config.yaml ausente no código-fonte.' }
Copy-Item (Join-Path $run 'map_extractor.exe'),(Join-Path $run 'vmap4_extractor.exe'),(Join-Path $run 'vmap4_assembler.exe'),(Join-Path $run 'mmaps_generator.exe'),$mmapConfig $stage
function Run-Extractor([string]$Name,[string[]]$Args=@()) {
    $p = Start-Process -FilePath (Join-Path $stage $Name) -ArgumentList $Args -WorkingDirectory $stage -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "$Name terminou com código $($p.ExitCode). Dados de estágio foram preservados em $stage" }
}
Write-Host 'Extraindo maps/DBC; o processo pode levar alguns minutos.'
Run-Extractor 'map_extractor.exe'
Write-Host 'Extraindo VMAPs.'
Run-Extractor 'vmap4_extractor.exe'
if (-not (Test-Path (Join-Path $stage 'Buildings'))) { throw "Buildings ausente em $stage; consulte a saída e não apague o estágio." }
Write-Host 'Montando VMAPs.'
Run-Extractor 'vmap4_assembler.exe' @('Buildings','vmaps')
Write-Host 'Gerando MMAPs. Esta etapa pode demorar bastante.'
Run-Extractor 'mmaps_generator.exe' @('--silent','--threads','8')
$data = Join-Path $run 'Data'
New-Item -ItemType Directory -Force -Path $data | Out-Null
foreach ($name in @('dbc','maps','cameras','vmaps','mmaps')) {
    $source = Join-Path $stage $name
    if (-not (Test-Path $source)) { throw "Saída obrigatória ausente ($name). Estágio preservado: $stage" }
    if (Test-Path (Join-Path $data $name)) { Remove-Item (Join-Path $data $name) -Recurse -Force }
    Copy-Item $source $data -Recurse
}
Write-Host "Extração concluída em $data. Cliente original preservado; estágio em $stage" -ForegroundColor Green
