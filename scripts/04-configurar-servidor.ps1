. "$PSScriptRoot\Common.ps1"
$profile = Get-Content -LiteralPath (Get-KitPath 'config/perfil-servidor.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($profile.rates.playerXp -lt 0.1 -or $profile.rates.playerXp -gt 100 -or $profile.rates.loot -lt 0.1 -or $profile.rates.loot -gt 100 -or $profile.rates.money -lt 0.1 -or $profile.rates.money -gt 100 -or $profile.rates.questMoney -lt 0.1 -or $profile.rates.questMoney -gt 100) { throw 'Taxas do perfil fora do intervalo de 0,1 a 100.' }
if ($profile.rates.botXpMultiplier -lt 0.1 -or $profile.rates.botXpMultiplier -gt 100) { throw 'XP efetiva dos bots deve ficar entre 0,1 e 100.' }
if ($profile.bots.minRandomBots -lt 0 -or $profile.bots.maxRandomBots -gt 5000 -or $profile.bots.minRandomBots -gt $profile.bots.maxRandomBots) { throw 'Quantidade de bots inválida (0 a 5000; mínimo <= máximo).' }
if ($profile.gameplay.creatureRespawnMinimumSeconds -lt 1 -or $profile.gameplay.creatureRespawnMinimumSeconds -gt 3600 -or $profile.gameplay.creatureHealthMultiplier -lt 0.1 -or $profile.gameplay.creatureHealthMultiplier -gt 100 -or $profile.gameplay.creatureDamageMultiplier -lt 0.1 -or $profile.gameplay.creatureDamageMultiplier -gt 100) { throw 'Ajustes de criaturas fora do intervalo permitido.' }
if ($profile.rates.reputation -lt 0.1 -or $profile.rates.reputation -gt 100 -or $profile.rates.honor -lt 0.1 -or $profile.rates.honor -gt 100 -or $profile.gameplay.creatureAggroMultiplier -lt 0.1 -or $profile.gameplay.creatureAggroMultiplier -gt 10 -or $profile.gameplay.creatureRespawnDynamicRate -lt 0.1 -or $profile.gameplay.creatureRespawnDynamicRate -gt 10 -or $profile.gameplay.durabilityLossOnDeath -lt 0 -or $profile.gameplay.durabilityLossOnDeath -gt 100) { throw 'Taxas adicionais fora do intervalo permitido.' }
if ($profile.bots.minLevel -lt 1 -or $profile.bots.maxLevel -gt 80 -or $profile.bots.minLevel -gt $profile.bots.maxLevel -or $profile.bots.maxAddedBots -lt 0 -or $profile.bots.maxAddedBots -gt 200 -or $profile.bots.allianceRatio -lt 0 -or $profile.bots.allianceRatio -gt 100 -or $profile.bots.hordeRatio -ne (100 - $profile.bots.allianceRatio) -or $profile.bots.rpgChance -lt 0 -or $profile.bots.rpgChance -gt 1) { throw 'Parâmetros adicionais dos bots inválidos.' }
$numberCulture = [Globalization.CultureInfo]::InvariantCulture
function Format-Rate($Value) { return ([double]$Value).ToString('0.######',$numberCulture) }
$run = Get-KitPath 'servidor/run'
$configs = Join-Path $run 'configs'
if (-not (Test-Path $configs)) { throw 'Configurações do build ausentes. Compile primeiro.' }
$backup = Get-KitPath ("servidor/config-backups/{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item $configs $backup -Recurse -Force

function Set-Conf([string]$Path,[hashtable]$Values) {
    if (-not (Test-Path $Path)) { throw "Arquivo de configuração não encontrado: $Path" }
    $content = [IO.File]::ReadAllText($Path)
    foreach ($key in $Values.Keys) {
        $escaped = [regex]::Escape($key)
        $pattern = "(?m)^\s*#?\s*$escaped\s*=.*$"
        $line = "$key = $($Values[$key])"
        if ([regex]::IsMatch($content,$pattern)) { $content = [regex]::Replace($content,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $line },1) }
        else { $content = $content.TrimEnd() + "`r`n$line`r`n" }
    }
    [IO.File]::WriteAllText($Path,$content,[Text.UTF8Encoding]::new($false))
}

$world = Join-Path $configs 'worldserver.conf'
$auth = Join-Path $configs 'authserver.conf'
foreach ($item in @(@{name='worldserver.conf.dist';target='worldserver.conf'},@{name='authserver.conf.dist';target='authserver.conf'})) {
    if (-not (Test-Path (Join-Path $configs $item.target))) {
        $dist = Join-Path $configs $item.name
        if (-not (Test-Path $dist)) { throw "Template ausente: $dist" }
        Copy-Item $dist (Join-Path $configs $item.target)
    }
}
$worldValues = @{
    'DataDir'='"Data"'; 'BindIP'='"127.0.0.1"'; 'MaxPlayerLevel'='80'; 'GameType'='0'; 'MapUpdate.Threads'='6';
    'Rate.XP.Kill'='5'; 'Rate.XP.Quest'='5'; 'Rate.XP.Quest.DF'='5'; 'Rate.XP.Explore'='5'; 'Rate.XP.Pet'='5';
    'Rate.Drop.Item.Poor'='3'; 'Rate.Drop.Item.Normal'='3'; 'Rate.Drop.Item.Uncommon'='3'; 'Rate.Drop.Item.Rare'='3'; 'Rate.Drop.Item.Epic'='3';
    'Rate.Drop.Item.Legendary'='3'; 'Rate.Drop.Item.Artifact'='3'; 'Rate.Drop.Item.Heirloom'='3'; 'Rate.Drop.Item.Referenced'='3'; 'Rate.Drop.Item.ReferencedAmount'='3'; 'Rate.Drop.Money'='3'; 'Rate.RewardQuestMoney'='4'
}
Set-Conf $world $worldValues
$xp = Format-Rate $profile.rates.playerXp
$loot = Format-Rate $profile.rates.loot
$money = Format-Rate $profile.rates.money
$questMoney = Format-Rate $profile.rates.questMoney
$worldOverrides = @{}
foreach ($key in @('Rate.XP.Kill','Rate.XP.Quest','Rate.XP.Quest.DF','Rate.XP.Explore','Rate.XP.Pet')) { $worldOverrides[$key]=$xp }
foreach ($key in @('Rate.Drop.Item.Poor','Rate.Drop.Item.Normal','Rate.Drop.Item.Uncommon','Rate.Drop.Item.Rare','Rate.Drop.Item.Epic','Rate.Drop.Item.Legendary','Rate.Drop.Item.Artifact','Rate.Drop.Item.Heirloom','Rate.Drop.Item.Referenced','Rate.Drop.Item.ReferencedAmount')) { $worldOverrides[$key]=$loot }
$worldOverrides['Rate.Drop.Money']=$money
$worldOverrides['Rate.RewardQuestMoney']=$questMoney
$worldOverrides['Rate.Reputation.Gain']=Format-Rate $profile.rates.reputation
$worldOverrides['Rate.Honor']=Format-Rate $profile.rates.honor
$worldOverrides['Respawn.DynamicMinimumCreature']=[string]$profile.gameplay.creatureRespawnMinimumSeconds
$worldOverrides['Respawn.DynamicRateCreature']=Format-Rate $profile.gameplay.creatureRespawnDynamicRate
$worldOverrides['Rate.Creature.Normal.HP']=Format-Rate $profile.gameplay.creatureHealthMultiplier
$worldOverrides['Rate.Creature.Normal.Damage']=Format-Rate $profile.gameplay.creatureDamageMultiplier
$worldOverrides['Rate.Creature.Aggro']=Format-Rate $profile.gameplay.creatureAggroMultiplier
$worldOverrides['DurabilityLoss.OnDeath']=[string]$profile.gameplay.durabilityLossOnDeath
$worldOverrides['InstantFlightPaths']=if ($profile.gameplay.instantFlightPaths) {'1'} else {'0'}
Set-Conf $world $worldOverrides
$mysqlClient = Get-KitPath 'servidor/mysql/acore-client.ini'
if (-not (Test-Path $mysqlClient)) { throw 'Execute scripts/10-configurar-mysql.ps1 antes de configurar os arquivos do servidor.' }
$passwordLine = Get-Content -LiteralPath $mysqlClient | Where-Object { $_ -match '^password=' } | Select-Object -First 1
if (-not $passwordLine) { throw 'Senha local do banco não encontrada no arquivo privado do MySQL.' }
$dbPassword = $passwordLine.Substring('password='.Length)
$dbInfo = @{
    auth='"127.0.0.1;3306;acore;' + $dbPassword + ';acore_auth"'
    characters='"127.0.0.1;3306;acore;' + $dbPassword + ';acore_characters"'
    world='"127.0.0.1;3306;acore;' + $dbPassword + ';acore_world"'
    playerbots='"127.0.0.1;3306;acore;' + $dbPassword + ';acore_playerbots"'
}
Set-Conf $auth @{ 'BindIP'='"127.0.0.1"'; 'LoginDatabaseInfo'=$dbInfo.auth }
Set-Conf $world @{ 'LoginDatabaseInfo'=$dbInfo.auth; 'WorldDatabaseInfo'=$dbInfo.world; 'CharacterDatabaseInfo'=$dbInfo.characters }
$dbimport = Join-Path $configs 'dbimport.conf'
if (-not (Test-Path $dbimport)) {
    $dbimportDist = Get-KitPath 'servidor/src/azerothcore-wotlk/src/tools/dbimport/dbimport.conf.dist'
    if (-not (Test-Path $dbimportDist)) { throw 'Template dbimport.conf.dist ausente.' }
    Copy-Item $dbimportDist "$dbimport.dist"
    Copy-Item $dbimportDist $dbimport
}
Set-Conf $dbimport @{
    'LoginDatabaseInfo'=$dbInfo.auth; 'WorldDatabaseInfo'=$dbInfo.world; 'CharacterDatabaseInfo'=$dbInfo.characters;
    'Updates.AllowedModules'='"all"'; 'Updates.AutoSetup'='1'
}
$moduleConfigs = Join-Path $configs 'modules'
New-Item -ItemType Directory -Force -Path $moduleConfigs | Out-Null
$moduleDirs = @(
    (Get-KitPath 'servidor/src/azerothcore-wotlk/modules/mod-playerbots'),
    (Get-KitPath 'servidor/src/azerothcore-wotlk/modules/mod-dungeon-clear'),
    (Get-KitPath 'servidor/src/azerothcore-wotlk/modules/mod-multibot-bridge'),
    (Get-KitPath 'servidor/src/azerothcore-wotlk/modules/mod-wow-teleporter')
)
foreach ($dir in $moduleDirs) {
    if (-not (Test-Path $dir)) { throw "Módulo ausente: $dir" }
    Get-ChildItem $dir -Recurse -File -Filter '*.conf.dist' | ForEach-Object {
        $target = Join-Path $moduleConfigs ([IO.Path]::GetFileName($_.Name))
        if (-not (Test-Path $target)) { Copy-Item $_.FullName $target }
        $actual = $target -replace '\.dist$',''
        if (-not (Test-Path $actual)) { Copy-Item $target $actual }
    }
}
$botConf = Get-ChildItem $moduleConfigs -File | Where-Object Name -Match 'playerbots\.conf$' | Select-Object -First 1
if (-not $botConf) { throw 'playerbots.conf do módulo não encontrado em configs/modules.' }
Set-Conf $botConf.FullName @{
    'Playerbots.Enabled'='1'; 'Playerbots.RandomBotAutologin'='1'; 'Playerbots.MinRandomBots'='1000'; 'Playerbots.MaxRandomBots'='1000';
    'Playerbots.RandomBotMinLevel'='1'; 'Playerbots.RandomBotMaxLevel'='80'; 'Playerbots.RandomBotAllianceRatio'='67'; 'Playerbots.RandomBotHordeRatio'='33';
    'Playerbots.RandomBotXPRate'='0.333333'; 'Playerbots.RandomBotRpgChance'='0.5'; 'Playerbots.RandomBotJoinLfg'='1'; 'Playerbots.RandomBotTalk'='1';
    'Playerbots.RandomBotSuggestDungeons'='1'; 'Playerbots.RandomBotInvitePlayer'='0'; 'Playerbots.InviteChat'='1'; 'Playerbots.GroupInvitationPermission'='2';
    'Playerbots.SelfBotLevel'='2'; 'Playerbots.EnableNewRpgStrategy'='1'; 'Playerbots.CommandServerPort'='0';
    'PlayerbotsDatabaseInfo'=$dbInfo.playerbots
}
$botRate = Format-Rate ([double]$profile.rates.botXpMultiplier / [double]$profile.rates.playerXp)
Set-Conf $botConf.FullName @{
    'Playerbots.MinRandomBots'=[string]$profile.bots.minRandomBots
    'Playerbots.MaxRandomBots'=[string]$profile.bots.maxRandomBots
    'Playerbots.RandomBotXPRate'=$botRate
    'Playerbots.RandomBotMinLevel'=[string]$profile.bots.minLevel
    'Playerbots.RandomBotMaxLevel'=[string]$profile.bots.maxLevel
    'Playerbots.MaxAddedBots'=[string]$profile.bots.maxAddedBots
    'Playerbots.RandomBotAllianceRatio'=[string]$profile.bots.allianceRatio
    'Playerbots.RandomBotHordeRatio'=[string]$profile.bots.hordeRatio
    'Playerbots.RandomBotRpgChance'=Format-Rate $profile.bots.rpgChance
    'Playerbots.RandomBotJoinLfg'=if ($profile.bots.joinLfg) {'1'} else {'0'}
    'Playerbots.RandomBotTalk'=if ($profile.bots.talk) {'1'} else {'0'}
    'Playerbots.RandomBotSuggestDungeons'=if ($profile.bots.suggestDungeons) {'1'} else {'0'}
    'Playerbots.RandomBotInvitePlayer'=if ($profile.bots.inviteHumanPlayers) {'1'} else {'0'}
    'Playerbots.DisabledWithoutRealPlayer'=if ($profile.bots.disabledWithoutRealPlayer) {'1'} else {'0'}
    'Playerbots.AutoEquipUpgradeLoot'=if ($profile.bots.autoEquipUpgradeLoot) {'1'} else {'0'}
}
Write-Host "Perfil e conexões do MySQL local configurados. Backup dos templates em $backup" -ForegroundColor Green
