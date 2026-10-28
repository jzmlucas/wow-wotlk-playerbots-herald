param([ValidateRange(0,64)][int]$ParallelJobs = 0)
. "$PSScriptRoot\Common.ps1"
$root = Get-KitPath 'servidor/src/azerothcore-wotlk'
if (-not (Test-Path (Join-Path $root 'CMakeLists.txt'))) { throw 'Fontes ausentes. Execute scripts/01-baixar-fontes.ps1.' }
$teleporterSource = Get-KitPath 'modules/mod-wow-teleporter'
$teleporterTarget = Join-Path $root 'modules/mod-wow-teleporter'
if (-not (Test-Path (Join-Path $teleporterSource 'CMakeLists.txt'))) { throw "Módulo de teletransporte ausente: $teleporterSource" }
New-Item -ItemType Directory -Force -Path $teleporterTarget | Out-Null
Copy-Item -Path (Join-Path $teleporterSource '*') -Destination $teleporterTarget -Recurse -Force
$logicalProcessors = [Environment]::ProcessorCount
$compilerJobs = 1
if ($ParallelJobs -eq 0) {
    $totalMemoryBytes = 0L
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $totalMemoryBytes = [long]$computerSystem.TotalPhysicalMemory
    } catch {
        try { $totalMemoryBytes = [long][GC]::GetGCMemoryInfo().TotalAvailableMemoryBytes }
        catch {
            try { $totalMemoryBytes = [long](Get-ComputerInfo -Property CsTotalPhysicalMemory -ErrorAction Stop).CsTotalPhysicalMemory }
            catch { $totalMemoryBytes = 0L }
        }
    }

    if ($totalMemoryBytes -gt 0) {
        $memoryGb = $totalMemoryBytes / 1GB
        $reservedMemoryGb = 8
        $memoryPerWorkerGb = 3
        $maxWorkerBudget = 6
        $workerBudget = [int][Math]::Max(1, [Math]::Min($maxWorkerBudget, [Math]::Min($logicalProcessors, [Math]::Floor(($memoryGb - $reservedMemoryGb) / $memoryPerWorkerGb))))
        $compilerJobs = [int][Math]::Min(2, [Math]::Max(1, [Math]::Floor([Math]::Sqrt($workerBudget))))
        $ParallelJobs = [int][Math]::Max(1, [Math]::Floor($workerBudget / $compilerJobs))
        Write-Host ("Build paralelo automático: {0} projetos x {1} compilações por projeto; orçamento de {2} trabalhos com {3} processadores lógicos e {4:N1} GB RAM." -f $ParallelJobs, $compilerJobs, $workerBudget, $logicalProcessors, $memoryGb) -ForegroundColor Cyan
    } else {
        $ParallelJobs = [Math]::Min(2, $logicalProcessors)
        Write-Warning "Não consegui detectar a RAM; usando $ParallelJobs trabalhos paralelos por segurança. Você pode informar -ParallelJobs manualmente."
    }
} elseif ($ParallelJobs -gt $logicalProcessors) {
    Write-Warning "ParallelJobs ($ParallelJobs) excede os $logicalProcessors processadores lógicos detectados e pode reduzir o desempenho."
}
$build = Join-Path $root 'build'
# Inclui os módulos do servidor, especialmente Playerbots, na compilação estática.
$cmakeArgs = @('-S', $root, '-B', $build, '-G', 'Visual Studio 17 2022', '-A', 'x64', '-DTOOLS_BUILD=all', '-DMODULES=static', '-DNOPCH=0')
if ($env:BOOST_ROOT) { $cmakeArgs += "-DBOOST_ROOT=$env:BOOST_ROOT" }
if ($env:OPENSSL_ROOT_DIR) { $cmakeArgs += "-DOPENSSL_ROOT_DIR=$env:OPENSSL_ROOT_DIR" }
Invoke-External cmake $cmakeArgs
$modulesProject = Join-Path $build 'modules/modules.vcxproj'
if (-not (Test-Path -LiteralPath $modulesProject)) { throw "Projeto dos módulos não foi gerado: $modulesProject" }
$projectText = [IO.File]::ReadAllText($modulesProject)
if ($projectText -notmatch '<DebugInformationFormat>') { throw 'Não foi possível localizar a configuração de símbolos dos módulos.' }
$projectText = [regex]::Replace($projectText, '<DebugInformationFormat>ProgramDatabase</DebugInformationFormat>', '<DebugInformationFormat>None</DebugInformationFormat>')
[IO.File]::WriteAllText($modulesProject, $projectText, [Text.UTF8Encoding]::new($false))
$oldClMpCount = $env:CL_MPCount
$env:CL_MPCount = "$compilerJobs"
try {
    Invoke-External cmake @('--build', $build, '--config', 'RelWithDebInfo', '--parallel', "$ParallelJobs")
} finally {
    if ($null -eq $oldClMpCount) { Remove-Item Env:CL_MPCount -ErrorAction SilentlyContinue }
    else { $env:CL_MPCount = $oldClMpCount }
}
$bin = Join-Path $build 'bin/RelWithDebInfo'
if (-not (Test-Path $bin)) { throw "Saída de build não encontrada: $bin" }
$run = Get-KitPath 'servidor/run'
if (Get-ServerProcesses) { throw 'Encerre authserver/worldserver antes de copiar executáveis para servidor/run.' }
New-Item -ItemType Directory -Force -Path $run | Out-Null
Copy-Item (Join-Path $bin '*') $run -Recurse -Force
$mysqlRoot = 'C:\Program Files\MySQL\MySQL Server 8.4'
$opensslRoot = $env:OPENSSL_ROOT_DIR
foreach ($pair in @(
    @{source=(Join-Path $mysqlRoot 'lib/libmysql.dll');target='libmysql.dll'},
    @{source=(Join-Path $opensslRoot 'bin/legacy.dll');target='legacy.dll'},
    @{source=(Join-Path $opensslRoot 'bin/libcrypto-3-x64.dll');target='libcrypto-3-x64.dll'},
    @{source=(Join-Path $opensslRoot 'bin/libssl-3-x64.dll');target='libssl-3-x64.dll'}
)) {
    if (-not (Test-Path $pair.source)) { throw "DLL necessária não encontrada: $($pair.source)" }
    Copy-Item $pair.source (Join-Path $run $pair.target) -Force
}
Write-Host "Build copiado para $run" -ForegroundColor Green
