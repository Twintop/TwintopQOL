local addonName, TwintopQOL = ...

local L = TwintopQOL.Localization

local FLAG_TEMPLATE = "|TInterface\\AddOns\\TwintopQOL\\Images\\Flags\\%s.tga:0|t   %s"
local PERCENT_FORMAT = "%3.2f%%"
local ROW_HEIGHT = 18
local CJK_FONT = "Fonts\\ARHei.TTF"
local KOREAN_FONT = "Fonts\\2002.TTF"

-- Translation progress by locale. Each "translator needed" note is in that locale's own language, so it is never localized.
local LOCALES = {
    { locale = "deDE", percent = 0, translators = "Übersetzer benötigt!" },
    { locale = "enGB", percent = 100, translators = "Twintop" },
    { locale = "enUS", percent = 100, translators = "Twintop" },
    { locale = "esES", percent = 0, translators = "Se necesita traductor!" },
    { locale = "esMX", percent = 0, translators = "Se necesita traductor!" },
    { locale = "frFR", percent = 0, translators = "Traducteur recherché!" },
    { locale = "itIT", percent = 0, translators = "Traduttore necessario!" },
    { locale = "koKR", percent = 0, translators = "번역기가 필요합니다!", font = KOREAN_FONT },
    { locale = "ptBR", percent = 0, translators = "Precisa-se de tradutor!" },
    { locale = "ptPT", percent = 0, translators = "Precisa-se de tradutor!" },
    { locale = "ruRU", percent = 0, translators = "Требуется переводчик!" },
    { locale = "zhCN", percent = 0, translators = "需要翻译！", font = CJK_FONT },
    { locale = "zhTW", percent = 0, translators = "需要翻譯！", font = CJK_FONT }
}

---Builds a gold label with a white value under it.
---@param parent Frame
---@param label string
---@param value string
---@param yCoord number
local function BuildInfoEntry(parent, label, value, yCoord)
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 10, yCoord)
    labelText:SetText(label)

    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPLEFT", 20, yCoord - 18)
    valueText:SetText(value)
end

---Fills the About page of the main window.
---@param panel Frame
local function BuildPage(panel)
    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText(L["TwintopQOL"])

    local author = C_AddOns.GetAddOnMetadata(addonName, "Author")
    local authorServer = C_AddOns.GetAddOnMetadata(addonName, "X-AuthorServer")
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version") .. "-" .. C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseType")

    local yCoord = -40
    BuildInfoEntry(panel, L["AboutAuthor"], string.format(L["AboutAuthorServer"], author, authorServer), yCoord)
    yCoord = yCoord - 40
    BuildInfoEntry(panel, L["AboutVersion"], version, yCoord)
    yCoord = yCoord - 40
    BuildInfoEntry(panel, L["AboutReleased"], C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseDate"), yCoord)

    yCoord = yCoord - 40
    local localizationText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    localizationText:SetPoint("TOPLEFT", 10, yCoord)
    localizationText:SetText(L["AboutLocalization"])

    yCoord = yCoord - 18
    for _, entry in ipairs(LOCALES) do
        local localeText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        localeText:SetPoint("TOPLEFT", 20, yCoord)
        localeText:SetText(string.format(FLAG_TEMPLATE, entry.locale, entry.locale))

        local percentText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        percentText:SetPoint("TOPRIGHT", panel, "TOPLEFT", 190, yCoord)
        percentText:SetJustifyH("RIGHT")
        percentText:SetText(string.format(PERCENT_FORMAT, entry.percent))

        local translatorsText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        translatorsText:SetPoint("TOPLEFT", 220, yCoord)
        if entry.font then
            translatorsText:SetFont(entry.font, 12, "")
        end
        translatorsText:SetText(entry.translators)

        yCoord = yCoord - ROW_HEIGHT
    end
end

TwintopQOL.Window:RegisterBottomPage("about", L["AboutPageTitle"], BuildPage)
