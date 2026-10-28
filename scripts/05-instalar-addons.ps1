param([string]$ClientPath,[string[]]$Only)
. "$PSScriptRoot\Common.ps1"
$lock = Read-JsonFile (Get-KitPath 'servidor/fontes.lock.json')
if (-not $ClientPath) { $ClientPath = Read-Host 'Pasta do cliente WoW 3.3.5a' }
$client = (Resolve-Path -LiteralPath $ClientPath).Path
$addonRoot = Join-Path $client 'Interface/AddOns'
New-Item -ItemType Directory -Force -Path $addonRoot | Out-Null
$backupRoot = Get-KitPath ("servidor/addon-backups/{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$mapping = @(
    @{repo='MultiBot-Chatless'; folder='MultiBot'},
    @{repo='mod-dungeon-clear-addon'; folder='DungeonClear'},
    @{repo='AltBot'; folder='AltBot'},
    @{folder='HeraldWotLK'; localPath='addons/HeraldWotLK'},
    @{folder='SoloRealmAddons'; localPath='addons/SoloRealmAddons'; legacyFolders=@('HeraldShop','HeraldTeleport','SoloShop','SoloTeleport','SoloRealm')}
)
if ($Only) {
    $Only = @($Only | ForEach-Object {
        if ($_ -in @('SoloShop','SoloTeleport','SoloRealm')) { 'SoloRealmAddons' } else { $_ }
    } | Select-Object -Unique)
    $unknown = @($Only | Where-Object { $_ -notin $mapping.folder })
    if ($unknown) { throw "Addon(s) desconhecido(s): $($unknown -join ', '). Use: $($mapping.folder -join ', ')." }
    $mapping = @($mapping | Where-Object { $_.folder -in $Only })
}
foreach ($item in $mapping) {
    if ($item.ContainsKey('localPath') -and $item.localPath) {
        $addonSource = Get-Item (Get-KitPath $item.localPath)
    } else {
        $source = $lock.repositories | Where-Object name -eq $item.repo | Select-Object -First 1
        if (-not $source) { throw "Fonte $($item.repo) não está no lock. Execute o download primeiro." }
        $src = Get-KitPath $source.path
        $addonSource = Get-ChildItem $src -Directory | Where-Object Name -Match '^(MultiBot|DungeonClear)$' | Select-Object -First 1
        if (-not $addonSource) { $addonSource = Get-Item $src }
    }
    $target = Join-Path $addonRoot $item.folder
    $legacyFolders = @()
    if ($item.ContainsKey('legacyFolders')) { $legacyFolders = @($item['legacyFolders']) }
    foreach ($legacyFolder in $legacyFolders) {
        if (-not $legacyFolder) { continue }
        $legacyTarget = Join-Path $addonRoot $legacyFolder
        if (Test-Path $legacyTarget) {
            New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
            Move-Item -LiteralPath $legacyTarget -Destination (Join-Path $backupRoot $legacyFolder)
        }
    }
    if (Test-Path $target) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        Move-Item $target (Join-Path $backupRoot $item.folder)
    }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    if ($item.folder -eq 'AltBot') {
        Get-ChildItem $addonSource.FullName -File -Force | Where-Object Extension -In @('.lua','.toc','.xml','.png') | Copy-Item -Destination $target -Force
        $toc = Join-Path $target 'AltBot.toc'
        $tocText = [IO.File]::ReadAllText($toc)
        if ($tocText -notmatch '(?m)^Bindings\.xml\s*$') {
            [IO.File]::AppendAllText($toc, "`r`nBindings.xml`r`n", [Text.UTF8Encoding]::new($false))
        }
    } else {
        Get-ChildItem $addonSource.FullName -Force | Where-Object Name -NotIn @('.git','.github') | Copy-Item -Destination $target -Recurse -Force
    }
    if (-not (Get-ChildItem $target -File -Filter '*.toc')) { throw "Addon $($item.folder) não contém arquivo TOC; confira o conteúdo upstream." }
}
Write-Host "Addons instalados em ${addonRoot}: $($mapping.folder -join ', '). Reinicie o cliente para carregar." -ForegroundColor Green
