local _, TwintopQOL = ...

local L = TwintopQOL.Localization

-- Chat messages are capped at 255 characters.
local MAX_RESPONSE_LENGTH = 255

local channelLabels = {
    SAY = L["ChannelSay"],
    YELL = L["ChannelYell"],
    RAID = L["ChannelRaid"],
    RAID_WARNING = L["ChannelRaidWarning"],
    PARTY = L["ChannelParty"],
    EMOTE = L["ChannelEmote"]
}

---Fills the General page of the main window.
---@param panel Frame
local function BuildPage(panel)
    local readyCheck = TwintopQOLSaved.readyCheck

    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText(L["GeneralPageTitle"])

    -- Ready check response
    local yCoord = -30
    local readyCheckHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    readyCheckHeader:SetPoint("TOPLEFT", 0, yCoord)
    readyCheckHeader:SetText(L["ReadyCheckHeader"])

    yCoord = yCoord - 20
    local readyCheckEnabled = TwintopQOL.Window:CreateCheckButton(panel, "TwintopQOLReadyCheckEnabled", L["Enabled"], 0, yCoord)
    readyCheckEnabled.tooltip = L["ReadyCheckEnabledTooltip"]

    local responseLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    responseLabel:SetText(L["ReadyCheckResponseLabel"])
    local channelLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    channelLabel:SetText(L["ReadyCheckChannelLabel"])
    -- Line the controls up past the wider of the two labels.
    local controlX = 20 + math.max(responseLabel:GetStringWidth(), channelLabel:GetStringWidth()) + 12

    yCoord = yCoord - 30
    local responseBox = CreateFrame("EditBox", "TwintopQOLReadyCheckResponse", panel, "InputBoxTemplate")
    responseBox:SetSize(300, 20)
    -- InputBoxTemplate's border reaches 5px left of the box.
    responseBox:SetPoint("TOPLEFT", controlX + 5, yCoord)
    responseLabel:SetPoint("LEFT", panel, "TOPLEFT", 20, yCoord - 10)
    responseBox:SetAutoFocus(false)
    responseBox:SetMaxLetters(MAX_RESPONSE_LENGTH)
    responseBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            readyCheck.response = self:GetText()
        end
    end)
    responseBox:SetScript("OnEnterPressed", responseBox.ClearFocus)
    responseBox:SetScript("OnEscapePressed", responseBox.ClearFocus)

    yCoord = yCoord - 30
    local channelDropdown = CreateFrame("DropdownButton", "TwintopQOLReadyCheckChannel", panel, "WowStyle1DropdownTemplate")
    channelDropdown:SetWidth(150)
    channelDropdown:SetPoint("TOPLEFT", controlX, yCoord)
    channelLabel:SetPoint("LEFT", panel, "TOPLEFT", 20, yCoord - 12)
    channelDropdown:SetupMenu(function(_, rootDescription)
        for _, channel in ipairs(TwintopQOL.ReadyCheck.CHANNELS) do
            rootDescription:CreateRadio(channelLabels[channel], function()
                return readyCheck.channel == channel
            end, function()
                readyCheck.channel = channel
            end)
        end
    end)

    local function RefreshResponseControls()
        responseBox:SetEnabled(readyCheck.enabled)
        channelDropdown:SetEnabled(readyCheck.enabled)
        if readyCheck.enabled then
            responseLabel:SetTextColor(1, 1, 1)
            responseBox:SetTextColor(1, 1, 1)
            channelLabel:SetTextColor(1, 1, 1)
        else
            responseBox:ClearFocus()
            responseLabel:SetTextColor(0.5, 0.5, 0.5)
            responseBox:SetTextColor(0.5, 0.5, 0.5)
            channelLabel:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    readyCheckEnabled:SetScript("OnClick", function(self)
        readyCheck.enabled = self:GetChecked()
        TwintopQOL.Window:SetCheckboxOnOff(self, readyCheck.enabled)
        RefreshResponseControls()
    end)

    panel:SetScript("OnShow", function()
        readyCheckEnabled:SetChecked(readyCheck.enabled)
        TwintopQOL.Window:SetCheckboxOnOff(readyCheckEnabled, readyCheck.enabled)
        responseBox:SetText(readyCheck.response)
        responseBox:SetCursorPosition(0)
        channelDropdown:GenerateMenu()
        RefreshResponseControls()
    end)
end

TwintopQOL.Window:RegisterHeader("general", L["GeneralPageTitle"])
TwintopQOL.Window:RegisterPage("generalGeneral", L["GeneralPageTitle"], BuildPage, "general")
