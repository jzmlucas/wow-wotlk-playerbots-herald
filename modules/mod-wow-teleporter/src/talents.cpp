#include "Chat.h"
#include "CommandScript.h"
#include "Player.h"
#include "RBAC.h"
#include "WorldSession.h"

using namespace Acore::ChatCommands;

namespace
{
class wow_talents_commandscript final : public CommandScript
{
public:
    wow_talents_commandscript() : CommandScript("wow_talents_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "resettalentos", HandleResetTalentsCommand, SEC_PLAYER, Console::No }
        };
        return commandTable;
    }

    static bool HandleResetTalentsCommand(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;

        if (player->IsInCombat() || player->IsInFlight() || player->IsBeingTeleported() || !player->IsAlive())
        {
            handler->SendSysMessage(
                "Voce nao pode resetar talentos durante combate, voo, teletransporte ou enquanto estiver morto.");
            return true;
        }

        if (!player->resetTalents(true))
        {
            handler->SendSysMessage("A especializacao ativa ja esta sem talentos para resetar.");
            return true;
        }

        player->SendTalentsInfoData(false);
        handler->SendSysMessage(
            "Talentos da especializacao ativa resetados de graca. "
            "Abra a janela de talentos para redistribuir os pontos.");
        return true;
    }
};
}

void AddSC_wow_talents()
{
    new wow_talents_commandscript();
}
