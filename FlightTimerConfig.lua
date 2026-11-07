local _, TwintopQOL = ...

local L = TwintopQOL.Localization

local RESET_POPUP = "TWINTOPQOL_FLIGHT_TIMES_RESET"
local BUTTON_WIDTH = 160
-- The x offset of the Timer Bar section's second column.
local COLUMN_X = 280
local CONTROL_WIDTH = 200
local WIDTH_RANGE = { 100, 600 }
local HEIGHT_RANGE = { 10, 60 }
local FONT_SIZE_RANGE = { 6, 40 }

---Fills the Flight Timer page of the main window.
---@param panel Frame
local function BuildPage(panel)
    local config = TwintopQOLSaved.flightTimer
    local flightTimer = TwintopQOL.FlightTimer

    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText(L["FlightTimerPageTitle"])

    local showBarCheckbox = TwintopQOL.Window:CreateCheckButton(panel, "TwintopQOLFlightTimerShowBar", L["FlightTimerShowBar"], 0, -30)
    showBarCheckbox.tooltip = L["FlightTimerShowBarTooltip"]
    showBarCheckbox:SetScript("OnClick", function(self)
        flightTimer:SetShowBar(self:GetChecked())
    end)

    local showTooltipsCheckbox = TwintopQOL.Window:CreateCheckButton(panel, "TwintopQOLFlightTimerShowTooltips", L["FlightTimerShowTooltips"], 0, -50)
    showTooltipsCheckbox.tooltip = L["FlightTimerShowTooltipsTooltip"]
    showTooltipsCheckbox:SetScript("OnClick", function(self)
        flightTimer:SetShowTooltips(self:GetChecked())
    end)

    local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", 0, -84)
    description:SetPoint("TOPRIGHT", 0, -84)
    description:SetJustifyH("LEFT")
    description:SetText(L["FlightTimerDescription"])

    -- The text the route count goes under.
    local lastText = description
    -- Only WoW Forever has the Frequent Flier legacy perk.
    if TwintopQOL.IsForever then
        local frequentFlier = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frequentFlier:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12)
        frequentFlier:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT", 0, -12)
        frequentFlier:SetJustifyH("LEFT")
        frequentFlier:SetText(L["FlightTimerFrequentFlierDescription"])
        lastText = frequentFlier
    end

    local routeCount = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    routeCount:SetPoint("TOPLEFT", lastText, "BOTTOMLEFT", 0, -16)

    local function RefreshRouteCount()
        routeCount:SetText(string.format(L["FlightTimerRouteCount"], flightTimer:GetRouteCount()))
    end

    local resetTimesBtn = CreateFrame("Button", "TwintopQOLFlightTimerResetTimes", panel, "UIPanelButtonTemplate")
    resetTimesBtn:SetSize(BUTTON_WIDTH, 22)
    resetTimesBtn:SetPoint("TOPLEFT", routeCount, "BOTTOMLEFT", 0, -10)
    resetTimesBtn:SetText(L["FlightTimerResetTimes"])
    resetTimesBtn:SetScript("OnClick", function() StaticPopup_Show(RESET_POPUP) end)

    StaticPopupDialogs[RESET_POPUP] = {
        text = L["FlightTimerResetConfirm"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            flightTimer:ResetTimes()
            RefreshRouteCount()
            TwintopQOL:Print(L["FlightTimerResetDone"])
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    -- The Timer Bar section: its lock, size, texture, colors, and font.
    local barHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    barHeader:SetPoint("TOPLEFT", resetTimesBtn, "BOTTOMLEFT", 0, -24)
    barHeader:SetText(L["FlightTimerBarHeader"])

    local barDescription = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barDescription:SetPoint("TOPLEFT", barHeader, "BOTTOMLEFT", 0, -6)
    barDescription:SetText(L["FlightTimerBarDescription"])

    local lockCheckbox = TwintopQOL.Window:CreateCheckButton(panel, "TwintopQOLFlightTimerLock", L["FlightTimerLock"], 0, 0)
    lockCheckbox:ClearAllPoints()
    lockCheckbox:SetPoint("TOPLEFT", barDescription, "BOTTOMLEFT", 0, -8)
    lockCheckbox.tooltip = L["FlightTimerLockTooltip"]
    lockCheckbox:SetScript("OnClick", function(self)
        config.locked = self:GetChecked()
        flightTimer:ApplyAppearance()
    end)

    local resetPositionBtn = CreateFrame("Button", "TwintopQOLFlightTimerResetPosition", panel, "UIPanelButtonTemplate")
    resetPositionBtn:SetSize(BUTTON_WIDTH, 22)
    resetPositionBtn:SetPoint("LEFT", lockCheckbox, "LEFT", COLUMN_X, 0)
    resetPositionBtn:SetText(L["FlightTimerResetPosition"])
    resetPositionBtn:SetScript("OnClick", function() flightTimer:ResetPosition() end)

    local widthSlider = TwintopQOL.Window:CreateSlider(panel, "TwintopQOLFlightTimerWidth", L["FlightTimerWidth"],
        WIDTH_RANGE[1], WIDTH_RANGE[2], 1, CONTROL_WIDTH, function(value)
            config.width = value
            flightTimer:ApplyAppearance()
        end)
    widthSlider:SetPoint("TOPLEFT", lockCheckbox, "BOTTOMLEFT", 4, -30)

    local heightSlider = TwintopQOL.Window:CreateSlider(panel, "TwintopQOLFlightTimerHeight", L["FlightTimerHeight"],
        HEIGHT_RANGE[1], HEIGHT_RANGE[2], 1, CONTROL_WIDTH, function(value)
            config.height = value
            flightTimer:ApplyAppearance()
        end)
    heightSlider:SetPoint("LEFT", widthSlider, "LEFT", COLUMN_X, 0)

    local textureLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textureLabel:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", -4, -34)
    textureLabel:SetText(L["FlightTimerTexture"])

    local textureDropdown = TwintopQOL.Window:CreateMediaDropdown(panel, "TwintopQOLFlightTimerTexture", "statusbar",
        CONTROL_WIDTH,
        function() return config.texture end,
        function(name)
            config.texture = name
            flightTimer:ApplyAppearance()
        end)
    textureDropdown:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", 0, -6)

    local fontLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", textureDropdown, "BOTTOMLEFT", 0, -16)
    fontLabel:SetText(L["FlightTimerFont"])

    local fontDropdown = TwintopQOL.Window:CreateMediaDropdown(panel, "TwintopQOLFlightTimerFont", "font", CONTROL_WIDTH,
        function() return config.fontFace end,
        function(name)
            config.fontFace = name
            flightTimer:ApplyAppearance()
        end)
    fontDropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -6)

    local fontSizeSlider = TwintopQOL.Window:CreateSlider(panel, "TwintopQOLFlightTimerFontSize", L["FlightTimerFontSize"],
        FONT_SIZE_RANGE[1], FONT_SIZE_RANGE[2], 1, CONTROL_WIDTH, function(value)
            config.fontSize = value
            flightTimer:ApplyAppearance()
        end)
    -- In the second column, its title level with the font's label.
    fontSizeSlider:SetPoint("TOPLEFT", fontLabel, "TOPLEFT", COLUMN_X + 4, -16)

    ---A swatch for one of the bar's colors, which redraws the bar as it changes.
    ---@param name string
    ---@param label string
    ---@param key "color"|"timingColor"
    ---@return TwintopQOL.ColorSwatch
    local function CreateBarColorSwatch(name, label, key)
        return TwintopQOL.Window:CreateColorSwatch(panel, name, label,
            function()
                local color = config[key]
                return color.r, color.g, color.b
            end,
            function(r, g, b)
                config[key] = { r = r, g = g, b = b }
                flightTimer:ApplyAppearance()
            end)
    end

    local colorSwatch = CreateBarColorSwatch("TwintopQOLFlightTimerColor", L["FlightTimerColor"], "color")
    colorSwatch:SetPoint("TOPLEFT", textureLabel, "TOPLEFT", COLUMN_X, 0)
    local timingColorSwatch = CreateBarColorSwatch("TwintopQOLFlightTimerTimingColor", L["FlightTimerTimingColor"], "timingColor")
    timingColorSwatch:SetPoint("TOPLEFT", colorSwatch, "BOTTOMLEFT", 0, -8)

    panel:SetScript("OnShow", function()
        showBarCheckbox:SetChecked(config.showBar)
        showTooltipsCheckbox:SetChecked(config.showTooltips)
        RefreshRouteCount()
        lockCheckbox:SetChecked(config.locked)
        widthSlider:SetValue(config.width)
        heightSlider:SetValue(config.height)
        textureDropdown:GenerateMenu()
        colorSwatch:Refresh()
        timingColorSwatch:Refresh()
        fontDropdown:GenerateMenu()
        fontSizeSlider:SetValue(config.fontSize)
        -- The bar shows a preview while the page is open, so changes show as they're made.
        flightTimer:SetPreview(true)
    end)
    panel:SetScript("OnHide", function()
        flightTimer:SetPreview(false)
    end)
end

TwintopQOL.Window:RegisterPage("generalFlightTimer", L["FlightTimerPageTitle"], BuildPage, "general")
