DELETE FROM `creature` WHERE `guid` IN (9001001, 9001002, 9001003, 9001004, 9001005, 9001006, 9001007, 9001008) AND `id` = 900101;
DELETE FROM `creature_template` WHERE `entry` = 900101;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 900101;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 900100;

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`, `flags_extra`, `ScriptName`)
VALUES (900101, 'Mercador do Reino', 'Loja por gold', 80, 80, 35, 1, 1, 7, 0, 'npc_wow_shop');

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (900101, 0, 3167, 1, 1), (900100, 0, 3167, 1, 1);

INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
VALUES
    (9001001, 900101, 0, 1519, 1519, 1, 1, -8867.57, 673.37, 97.90, 3.10, 300, 0, 0, 'Loja por gold - Stormwind'),
    (9001002, 900101, 0, 1537, 1537, 1, 1, -4835.59, -1232.57, 501.87, 2.30, 300, 0, 0, 'Loja por gold - Ironforge'),
    (9001003, 900101, 1, 1657, 1657, 1, 1, 9946.43, 2495.07, 1318.67, 3.20, 300, 0, 0, 'Loja por gold - Darnassus'),
    (9001004, 900101, 530, 3557, 3557, 1, 1, -4051.35, -11753.65, -138.61, 1.50, 300, 0, 0, 'Loja por gold - Exodar'),
    (9001005, 900101, 1, 1637, 1637, 1, 1, 1630.00, -4438.60, 15.76, 3.10, 300, 0, 0, 'Loja por gold - Orgrimmar'),
    (9001006, 900101, 1, 1638, 1638, 1, 1, -1274.25, 90.99, 128.16, 5.00, 300, 0, 0, 'Loja por gold - Thunder Bluff'),
    (9001007, 900101, 0, 1497, 1497, 1, 1, 1632.36, 220.99, -43.10, 3.14, 300, 0, 0, 'Loja por gold - Undercity'),
    (9001008, 900101, 530, 3487, 3487, 1, 1, 9487.69, -7279.20, 14.29, 0.00, 300, 0, 0, 'Loja por gold - Silvermoon');
