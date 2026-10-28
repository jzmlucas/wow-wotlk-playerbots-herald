local gameMenu = GameMenuFrame
BINDING_HEADER_SOLOREALMADDONS = "Solo Realm Addons"
if not gameMenu then
  DEFAULT_CHAT_FRAME:AddMessage("Solo Realm Addons: o menu de jogo não foi encontrado.")
  return
end

local function resetTalents()
  if not UnitExists("player") then
    DEFAULT_CHAT_FRAME:AddMessage("Solo Realm Addons: entre no mundo para resetar os talentos.")
    return
  end
  SendChatMessage(".resettalentos", "SAY")
end

SLASH_SOLOREALMRESETTALENTS1 = "/resettalentos"
SlashCmdList.SOLOREALMRESETTALENTS = resetTalents

StaticPopupDialogs["SOLOREALM_RESET_TALENTS"] = {
  text = "Resetar de graça os talentos da especialização ativa?",
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = resetTalents,
  timeout = 0,
  whileDead = false,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function openShop()
  HideUIPanel(gameMenu)
  SoloShopToggle()
end

local function openTeleport()
  HideUIPanel(gameMenu)
  SoloTeleportToggle()
end

local function confirmTalentReset()
  HideUIPanel(gameMenu)
  StaticPopup_Show("SOLOREALM_RESET_TALENTS")
end

local originalHeight = gameMenu:GetHeight()
local buttonWidth = GameMenuButtonOptions and GameMenuButtonOptions:GetWidth() or 144
local buttonHeight = GameMenuButtonOptions and GameMenuButtonOptions:GetHeight() or 21

local function addMenuButton(name, label, anchor, offset, onClick)
  local button = CreateFrame("Button", name, gameMenu, "GameMenuButtonTemplate")
  button:SetWidth(buttonWidth)
  button:SetHeight(buttonHeight)
  button:SetText(label)
  button:SetPoint("TOP", anchor, anchor == gameMenu and "TOP" or "BOTTOM", 0, offset)
  button:SetScript("OnClick", onClick)
  button:Show()
  return button
end

local shopButton = addMenuButton("SoloRealmShopGoldButton", "Loja de Ouro", gameMenu, -37, openShop)
local teleportButton = addMenuButton("SoloRealmTeleportButton", "Teletransportes", shopButton, -4, openTeleport)
local talentButton = addMenuButton("SoloRealmResetTalentsButton", "Resetar Talentos", teleportButton, -4, confirmTalentReset)

if GameMenuButtonOptions then
  GameMenuButtonOptions:ClearAllPoints()
  GameMenuButtonOptions:SetPoint("TOP", talentButton, "BOTTOM", 0, -4)
end

gameMenu:SetHeight(originalHeight + 3 * (buttonHeight + 4))
