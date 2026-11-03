local _, TwintopQOL = ...

local L = TwintopQOL.Localization

-- Chat messages are capped at 255 characters.
local MAX_RESPONSE_LENGTH = 255

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

    yCoord = yCoord - 30
    local responseLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    responseLabel:SetPoint("TOPLEFT", 20, yCoord)
    responseLabel:SetText(L["ReadyCheckResponseLabel"])

    local responseBox = CreateFrame("EditBox", "TwintopQOLReadyCheckResponse", panel, "InputBoxTemplate")
    responseBox:SetSize(300, 20)
    responseBox:SetPoint("LEFT", responseLabel, "RIGHT", 12, 0)
    responseBox:SetAutoFocus(false)
    responseBox:SetMaxLetters(MAX_RESPONSE_LENGTH)
    responseBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            readyCheck.response = self:GetText()
        end
    end)
    responseBox:SetScript("OnEnterPressed", responseBox.ClearFocus)
    responseBox:SetScript("OnEscapePressed", responseBox.ClearFocus)

    local function RefreshResponseBox()
        responseBox:SetEnabled(readyCheck.enabled)
        if readyCheck.enabled then
            responseLabel:SetTextColor(1, 1, 1)
            responseBox:SetTextColor(1, 1, 1)
        else
            responseBox:ClearFocus()
            responseLabel:SetTextColor(0.5, 0.5, 0.5)
            responseBox:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    readyCheckEnabled:SetScript("OnClick", function(self)
        readyCheck.enabled = self:GetChecked()
        TwintopQOL.Window:SetCheckboxOnOff(self, readyCheck.enabled)
        RefreshResponseBox()
    end)

    panel:SetScript("OnShow", function()
        readyCheckEnabled:SetChecked(readyCheck.enabled)
        TwintopQOL.Window:SetCheckboxOnOff(readyCheckEnabled, readyCheck.enabled)
        responseBox:SetText(readyCheck.response)
        responseBox:SetCursorPosition(0)
        RefreshResponseBox()
    end)
end

TwintopQOL.Window:RegisterHeader("general", L["GeneralPageTitle"])
TwintopQOL.Window:RegisterPage("generalGeneral", L["GeneralPageTitle"], BuildPage, "general")
