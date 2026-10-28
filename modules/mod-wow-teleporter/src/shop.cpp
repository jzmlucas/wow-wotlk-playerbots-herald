#include "Chat.h"
#include "CommandScript.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SharedDefines.h"
#include "StringFormat.h"
#include "WorldSession.h"

#include "shop_catalog.h"

#include <algorithm>
#include <cstddef>
#include <string>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 ShopCategoryActionBase = 1000;
constexpr uint32 ShopPageActionBase = 10000;
constexpr uint32 ShopPageActionStride = 1000;
constexpr uint32 ShopPurchaseActionBase = 20000;
constexpr size_t ShopItemsPerNpcPage = GOSSIP_MAX_MENU_ITEMS - 3;

std::string FormatShopMoney(uint32 copper)
{
    uint32 gold = copper / GOLD;
    uint32 silver = (copper % GOLD) / SILVER;
    copper %= SILVER;
    std::string result;

    if (gold)
        result = std::to_string(gold) + "g";
    if (silver)
    {
        if (!result.empty())
            result += " ";
        result += std::to_string(silver) + "s";
    }
    if (copper || result.empty())
    {
        if (!result.empty())
            result += " ";
        result += std::to_string(copper) + "c";
    }

    return result;
}

uint32 MakeShopPageAction(ShopCategory category, size_t page)
{
    return ShopPageActionBase + static_cast<uint32>(category) * ShopPageActionStride + static_cast<uint32>(page);
}

bool BuyShopItem(Player* player, size_t shopIndex)
{
    if (shopIndex >= ShopCatalog.size())
        return false;

    ShopEntry const& entry = ShopCatalog[shopIndex];
    ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(entry.itemId);
    if (!itemTemplate)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Este item da loja esta indisponivel no momento.");
        return false;
    }

    uint32 priceCopper = entry.priceCopper;
    if (player->GetMoney() < priceCopper)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Voce nao tem moeda suficiente para esta compra.");
        return false;
    }

    ItemPosCountVec inventoryPositions;
    InventoryResult inventoryResult = player->CanStoreNewItem(
        NULL_BAG, NULL_SLOT, inventoryPositions, entry.itemId, entry.count);
    if (inventoryResult != EQUIP_ERR_OK)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Libere espaco na bolsa antes de comprar este item.");
        return false;
    }

    Item* item = player->StoreNewItem(inventoryPositions, entry.itemId, true);
    if (!item)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Nao foi possivel entregar o item; seu gold nao foi cobrado.");
        return false;
    }

    player->SetMoney(player->GetMoney() - priceCopper);
    player->SendNewItem(item, entry.count, true, false);
    ChatHandler(player->GetSession()).PSendSysMessage(
        "Compra concluida: {} x{} por {}.", itemTemplate->Name1, entry.count, FormatShopMoney(priceCopper));
    return true;
}

void AddShopCategoryItems(Player* player, Creature* creature, ShopCategory category, size_t page)
{
    std::vector<size_t> categoryItems;
    for (size_t i = 0; i < ShopCatalog.size(); ++i)
    {
        ShopEntry const& entry = ShopCatalog[i];
        if (entry.category != category || !sObjectMgr->GetItemTemplate(entry.itemId))
            continue;
        if (entry.glyphClassId && entry.glyphClassId != player->getClass())
            continue;
        if (entry.allowableClassMask != -1 && !(static_cast<uint32>(entry.allowableClassMask) & player->getClassMask()))
            continue;
        if (entry.requiredLevel > player->GetLevel())
            continue;

        categoryItems.push_back(i);
    }

    size_t pageCount = (categoryItems.size() + ShopItemsPerNpcPage - 1) / ShopItemsPerNpcPage;
    if (pageCount == 0)
        page = 0;
    else if (page >= pageCount)
        page = pageCount - 1;

    size_t first = page * ShopItemsPerNpcPage;
    size_t last = std::min(first + ShopItemsPerNpcPage, categoryItems.size());
    for (size_t position = first; position < last; ++position)
    {
        size_t shopIndex = categoryItems[position];
        ShopEntry const& entry = ShopCatalog[shopIndex];
        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(entry.itemId);
        std::string label = Acore::StringFormat("{} - {} (x{})",
            itemTemplate->Name1, FormatShopMoney(entry.priceCopper), entry.count);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, label,
            GOSSIP_SENDER_MAIN, ShopPurchaseActionBase + static_cast<uint32>(shopIndex));
    }

    if (page > 0)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Itens anteriores",
            GOSSIP_SENDER_MAIN, MakeShopPageAction(category, page - 1));
    if (page + 1 < pageCount)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Proximos itens",
            GOSSIP_SENDER_MAIN, MakeShopPageAction(category, page + 1));
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Voltar as categorias",
        GOSSIP_SENDER_MAIN, ShopCategoryActionBase - 1);
    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
}

class npc_wow_shop final : public CreatureScript
{
public:
    npc_wow_shop() : CreatureScript("npc_wow_shop") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        for (size_t i = 0; i < ShopCategoryNames.size(); ++i)
            AddGossipItemFor(player, GOSSIP_ICON_VENDOR, ShopCategoryNames[i],
                GOSSIP_SENDER_MAIN, ShopCategoryActionBase + static_cast<uint32>(i));

        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);

        if (action == ShopCategoryActionBase - 1)
        {
            CloseGossipMenuFor(player);
            return OnGossipHello(player, creature);
        }

        if (action >= ShopCategoryActionBase && action < ShopCategoryActionBase + ShopCategoryNames.size())
        {
            AddShopCategoryItems(player, creature, static_cast<ShopCategory>(action - ShopCategoryActionBase), 0);
            return true;
        }

        if (action >= ShopPageActionBase && action < ShopPurchaseActionBase)
        {
            uint32 pageAction = action - ShopPageActionBase;
            uint32 categoryIndex = pageAction / ShopPageActionStride;
            size_t page = pageAction % ShopPageActionStride;
            if (categoryIndex < ShopCategoryNames.size())
            {
                AddShopCategoryItems(player, creature, static_cast<ShopCategory>(categoryIndex), page);
                return true;
            }
        }

        if (action >= ShopPurchaseActionBase && action < ShopPurchaseActionBase + ShopCatalog.size())
        {
            CloseGossipMenuFor(player);
            BuyShopItem(player, action - ShopPurchaseActionBase);
            return true;
        }

        CloseGossipMenuFor(player);
        return true;
    }
};

class wow_shop_commandscript final : public CommandScript
{
public:
    wow_shop_commandscript() : CommandScript("wow_shop_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable shopCommandTable =
        {
            { "buy", HandleBuyCommand, SEC_PLAYER, Console::No }
        };
        static ChatCommandTable commandTable =
        {
            { "wowshop", shopCommandTable }
        };
        return commandTable;
    }

    static bool HandleBuyCommand(ChatHandler* handler, uint32 shopIndex)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;

        BuyShopItem(player, shopIndex);
        return true;
    }
};
}

void AddSC_wow_shop()
{
    new npc_wow_shop();
    new wow_shop_commandscript();
}
