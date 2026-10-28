param([switch]$RefreshPins)
. "$PSScriptRoot\Common.ps1"
$manifest = Read-JsonFile (Get-KitPath 'config/fontes.json')
$lockPath = Get-KitPath 'servidor/fontes.lock.json'
$publishedLockPath = Get-KitPath 'config/fontes.lock.json'
$lock = if (Test-Path $lockPath) { Read-JsonFile $lockPath } elseif (Test-Path $publishedLockPath) { Read-JsonFile $publishedLockPath } else { $null }
if ($lock -and -not $RefreshPins) { Write-Host 'Lock existente: fontes serão restauradas nos SHAs fixados.' }
if ($RefreshPins -and -not $lock) { throw 'Não há lock anterior para atualizar. Execute sem -RefreshPins primeiro.' }

$heraldPatchPath = Get-KitPath 'patches/playerbots-herald.patch'
if (-not (Test-Path $heraldPatchPath)) { throw "Patch Herald ausente: $heraldPatchPath" }
$heraldPatchHash = (Get-FileHash -LiteralPath $heraldPatchPath -Algorithm SHA256).Hash.ToLowerInvariant()
$heraldMarkerName = '.wow-selfhost-herald-patch.sha256'
$heraldPatchFiles = @([regex]::Matches([IO.File]::ReadAllText($heraldPatchPath), '(?m)^diff --git a/(.+?) b/') | ForEach-Object { $_.Groups[1].Value })

$records = [Collections.Generic.List[object]]::new()
foreach ($repo in $manifest.repositories) {
    $path = Get-KitPath $repo.path
    Assert-UnderKit $path
    $old = if ($lock) { $lock.repositories | Where-Object name -eq $repo.name | Select-Object -First 1 } else { $null }
    if ($RefreshPins) {
        if (Test-Path (Join-Path $path '.git')) {
            if ($repo.name -eq 'mod-playerbots' -and (Test-Path (Join-Path $path $heraldMarkerName))) {
                $markerPath = Join-Path $path $heraldMarkerName
                $installedPatchHash = (Get-Content -LiteralPath $markerPath -Raw).Trim().ToLowerInvariant()
                if ($installedPatchHash -ne $heraldPatchHash) { throw 'O patch Herald instalado difere do patch publicado; atualize manualmente após revisar as alterações locais.' }
                $allowedDirty = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
                foreach ($file in $heraldPatchFiles) { [void]$allowedDirty.Add($file) }
                [void]$allowedDirty.Add($heraldMarkerName)
                $dirtyBeforeRefresh = @(& git -C $path status --porcelain --untracked-files=all)
                $unexpectedDirty = @($dirtyBeforeRefresh | Where-Object { $_.Length -ge 4 -and -not $allowedDirty.Contains($_.Substring(3).Trim()) })
                if ($unexpectedDirty) { throw "Checkout mod-playerbots tem alterações além do patch Herald. Faça backup ou commit antes de atualizar: $($unexpectedDirty -join '; ')" }
                Invoke-External git @('-C', $path, 'apply', '--reverse', '--check', $heraldPatchPath)
                Invoke-External git @('-C', $path, 'apply', '--reverse', $heraldPatchPath)
                Remove-Item -LiteralPath $markerPath -Force
            }
            $dirty = & git -C $path status --porcelain
            if ($dirty) { throw "Checkout $($repo.name) tem alterações locais. Faça backup ou commit antes de atualizar." }
        }
        $branch = $repo.branch
        if ($branch -eq 'HEAD') {
            $sym = & git ls-remote --symref $repo.url HEAD | Select-Object -First 1
            if ($sym -notmatch '^ref:\s+refs/heads/([^\s]+)\s+HEAD$') { throw "Não foi possível resolver a branch padrão: $($repo.url)" }
            $branch = $Matches[1]
        }
        $sha = (& git ls-remote $repo.url "refs/heads/$branch" | ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -First 1)
        if (-not $sha) { throw "Branch não encontrada para $($repo.name): $branch" }
    } elseif ($old) {
        $branch = $old.branch; $sha = $old.commit
    } else {
        $branch = $repo.branch
        if ($branch -eq 'HEAD') {
            $sym = & git ls-remote --symref $repo.url HEAD | Select-Object -First 1
            if ($sym -notmatch '^ref:\s+refs/heads/([^\s]+)\s+HEAD$') { throw "Não foi possível resolver a branch padrão: $($repo.url)" }
            $branch = $Matches[1]
        }
        $sha = (& git ls-remote $repo.url "refs/heads/$branch" | ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -First 1)
        if (-not $sha) { throw "Branch não encontrada para $($repo.name): $branch" }
    }
    if (Test-Path (Join-Path $path '.git')) {
        if ($RefreshPins) { Invoke-External git @('-C', $path, 'fetch', 'origin', $sha) }
        Invoke-External git @('-C', $path, 'checkout', '--detach', $sha)
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
        Invoke-External git @('clone', '--no-checkout', $repo.url, $path)
        Invoke-External git @('-C', $path, 'fetch', 'origin', $sha)
        Invoke-External git @('-C', $path, 'checkout', '--detach', $sha)
    }
    $actual = (& git -C $path rev-parse HEAD).Trim()
    if ($actual -ne $sha) { throw "SHA obtido não corresponde ao pin para $($repo.name)." }
    $records.Add([pscustomobject]@{ name=$repo.name; role=$repo.role; url=$repo.url; branch=$branch; commit=$sha; path=$repo.path })
}
$playerbotsPath = Get-KitPath 'servidor/src/azerothcore-wotlk/modules/mod-playerbots'
$teleporterSource = Get-KitPath 'modules/mod-wow-teleporter'
$teleporterTarget = Get-KitPath 'servidor/src/azerothcore-wotlk/modules/mod-wow-teleporter'
if (-not (Test-Path (Join-Path $teleporterSource 'CMakeLists.txt'))) { throw "Módulo de teletransporte ausente: $teleporterSource" }
New-Item -ItemType Directory -Force -Path $teleporterTarget | Out-Null
Copy-Item -Path (Join-Path $teleporterSource '*') -Destination $teleporterTarget -Recurse -Force
$heraldMarkerPath = Join-Path $playerbotsPath $heraldMarkerName
if (Test-Path $heraldMarkerPath) {
    $installedPatchHash = (Get-Content -LiteralPath $heraldMarkerPath -Raw).Trim().ToLowerInvariant()
    if ($installedPatchHash -ne $heraldPatchHash) { throw 'O patch Herald instalado não corresponde ao arquivo versionado.' }
} else {
    $moduleDirty = & git -C $playerbotsPath status --porcelain --untracked-files=all
    if ($moduleDirty) { throw 'O checkout mod-playerbots contém alterações locais; não aplicarei o patch Herald sobre alterações desconhecidas.' }
    Invoke-External git @('-C', $playerbotsPath, 'apply', '--check', $heraldPatchPath)
    Invoke-External git @('-C', $playerbotsPath, 'apply', $heraldPatchPath)
    [IO.File]::WriteAllText($heraldMarkerPath, "$heraldPatchHash`r`n", [Text.UTF8Encoding]::new($false))
}
New-Item -ItemType Directory -Force -Path (Split-Path $lockPath) | Out-Null
[pscustomobject]@{ schemaVersion=1; resolvedAt=(Get-Date).ToString('o'); repositories=@($records) } |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $lockPath -Encoding UTF8
Write-Host "Fontes prontas e fixadas em $lockPath" -ForegroundColor Green
