local frame = CreateFrame("Frame", "HeraldWotLKFrame", UIParent)
frame:SetWidth(248)
frame:SetHeight(192)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
frame:Hide()

local function togglePanel()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -18)
title:SetText("Herald WotLK — Autopilot")

local function sendCommand(action)
  if not UnitExists("player") then
    DEFAULT_CHAT_FRAME:AddMessage("Herald: entre no mundo para usar os controles.")
    return
  end

  SendChatMessage(".playerbots bot herald " .. action, "SAY")
end

local buttons = {
  { text = "Iniciar questing", command = "start" },
  { text = "Pausar", command = "pause" },
  { text = "Retomar", command = "resume" },
  { text = "Parar e devolver controle", command = "stop" },
  { text = "Ver estado", command = "status" },
}

for index, item in ipairs(buttons) do
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetWidth(205)
  button:SetHeight(24)
  button:SetPoint("TOP", frame, "TOP", 0, -42 - ((index - 1) * 27))
  button:SetText(item.text)
  button:SetScript("OnClick", function() sendCommand(item.command) end)
end

SLASH_HERALDWOTLK1 = "/herald"
SLASH_HERALDWOTLK2 = "/heraldwotlk"
SlashCmdList.HERALDWOTLK = togglePanel
_G.HeraldWotLKToggle = togglePanel
BINDING_HEADER_HERALDWOTLK = "Herald WotLK"
BINDING_NAME_HERALDWOTLK_TOGGLE = "Abrir controles Herald"

local minimapButton = CreateFrame("Button", "HeraldWotLKMinimapButton", Minimap)
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")

local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
icon:SetTexture("Interface\\Icons\\Ability_Hunter_EagleEye")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetWidth(52)
border:SetHeight(52)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local minimapAngle = math.rad(225)
local minimapRadius = 80
local function placeMinimapButton()
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER",
    math.cos(minimapAngle) * minimapRadius,
    math.sin(minimapAngle) * minimapRadius)
end

local function updateMinimapAngle()
  local scale = Minimap:GetEffectiveScale()
  local cursorX, cursorY = GetCursorPosition()
  cursorX = cursorX / scale - Minimap:GetLeft() - Minimap:GetWidth() / 2
  cursorY = cursorY / scale - Minimap:GetBottom() - Minimap:GetHeight() / 2
  minimapAngle = math.atan2(cursorY, cursorX)
  placeMinimapButton()
end

minimapButton:SetScript("OnDragStart", function(self)
  self.dragging = true
  self:SetScript("OnUpdate", function()
    updateMinimapAngle()
  end)
end)

minimapButton:SetScript("OnDragStop", function(self)
  self.dragging = false
  self.skipClickUntil = GetTime() + 0.2
  self:SetScript("OnUpdate", nil)
end)

minimapButton:SetScript("OnClick", function(self, mouseButton)
  if self.skipClickUntil and GetTime() < self.skipClickUntil then
    return
  end

  if mouseButton == "RightButton" then
    sendCommand("status")
  else
    togglePanel()
  end
end)

minimapButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("Herald WotLK", 1, 0.82, 0)
  GameTooltip:AddLine("Clique para abrir os controles", 1, 1, 1)
  GameTooltip:AddLine("Clique direito para consultar o estado", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

placeMinimapButton()

DEFAULT_CHAT_FRAME:AddMessage("Herald WotLK carregado. Use /herald; atalho em Teclas > Herald WotLK.")
