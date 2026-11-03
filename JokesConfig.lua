local _, TwintopQOL = ...

local L = TwintopQOL.Localization

local contentTypeLabels = {
    openWorld = L["JokesContentOpenWorld"],
    dungeonNormal = L["JokesContentDungeonNormal"],
    dungeonHeroic = L["JokesContentDungeonHeroic"],
    dungeonMythic = L["JokesContentDungeonMythic"],
    mythicPlus = L["JokesContentMythicPlus"],
    delve = L["JokesContentDelve"],
    scenario = L["JokesContentScenario"],
    raidLFR = L["JokesContentRaidLFR"],
    raidNormal = L["JokesContentRaidNormal"],
    raidHeroic = L["JokesContentRaidHeroic"],
    raidMythic = L["JokesContentRaidMythic"],
    battleground = L["JokesContentBattleground"],
    arena = L["JokesContentArena"]
}

---@param parent Frame
---@param name string
---@param label string
---@param x number
---@param y number
---@return CheckButton
local function BuildCheckButton(parent, name, label, x, y)
    local checkbox = CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    _G[checkbox:GetName() .. "Text"]:SetText(label)
    return checkbox
end

---Colors a checkbox label green (enabled) or red (disabled) and sets it to match.
---@param checkbox CheckButton
---@param enable boolean
local function ToggleCheckboxOnOff(checkbox, enable)
    local text = _G[checkbox:GetName() .. "Text"]
    if enable then
        text:SetTextColor(0, 1, 0)
        text:SetText(L["Enabled"])
    else
        text:SetTextColor(1, 0, 0)
        text:SetText(L["Disabled"])
    end
end

---Enables a checkbox, or grays it out with a tooltip saying what turned it off.
---@param checkbox CheckButton
---@param enable boolean
---@param tooltip string
local function ToggleCheckboxEnabled(checkbox, enable, tooltip)
    local text = _G[checkbox:GetName() .. "Text"]
    if enable then
        checkbox:Enable()
        text:SetTextColor(1, 1, 1)
        checkbox.tooltip = tooltip
    else
        checkbox:Disable()
        text:SetTextColor(0.5, 0.5, 0.5)
        checkbox.tooltip = L["JokesContentDisabledTooltip"]
    end
end

---Fills the Jokes Configuration page of the main window.
---@param panel Frame
local function BuildPage(panel)
    local config = TwintopQOLSaved.jokesConfig
    local contentCheckboxes = {}

    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText(L["JokesConfigPageTitle"])

    local yCoord = -30
    local enabledCheckbox = BuildCheckButton(panel, "TwintopQOLJokesEnabled", L["Enabled"], 0, yCoord)
    enabledCheckbox.tooltip = L["JokesEnabledTooltip"]

    local function RefreshContentCheckboxes()
        for contentType, checkbox in pairs(contentCheckboxes) do
            ToggleCheckboxEnabled(checkbox, config.enabled, L["JokesContentTooltip"])
            checkbox:SetChecked(config.content[contentType])
        end
    end

    enabledCheckbox:SetScript("OnClick", function(self)
        config.enabled = self:GetChecked()
        ToggleCheckboxOnOff(self, config.enabled)
        RefreshContentCheckboxes()
    end)

    yCoord = yCoord - 30
    local contentHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentHeader:SetPoint("TOPLEFT", 0, yCoord)
    contentHeader:SetText(L["JokesContentHeader"])

    yCoord = yCoord - 20
    for _, contentType in ipairs(TwintopQOL.Jokes.CONTENT_TYPES) do
        local checkbox = BuildCheckButton(panel, "TwintopQOLJokesContent_" .. contentType, contentTypeLabels[contentType], 20, yCoord)
        checkbox:SetMotionScriptsWhileDisabled(true)
        checkbox:SetScript("OnClick", function(self)
            config.content[contentType] = self:GetChecked()
        end)
        contentCheckboxes[contentType] = checkbox
        yCoord = yCoord - 20
    end

    yCoord = yCoord - 30
    local behaviorHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    behaviorHeader:SetPoint("TOPLEFT", 0, yCoord)
    behaviorHeader:SetText(L["JokesBehaviorHeader"])

    yCoord = yCoord - 20
    local noRepeatsCheckbox = BuildCheckButton(panel, "TwintopQOLJokesNoRepeats", L["JokesNoRepeats"], 0, yCoord)
    noRepeatsCheckbox.tooltip = L["JokesNoRepeatsTooltip"]
    noRepeatsCheckbox:SetScript("OnClick", function(self)
        config.noRepeats = self:GetChecked()
    end)

    panel:SetScript("OnShow", function()
        enabledCheckbox:SetChecked(config.enabled)
        ToggleCheckboxOnOff(enabledCheckbox, config.enabled)
        RefreshContentCheckboxes()
        noRepeatsCheckbox:SetChecked(config.noRepeats)
    end)
end

TwintopQOL.Window:RegisterHeader("jokes", L["JokesPageTitle"])
TwintopQOL.Window:RegisterPage("jokesConfig", L["JokesConfigPageTitle"], BuildPage, "jokes")
