local destinations = {
  { name = "Reinos do Leste", places = {
    { "Ventobravo", 0 }, { "Altaforja", 1 }, { "Cidade Baixa", 6 }, { "Luaprata", 7 },
  } },
  { name = "Kalimdor", places = {
    { "Darnassus", 2 }, { "Exodar", 3 }, { "Orgrimmar", 4 }, { "Penhasco do Trovão", 5 },
  } },
  { name = "Terralém", places = {
    { "Península Fogo do Inferno (nível 58)", 12 },
    { "Shattrath (nível 60)", 8 }, { "Nagrand (nível 64)", 13 },
  } },
  { name = "Nortúndria", places = {
    { "Tundra Boreana (nível 68)", 10 }, { "Fiorde Uivante (nível 68)", 11 },
    { "Dalaran (nível 74)", 9 },
  } },
}

local frame = CreateFrame("Frame", "SoloTeleportFrame", UIParent)
frame:SetWidth(350)
frame:SetHeight(330)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
table.insert(UISpecialFrames, "SoloTeleportFrame")
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -18)
title:SetText("SoloRealm — Teletransporte")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
close:SetScript("OnClick", function() frame:Hide() end)

local buttons = {}
local function clearButtons()
  for _, button in ipairs(buttons) do button:Hide() end
  buttons = {}
end

local function addButton(label, row, callback)
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetWidth(290)
  button:SetHeight(30)
  button:SetPoint("TOP", frame, "TOP", 0, -52 - ((row - 1) * 36))
  button:SetText(label)
  button:SetScript("OnClick", callback)
  table.insert(buttons, button)
end

local showRegions
local function showPlaces(region)
  clearButtons()
  title:SetText(region.name)
  for index, place in ipairs(region.places) do
    local selectedPlace = place
    addButton(selectedPlace[1], index, function()
      if not UnitExists("player") then
        DEFAULT_CHAT_FRAME:AddMessage("Solo Realm Addons: entre no mundo para usar o teletransporte.")
        return
      end
      SendChatMessage(".wowteleport " .. selectedPlace[2], "SAY")
      frame:Hide()
    end)
  end
  addButton("Voltar aos continentes", #region.places + 1, showRegions)
end

showRegions = function()
  clearButtons()
  title:SetText("Escolha um continente")
  for index, region in ipairs(destinations) do
    local selectedRegion = region
    addButton(selectedRegion.name, index, function() showPlaces(selectedRegion) end)
  end
end

local function toggle()
  if frame:IsShown() then
    frame:Hide()
  else
    showRegions()
    frame:Show()
  end
end

SLASH_SOLOREALMTELEPORT1 = "/teleport"
SlashCmdList.SOLOREALMTELEPORT = toggle
_G.SoloTeleportToggle = toggle
BINDING_NAME_SOLOREALMTELEPORT_TOGGLE = "Abrir Teletransportes"

DEFAULT_CHAT_FRAME:AddMessage("Solo Realm Addons carregado. Use /shop, /teleport ou /resettalentos.")
