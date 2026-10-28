. "$PSScriptRoot\Common.ps1"
$profile = Get-Content -LiteralPath (Get-KitPath 'config/perfil-servidor.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$run = Get-KitPath 'servidor/run'
$worldPath = Join-Path $run 'configs/worldserver.conf'
$authPath = Join-Path $run 'configs/authserver.conf'
$botsPath = Join-Path $run 'configs/modules/playerbots.conf'
foreach ($p in @($worldPath,$authPath,$botsPath)) { if (-not (Test-Path $p)) { throw "Configuração ausente: $p" } }
$checks = @(
    @{file=$worldPath; pattern='(?m)^BindIP\s*=\s*"127\.0\.0\.1"\s*$'; label='worldserver vinculado apenas ao localhost'},
    @{file=$authPath; pattern='(?m)^BindIP\s*=\s*"127\.0\.0\.1"\s*$'; label='authserver vinculado apenas ao localhost'},
    @{file=$worldPath; pattern='(?m)^MaxPlayerLevel\s*=\s*80\s*$'; label='nível máximo 80'},
    @{file=$worldPath; pattern=('(?m)^Rate\.XP\.Kill\s*=\s*' + [regex]::Escape(([double]$profile.rates.playerXp).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='XP de jogador'},
    @{file=$worldPath; pattern=('(?m)^Rate\.XP\.Quest\.DF\s*=\s*' + [regex]::Escape(([double]$profile.rates.playerXp).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='XP de quests do Dungeon Finder'},
    @{file=$worldPath; pattern=('(?m)^Rate\.Drop\.Item\.Normal\s*=\s*' + [regex]::Escape(([double]$profile.rates.loot).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='drop de itens'},
    @{file=$worldPath; pattern=('(?m)^Rate\.Drop\.Money\s*=\s*' + [regex]::Escape(([double]$profile.rates.money).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='dinheiro de loot'},
    @{file=$worldPath; pattern=('(?m)^Rate\.RewardQuestMoney\s*=\s*' + [regex]::Escape(([double]$profile.rates.questMoney).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='dinheiro de quests'},
    @{file=$worldPath; pattern=('(?m)^Respawn\.DynamicMinimumCreature\s*=\s*' + $profile.gameplay.creatureRespawnMinimumSeconds + '\s*$'); label='respawn mínimo de criaturas'},
    @{file=$worldPath; pattern=('(?m)^Rate\.Creature\.Normal\.HP\s*=\s*' + [regex]::Escape(([double]$profile.gameplay.creatureHealthMultiplier).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='vida de criaturas'},
    @{file=$worldPath; pattern=('(?m)^Rate\.Creature\.Normal\.Damage\s*=\s*' + [regex]::Escape(([double]$profile.gameplay.creatureDamageMultiplier).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)) + '\s*$'); label='dano de criaturas'},
    @{file=$botsPath; pattern=('(?m)^Playerbots\.MinRandomBots\s*=\s*' + $profile.bots.minRandomBots + '\s*$'); label='mínimo de bots'},
    @{file=$botsPath; pattern=('(?m)^Playerbots\.MaxRandomBots\s*=\s*' + $profile.bots.maxRandomBots + '\s*$'); label='máximo de bots'},
    @{file=$botsPath; pattern=('(?m)^Playerbots\.RandomBotMinLevel\s*=\s*' + $profile.bots.minLevel + '\s*$'); label='nível mínimo dos bots'},
    @{file=$botsPath; pattern=('(?m)^Playerbots\.RandomBotMaxLevel\s*=\s*' + $profile.bots.maxLevel + '\s*$'); label='nível máximo dos bots'},
    @{file=$botsPath; pattern=('(?m)^Playerbots\.RandomBotXPRate\s*=\s*' + [regex]::Escape((([double]$profile.rates.botXpMultiplier / [double]$profile.rates.playerXp).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture))) + '\s*$'); label='XP efetiva de bot'}
)
$errors = @()
foreach ($c in $checks) {
    if ([regex]::IsMatch([IO.File]::ReadAllText($c.file),$c.pattern)) { Write-Host "OK: $($c.label)" -ForegroundColor Green }
    else { Write-Host "FALHA: $($c.label)" -ForegroundColor Red; $errors += $c.label }
}
if ($errors.Count) { throw "Perfil inválido em $($errors.Count) checagem(ns)." }
function Assert-Value([string]$Path,[string]$Key,[string]$Expected) {
    $pattern='(?m)^' + [regex]::Escape($Key) + '\s*=\s*' + [regex]::Escape($Expected) + '\s*$'
    if (-not [regex]::IsMatch([IO.File]::ReadAllText($Path),$pattern)) { throw "Configuração divergente: $Key (esperado $Expected)" }
    Write-Host "OK: $Key" -ForegroundColor Green
}
function Rate($Value) { return ([double]$Value).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture) }
Assert-Value $worldPath 'Rate.Reputation.Gain' (Rate $profile.rates.reputation)
Assert-Value $worldPath 'Rate.Honor' (Rate $profile.rates.honor)
Assert-Value $worldPath 'Rate.Creature.Aggro' (Rate $profile.gameplay.creatureAggroMultiplier)
Assert-Value $worldPath 'Respawn.DynamicRateCreature' (Rate $profile.gameplay.creatureRespawnDynamicRate)
Assert-Value $worldPath 'DurabilityLoss.OnDeath' ([string]$profile.gameplay.durabilityLossOnDeath)
Assert-Value $worldPath 'InstantFlightPaths' $(if($profile.gameplay.instantFlightPaths){'1'}else{'0'})
Assert-Value $botsPath 'Playerbots.MaxAddedBots' ([string]$profile.bots.maxAddedBots)
Assert-Value $botsPath 'Playerbots.RandomBotAllianceRatio' ([string]$profile.bots.allianceRatio)
Assert-Value $botsPath 'Playerbots.RandomBotHordeRatio' ([string]$profile.bots.hordeRatio)
Assert-Value $botsPath 'Playerbots.RandomBotRpgChance' (Rate $profile.bots.rpgChance)
foreach($entry in @(
    @('joinLfg','Playerbots.RandomBotJoinLfg'),@('talk','Playerbots.RandomBotTalk'),
    @('suggestDungeons','Playerbots.RandomBotSuggestDungeons'),@('inviteHumanPlayers','Playerbots.RandomBotInvitePlayer'),
    @('disabledWithoutRealPlayer','Playerbots.DisabledWithoutRealPlayer'),@('autoEquipUpgradeLoot','Playerbots.AutoEquipUpgradeLoot')
)) { Assert-Value $botsPath $entry[1] $(if($profile.bots.($entry[0])){'1'}else{'0'}) }
Write-Host 'Perfil estático validado.' -ForegroundColor Green
