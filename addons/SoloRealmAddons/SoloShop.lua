local shopFrame = CreateFrame("Frame", "SoloShopFrame", UIParent)
shopFrame:SetWidth(870)
shopFrame:SetHeight(570)
shopFrame:SetPoint("CENTER")
shopFrame:SetFrameStrata("DIALOG")
shopFrame:SetMovable(true)
shopFrame:EnableMouse(true)
shopFrame:RegisterForDrag("LeftButton")
table.insert(UISpecialFrames, "SoloShopFrame")
shopFrame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
shopFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
shopFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
shopFrame:Hide()

local shopTitle = shopFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
shopTitle:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 28, -20)
shopTitle:SetText("Loja do Reino")
shopTitle:SetTextColor(1, 0.82, 0.25)

local shopGold = shopFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
shopGold:SetPoint("TOPRIGHT", shopFrame, "TOPRIGHT", -42, -24)
shopGold:SetTextColor(1, 0.82, 0.25)

local closeShop = CreateFrame("Button", nil, shopFrame, "UIPanelCloseButton")
closeShop:SetPoint("TOPRIGHT", shopFrame, "TOPRIGHT", -5, -5)
closeShop:SetScript("OnClick", function() shopFrame:Hide() end)

local goldLine = shopFrame:CreateTexture(nil, "ARTWORK")
goldLine:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 20, -48)
goldLine:SetPoint("TOPRIGHT", shopFrame, "TOPRIGHT", -20, -48)
goldLine:SetHeight(2)
goldLine:SetTexture(0.72, 0.52, 0.18, 0.9)

local categoryPanel = CreateFrame("Frame", nil, shopFrame)
categoryPanel:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 22, -94)
categoryPanel:SetWidth(142)
categoryPanel:SetHeight(420)
categoryPanel:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
categoryPanel:SetBackdropColor(0.04, 0.04, 0.04, 0.9)

local categoryButtons = {}
local categoryHeader = categoryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryHeader:SetPoint("TOP", categoryPanel, "TOP", 0, -12)
categoryHeader:SetText("Categorias")
categoryHeader:SetTextColor(0.92, 0.76, 0.42)

local itemGrid = CreateFrame("Frame", nil, shopFrame)
itemGrid:SetPoint("TOPLEFT", categoryPanel, "TOPRIGHT", 12, 0)
itemGrid:SetWidth(420)
itemGrid:SetHeight(420)

local previewPanel = CreateFrame("Frame", nil, shopFrame)
previewPanel:SetPoint("TOPLEFT", itemGrid, "TOPRIGHT", 12, 32)
previewPanel:SetWidth(220)
previewPanel:SetHeight(450)
previewPanel:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
previewPanel:SetBackdropColor(0.04, 0.04, 0.04, 0.9)

local previewTitle = previewPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
previewTitle:SetPoint("TOP", previewPanel, "TOP", 0, -12)
previewTitle:SetText("Visualização")
previewTitle:SetTextColor(0.92, 0.76, 0.42)

local previewModel = CreateFrame("DressUpModel", "SoloShopPreview", previewPanel)
previewModel:SetPoint("TOPLEFT", previewPanel, "TOPLEFT", 12, -34)
previewModel:SetWidth(196)
previewModel:SetHeight(180)
previewModel:SetUnit("player")

local previewIcon = previewPanel:CreateTexture(nil, "OVERLAY")
previewIcon:SetPoint("TOP", previewPanel, "TOP", 0, -220)
previewIcon:SetWidth(56)
previewIcon:SetHeight(56)
previewIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
previewIcon:SetDrawLayer("OVERLAY", 2)

local previewName = previewPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
previewName:SetPoint("TOPLEFT", previewPanel, "TOPLEFT", 12, -282)
previewName:SetWidth(196)
previewName:SetJustifyH("CENTER")
previewName:SetText("Selecione um item")
previewName:SetTextColor(1, 0.82, 0.25)

local previewDescription = previewPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
previewDescription:SetPoint("TOPLEFT", previewName, "BOTTOMLEFT", 0, -8)
previewDescription:SetWidth(196)
previewDescription:SetJustifyH("CENTER")
previewDescription:SetText("Escolha um produto para ver a prévia e o preço.")

local previewStatus = previewPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
previewStatus:SetPoint("TOPLEFT", previewDescription, "BOTTOMLEFT", 0, -8)
previewStatus:SetWidth(196)
previewStatus:SetJustifyH("CENTER")
previewStatus:SetText("Prévia visual: selecionar não equipa nem compra.")

local selectedItem
local selectedCategory
local currentPage = 1
local visibleItems = {}
local itemButtons = {}
local updateShopPreview
local classIdsByToken
local selectedClassFilter = "player"
local selectedLevel = 80
local emptyFilterMessage

local function getShopItemIcon(itemId)
  local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
  return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function createItemCard(index)
  local card = CreateFrame("Button", nil, itemGrid)
  card:SetWidth(132)
  card:SetHeight(100)
  card:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  card:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
  local row = math.floor((index - 1) / 3)
  local column = (index - 1) % 3
  card:SetPoint("TOPLEFT", itemGrid, "TOPLEFT", column * 140 + 2, -2 - row * 108)

  card.icon = card:CreateTexture(nil, "ARTWORK")
  card.icon:SetPoint("TOP", card, "TOP", 0, -9)
  card.icon:SetWidth(38)
  card.icon:SetHeight(38)
  card.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

  card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -51)
  card.name:SetWidth(122)
  card.name:SetHeight(22)
  card.name:SetJustifyH("CENTER")
  card.name:SetWordWrap(false)

  card.price = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  card.price:SetPoint("BOTTOM", card, "BOTTOM", 0, 7)
  card.price:SetTextColor(1, 0.78, 0.28)
  card:SetScript("OnClick", function(self)
    if self.item then
      selectedItem = self.item
      updateShopPreview()
    end
  end)
  card:SetScript("OnEnter", function(self)
    if self.item then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetHyperlink("item:" .. self.item.id)
      GameTooltip:Show()
    end
  end)
  card:SetScript("OnLeave", function() GameTooltip:Hide() end)
  itemButtons[index] = card
  return card
end

local buyButton = CreateFrame("Button", nil, previewPanel, "UIPanelButtonTemplate")
buyButton:SetWidth(178)
buyButton:SetHeight(28)
buyButton:SetPoint("BOTTOM", previewPanel, "BOTTOM", 0, 34)
buyButton:SetText("Comprar")

local function formatMoney(copper)
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local remainder = copper % 100
  local parts = {}
  if gold > 0 then table.insert(parts, gold .. " g") end
  if silver > 0 then table.insert(parts, silver .. " s") end
  if remainder > 0 or #parts == 0 then table.insert(parts, remainder .. " c") end
  return table.concat(parts, " ")
end

local wearableSlots = {
  INVTYPE_HEAD = true, INVTYPE_NECK = true, INVTYPE_SHOULDER = true,
  INVTYPE_BODY = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
  INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true,
  INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_FINGER = true,
  INVTYPE_TRINKET = true, INVTYPE_CLOAK = true, INVTYPE_WEAPON = true,
  INVTYPE_SHIELD = true, INVTYPE_2HWEAPON = true,
  INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true,
  INVTYPE_HOLDABLE = true, INVTYPE_RANGED = true,
  INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true, INVTYPE_RELIC = true,
  INVTYPE_TABARD = true,
}

updateShopPreview = function()
  if not selectedItem then return end
  local itemName, itemLink, _, _, _, _, _, _, equipLocation = GetItemInfo(selectedItem.id)
  previewName:SetText(itemName or selectedItem.name)
  local requiredLevelText = selectedItem.requiredLevel > 0 and ("\nNível mínimo: " .. selectedItem.requiredLevel) or "\nSem nível mínimo"
  previewDescription:SetText("Preço: " .. formatMoney(selectedItem.priceCopper) .. "\nQuantidade: " .. selectedItem.count .. requiredLevelText)
  previewIcon:SetTexture(getShopItemIcon(selectedItem.id))
  previewModel:Undress()
  previewModel:SetUnit("player")

  -- Preview only in the isolated DressUpModel; never equip the real character.
  -- Non-equipment products use an enlarged icon instead.
  local previewedOnModel = false
  if itemLink and wearableSlots[equipLocation] and previewModel.TryOn then
    previewedOnModel = pcall(previewModel.TryOn, previewModel, itemLink)
  end
  if previewedOnModel then
    previewModel:Show()
    previewIcon:ClearAllPoints()
    previewIcon:SetPoint("TOP", previewPanel, "TOP", 0, -220)
    previewIcon:SetWidth(56)
    previewIcon:SetHeight(56)
    previewStatus:SetText("Prévia 3D local. O personagem não foi equipado.")
  else
    previewModel:Hide()
    previewIcon:ClearAllPoints()
    previewIcon:SetPoint("TOP", previewPanel, "TOP", 0, -74)
    previewIcon:SetWidth(128)
    previewIcon:SetHeight(128)
    previewStatus:SetText("Prévia visual do item. Selecionar não compra nem equipa.")
  end
  shopGold:SetText("Meu saldo: " .. formatMoney(GetMoney()))
end

local function refreshShopItems(category, page)
  selectedCategory = category
  visibleItems = {}
  local classId
  if selectedClassFilter == "player" then
    local _, classToken = UnitClass("player")
    classId = classIdsByToken[classToken]
  elseif selectedClassFilter ~= "all" then
    classId = classIdsByToken[selectedClassFilter]
  end
  for _, item in ipairs(category.items) do
    local classMatches = not classId
    if classId then
      if item.glyphClass and item.glyphClass > 0 then
        classMatches = item.glyphClass == classId
      elseif item.classMask == -1 then
        classMatches = true
      else
        local classBit = 2 ^ (classId - 1)
        classMatches = math.floor(item.classMask / classBit) % 2 == 1
      end
    end
    local levelMatches = (item.requiredLevel or 0) == 0 or item.requiredLevel <= selectedLevel
    if classMatches and levelMatches then table.insert(visibleItems, item) end
  end

  local pageSize = 12
  local pageCount = math.max(1, math.ceil(#visibleItems / pageSize))
  page = math.max(1, math.min(page, pageCount))
  currentPage = page
  selectedItem = nil
  shopTitle:SetText("Loja do Reino  |  " .. category.name)
  previewName:SetText("Selecione um item")
  previewDescription:SetText("Clique em um produto para ver a prévia.")
  previewIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  previewModel:Undress()
  previewModel:SetUnit("player")
  previewModel:Show()
  previewIcon:ClearAllPoints()
  previewIcon:SetPoint("TOP", previewPanel, "TOP", 0, -220)
  previewIcon:SetWidth(56)
  previewIcon:SetHeight(56)
  previewStatus:SetText("Prévia visual: selecionar não equipa nem compra.")
  local first = ((page - 1) * pageSize) + 1
  local last = math.min(first + pageSize - 1, #visibleItems)
  if #visibleItems == 0 then emptyFilterMessage:Show() else emptyFilterMessage:Hide() end
  for slot = 1, pageSize do
    local card = itemButtons[slot] or createItemCard(slot)
    local item = visibleItems[first + slot - 1]
    card.item = item
    if item and first + slot - 1 <= last then
      card.name:SetText(item.name)
      card.price:SetText(formatMoney(item.priceCopper))
      card.icon:SetTexture(getShopItemIcon(item.id))
      card:Show()
    else
      card:Hide()
    end
  end
  shopGold:SetText("Meu saldo: " .. formatMoney(GetMoney()))
end

local function refreshSelectedCategory()
  if selectedCategory then refreshShopItems(selectedCategory, 1) end
end

classIdsByToken = {
  WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
  DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9, DRUID = 11,
}
local classNames = {
  WARRIOR = "Guerreiro", PALADIN = "Paladino", HUNTER = "Caçador", ROGUE = "Ladino",
  PRIEST = "Sacerdote", DEATHKNIGHT = "Cavaleiro da Morte", SHAMAN = "Xamã",
  MAGE = "Mago", WARLOCK = "Bruxo", DRUID = "Druida",
}
local classOptions = {
  { text = "Minha classe", value = "player" },
  { text = "Todas as classes", value = "all" },
  { text = "Guerreiro", value = "WARRIOR" },
  { text = "Paladino", value = "PALADIN" },
  { text = "Caçador", value = "HUNTER" },
  { text = "Ladino", value = "ROGUE" },
  { text = "Sacerdote", value = "PRIEST" },
  { text = "Cavaleiro da Morte", value = "DEATHKNIGHT" },
  { text = "Xamã", value = "SHAMAN" },
  { text = "Mago", value = "MAGE" },
  { text = "Bruxo", value = "WARLOCK" },
  { text = "Druida", value = "DRUID" },
}
selectedLevel = math.max(1, math.min(80, UnitLevel("player") or 80))

local classFilterLabel = shopFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
classFilterLabel:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 23, -58)
classFilterLabel:SetText("Classe:")
classFilterLabel:SetTextColor(0.92, 0.76, 0.42)

local classFilter = CreateFrame("Frame", "SoloShopClassFilter", shopFrame, "UIDropDownMenuTemplate")
classFilter:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 63, -45)
UIDropDownMenu_SetWidth(classFilter, 140)
UIDropDownMenu_Initialize(classFilter, function(_, level)
  for _, option in ipairs(classOptions) do
    local selectedOption = option
    local info = UIDropDownMenu_CreateInfo()
    info.text = selectedOption.text
    info.checked = selectedClassFilter == selectedOption.value
    info.func = function()
      selectedClassFilter = selectedOption.value
      UIDropDownMenu_SetText(classFilter, selectedOption.text)
      refreshSelectedCategory()
    end
    UIDropDownMenu_AddButton(info, level)
  end
end)
local _, playerClassToken = UnitClass("player")
if classNames[playerClassToken] then
  classOptions[1].text = "Meu personagem (" .. classNames[playerClassToken] .. ")"
end
UIDropDownMenu_SetText(classFilter, classOptions[1].text)

local levelFilterLabel = shopFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
levelFilterLabel:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 270, -58)
levelFilterLabel:SetText("Nível do personagem:")
levelFilterLabel:SetTextColor(0.92, 0.76, 0.42)

local levelFilter = CreateFrame("EditBox", "SoloShopLevelFilter", shopFrame, "InputBoxTemplate")
levelFilter:SetPoint("TOPLEFT", shopFrame, "TOPLEFT", 342, -56)
levelFilter:SetWidth(42)
levelFilter:SetHeight(22)
levelFilter:SetAutoFocus(false)
levelFilter:SetNumeric(true)
levelFilter:SetMaxLetters(2)
levelFilter:SetText(tostring(selectedLevel))

local function applyLevelFilter()
  local level = tonumber(levelFilter:GetText()) or UnitLevel("player") or 80
  selectedLevel = math.max(1, math.min(80, math.floor(level)))
  levelFilter:SetText(tostring(selectedLevel))
  refreshSelectedCategory()
end

levelFilter:SetScript("OnEnterPressed", function(self)
  applyLevelFilter()
  self:ClearFocus()
end)
levelFilter:SetScript("OnEditFocusLost", applyLevelFilter)
levelFilter:SetScript("OnEscapePressed", function(self)
  self:SetText(tostring(selectedLevel))
  self:ClearFocus()
end)

emptyFilterMessage = itemGrid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
emptyFilterMessage:SetPoint("CENTER", itemGrid, "CENTER", 0, 0)
emptyFilterMessage:SetWidth(390)
emptyFilterMessage:SetJustifyH("CENTER")
emptyFilterMessage:SetText("Nenhum item compatível com estes filtros.")
emptyFilterMessage:Hide()

local function refreshCategoryButtons()
  for _, button in ipairs(categoryButtons) do button:Hide() end
  categoryButtons = {}
  for index, category in ipairs(SoloShopCatalog.categories) do
    local selectedCategory = category
    local button = CreateFrame("Button", nil, categoryPanel, "UIPanelButtonTemplate")
    button:SetWidth(126)
    button:SetHeight(31)
    button:SetPoint("TOP", categoryPanel, "TOP", 0, -35 - ((index - 1) * 37))
    button:SetText(category.name)
    button:SetScript("OnClick", function() refreshShopItems(selectedCategory, 1) end)
    table.insert(categoryButtons, button)
  end
end

buyButton:SetScript("OnClick", function()
  if not selectedItem then
    DEFAULT_CHAT_FRAME:AddMessage("Solo Realm Addons: selecione um item antes de comprar.")
    return
  end
  if not UnitExists("player") then
    DEFAULT_CHAT_FRAME:AddMessage("Solo Realm Addons: entre no mundo para usar a loja.")
    return
  end
  SendChatMessage(".wowshop buy " .. selectedItem.index, "SAY")
  shopFrame:Hide()
end)

local previousPage = CreateFrame("Button", nil, shopFrame, "UIPanelButtonTemplate")
previousPage:SetWidth(120)
previousPage:SetHeight(25)
previousPage:SetPoint("BOTTOMLEFT", shopFrame, "BOTTOMLEFT", 180, 20)
previousPage:SetText("Pagina anterior")
previousPage:SetScript("OnClick", function()
  if selectedCategory and currentPage > 1 then refreshShopItems(selectedCategory, currentPage - 1) end
end)

local nextPage = CreateFrame("Button", nil, shopFrame, "UIPanelButtonTemplate")
nextPage:SetWidth(120)
nextPage:SetHeight(25)
nextPage:SetPoint("BOTTOMLEFT", shopFrame, "BOTTOMLEFT", 310, 20)
nextPage:SetText("Proxima pagina")
nextPage:SetScript("OnClick", function()
  if selectedCategory and currentPage * 12 < #visibleItems then
    refreshShopItems(selectedCategory, currentPage + 1)
  end
end)

local function toggleShopPanel()
  if shopFrame:IsShown() then
    shopFrame:Hide()
  else
    refreshCategoryButtons()
    shopGold:SetText("Meu saldo: " .. formatMoney(GetMoney()))
    local category = selectedCategory or SoloShopCatalog.categories[1]
    refreshShopItems(category, currentPage or 1)
    shopFrame:Show()
  end
end

SLASH_SOLOREALMSHOP1 = "/shop"
SlashCmdList.SOLOREALMSHOP = toggleShopPanel
_G.SoloShopToggle = toggleShopPanel
BINDING_NAME_SOLOREALMSHOP_TOGGLE = "Abrir Loja de Ouro"
