local addonName, TwintopQOL = ...
TwintopQOL.News = TwintopQOL.News or {}

local LSHM = LibStub("LibSimpleHTMLMarkdown-1.0")

local ADDON_VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version") .. "-" .. C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseType")
local ISSUE_URL = "https://github.com/Twintop/TwintopQOL/issues/"
local URL_POPUP = "TWINTOPQOL_NEWS_URL"

local frame

---Opens a link from the reader: GitHub issue numbers and plain URLs.
---@param link string
---@param text string
local function OnHyperlinkClick(_, link, text)
    if link == "window:close" then
        TwintopQOL.News:Hide()
    elseif link:match("https?://") then
        StaticPopup_Show(URL_POPUP, nil, nil, { title = text, url = link })
    elseif link:match("^#%d+$") then
        local url = ISSUE_URL .. link:sub(2)
        StaticPopup_Show(URL_POPUP, nil, nil, { title = "issue " .. link .. " on GitHub", url = url })
    end
end

---Builds the reader: the markdown rendered as HTML inside a scroll frame.
---@param parent Frame
local function BuildReader(parent)
    local scrollFrame = CreateFrame("ScrollFrame", "TwintopQOLNewsScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -34)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -32, 38)

    local simpleHtml = CreateFrame("SimpleHTML", "TwintopQOLNewsHTMLFrame", scrollFrame)
    simpleHtml:SetWidth(700)
    simpleHtml:SetHeight(1)

    simpleHtml:SetFontObject("h1", "SystemFont_Huge1")
    simpleHtml:SetTextColor("h1", 1.0, 0.82, 0.0, 1)

    simpleHtml:SetFontObject("h2", "SystemFont_Large")
    simpleHtml:SetTextColor("h2", 0.45, 0.75, 1.0, 1)

    simpleHtml:SetFontObject("h3", "SystemFont_Med3")
    simpleHtml:SetTextColor("h3", 0.9, 0.9, 0.9, 1)

    simpleHtml:SetFontObject("p", "GameFontHighlight")
    simpleHtml:SetTextColor("p", 0.78, 0.78, 0.78, 1)

    simpleHtml:SetHyperlinkFormat("[|cff4da6ff|H%s|h%s|h|r]")
    simpleHtml:SetScript("OnHyperlinkClick", OnHyperlinkClick)
    simpleHtml:SetScript("OnHyperlinkEnter", function() SetCursor("Interface\\CURSOR\\vehichleCursor.PNG") end)
    simpleHtml:SetScript("OnHyperlinkLeave", function() SetCursor(nil) end)

    simpleHtml:SetText(LSHM:ToHTML(TwintopQOL.NewsContent or ""))
    simpleHtml:SetHeight(simpleHtml:GetContentHeight() + 10)
    scrollFrame:SetScrollChild(simpleHtml)
end

local function CreateMainFrame()
    if frame then return end

    frame = CreateFrame("Frame", "TwintopQOLNewsWindow", UIParent, "BackdropTemplate")
    frame:SetSize(750, 505)
    -- Anchor before clamping. A clamped frame with no points takes the screen rect as its anchor
    -- origin, and anchoring it to UIParent afterwards fails the anchor family check.
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    tinsert(UISpecialFrames, "TwintopQOLNewsWindow") -- ESC to close

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 14, -10)
    titleText:SetText("Twintop QOL Updates")

    local closeX = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", -2, -2)
    closeX:SetScript("OnClick", function() TwintopQOL.News:Hide() end)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() TwintopQOL.News:Hide() end)

    local showAgain = CreateFrame("CheckButton", "TwintopQOLNewsShowAgain", frame, "ChatConfigCheckButtonTemplate")
    showAgain:SetPoint("BOTTOMLEFT", 8, 6)
    _G[showAgain:GetName() .. "Text"]:SetText("Show on new version release")
    showAgain.tooltip = "Show this update popup whenever a new version of Twintop QOL is released."
    showAgain:SetChecked(TwintopQOLSaved.news.enabled)
    showAgain:SetScript("OnClick", function(self)
        TwintopQOLSaved.news.enabled = self:GetChecked()
    end)

    -- Override LibSimpleHTMLMarkdown inline color escapes for a cleaner palette
    LSHM.config["strong"]  = "|cffffcc00"
    LSHM.config["/strong"] = "|r"
    LSHM.config["em"]      = "|cffff9966"
    LSHM.config["/em"]     = "|r"
    LSHM.config["code"]    = "|cffaaaadd"
    LSHM.config["/code"]   = "|r"
    LSHM.config["pre"]     = "<p>|cffaaaadd"
    LSHM.config["/pre"]    = "|r</p><br />"

    BuildReader(frame)

    -- ... and this is the popup the URL links open.
    StaticPopupDialogs[URL_POPUP] = {
        OnShow = function(self, data)
            self:SetWidth(450)
            self:SetFormattedText("Here's a link to %s", data.title)
            self:GetEditBox():SetText(data.url)
            self:GetEditBox():SetAutoFocus(true)
            self:GetEditBox():HighlightText()
        end,
        OnAccept = function(self)
            self:Hide()
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        text = "",
        button1 = OKAY,
        hasEditBox = true,
        hasWideEditBox = true,
        editBoxWidth = 400,
        timeout = 60,
        whileDead = true,
        closeButton = true,
        hideOnEscape = true
    }
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function TwintopQOL.News:Hide()
    if frame then
        frame:Hide()
    end
end

---Opens the window, marking the running version as seen.
function TwintopQOL.News:Show()
    CreateMainFrame()
    TwintopQOLSaved.news.lastUpdate = ADDON_VERSION
    frame:Show()
    frame:Raise()
end

---Toggles the news window.
function TwintopQOL.News:Toggle()
    if frame and frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

---Shows the window on login when a version the player hasn't seen is running.
function TwintopQOL.News:Init()
    if TwintopQOLSaved.news.enabled and TwintopQOLSaved.news.lastUpdate ~= ADDON_VERSION then
        self:Show()
    end
end
