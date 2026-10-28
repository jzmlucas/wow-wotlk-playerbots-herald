DELETE FROM `creature` WHERE `guid` = 9001000 AND `id` = 900100;
DELETE FROM `creature_template` WHERE `entry` = 900100;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 900100;

INSERT INTO `creature_template`
    (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`, `flags_extra`, `ScriptName`)
VALUES
    (900100, 'Teleportador', 'Viagem entre regiões', 80, 80, 35, 1, 1, 7, 0, 'npc_wow_teleporter');

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (900100, 0, 3167, 1, 1);

INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
VALUES
    (9001000, 900100, 0, 1519, 1519, 1, 1, -8833.38, 628.62, 94.01, 0.70, 300, 0, 0, 'NPC Teletransportador do reino');
