-- Rode uma vez no banco acore_auth depois de importar a base AzerothCore.
UPDATE realmlist
SET name = 'Reino Local', address = '127.0.0.1', localAddress = '127.0.0.1', localSubnetMask = '255.255.255.0', gamebuild = 12340
WHERE id = 1;
