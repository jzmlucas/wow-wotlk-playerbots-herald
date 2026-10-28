#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Player.h"
#include "Creature.h"
#include "WorldSession.h"
#include "RBAC.h"

#include <array>
#include <cstring>

using namespace Acore::ChatCommands;

namespace
{
struct Destination
{
    char const* name;
    uint32 map;
    float x;
    float y;
    float z;
    float orientation;
    uint8 level;
};

constexpr std::array<Destination, 14> Destinations = {{
    {"Stormwind", 0, -8833.38f, 628.62f, 94.01f, 0.70f, 1},
    {"Ironforge", 0, -4981.25f, -881.54f, 501.66f, 5.40f, 1},
    {"Darnassus", 1, 9947.52f, 2482.73f, 1316.21f, 1.57f, 1},
    {"Exodar", 530, -3864.92f, -11643.70f, -137.64f, 5.50f, 1},
    {"Orgrimmar", 1, 1633.33f, -4439.11f, 15.76f, 0.00f, 1},
    {"Thunder Bluff", 1, -1277.37f, 124.80f, 131.29f, 5.00f, 1},
    {"Undercity", 0, 1637.28f, 239.13f, -43.03f, 3.14f, 1},
    {"Silvermoon", 530, 9487.69f, -7279.20f, 14.29f, 0.00f, 1},
    {"Shattrath", 530, -1887.62f, 5359.16f, -12.43f, 4.40f, 60},
    {"Dalaran", 571, 5807.75f, 588.35f, 661.20f, 1.64f, 74},
    {"Borean Tundra", 571, 2954.14f, 5370.22f, 60.45f, 2.00f, 68},
    {"Howling Fjord", 571, 1902.16f, -4883.91f, 171.20f, 1.57f, 68},
    {"Hellfire Peninsula", 530, -207.90f, 2035.24f, 96.46f, 1.57f, 58},
    {"Nagrand", 530, -1610.85f, 7733.62f, -17.28f, 1.57f, 64}
}};

enum GossipAction : uint32
{
    MainMenu = 1,
    EasternKingdoms,
    Kalimdor,
    Outland,
    Northrend,
    DestinationBase = 100
};

uint32 RegionForMap(uint32 map, char const* name)
{
    if (std::strcmp(name, "Exodar") == 0)
        return Kalimdor;
    if (std::strcmp(name, "Silvermoon") == 0)
        return EasternKingdoms;
    if (map == 0)
        return EasternKingdoms;
    if (map == 1)
        return Kalimdor;
    if (map == 530)
        return Outland;
    return Northrend;
}

bool TryTeleport(Player* player, size_t index)
{
    if (index >= Destinations.size())
        return false;

    Destination const& destination = Destinations[index];
    if (player->IsInCombat() || player->IsInFlight() || player->IsBeingTeleported() || !player->IsAlive())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("You cannot teleport right now.");
        return false;
    }

    if (player->GetLevel() < destination.level)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("You do not meet the level requirement.");
        return false;
    }

    player->TeleportTo(destination.map, destination.x, destination.y, destination.z, destination.orientation);
    return true;
}

class npc_wow_teleporter final : public CreatureScript
{
public:
    npc_wow_teleporter() : CreatureScript("npc_wow_teleporter") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Eastern Kingdoms", GOSSIP_SENDER_MAIN, EasternKingdoms);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Kalimdor", GOSSIP_SENDER_MAIN, Kalimdor);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Outland", GOSSIP_SENDER_MAIN, Outland);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Northrend", GOSSIP_SENDER_MAIN, Northrend);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);
        if (action == MainMenu)
            return OnGossipHello(player, creature);

        if (action >= EasternKingdoms && action <= Northrend)
        {
            for (uint32 i = 0; i < Destinations.size(); ++i)
                if (RegionForMap(Destinations[i].map, Destinations[i].name) == action)
                    AddGossipItemFor(player, GOSSIP_ICON_TAXI, Destinations[i].name,
                        GOSSIP_SENDER_MAIN, DestinationBase + i);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Voltar", GOSSIP_SENDER_MAIN, MainMenu);
            SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            return true;
        }

        if (action >= DestinationBase && action < DestinationBase + Destinations.size())
        {
            CloseGossipMenuFor(player);
            TryTeleport(player, action - DestinationBase);
            return true;
        }

        CloseGossipMenuFor(player);
        return true;
    }
};

class wow_teleporter_commandscript final : public CommandScript
{
public:
    wow_teleporter_commandscript() : CommandScript("wow_teleporter_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "wowteleport", HandleTeleportCommand, SEC_PLAYER, Console::No }
        };
        return commandTable;
    }

    static bool HandleTeleportCommand(ChatHandler* handler, uint32 index)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;

        TryTeleport(player, index);
        return true;
    }
};
}

void AddSC_wow_teleporter()
{
    new npc_wow_teleporter();
    new wow_teleporter_commandscript();
}
