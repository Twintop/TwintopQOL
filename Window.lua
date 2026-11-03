local addonName, TwintopQOL = ...
TwintopQOL.Window = TwintopQOL.Window or {}

local L = TwintopQOL.Localization

local ADDON_VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version") .. "-" .. C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseType")

local FRAME_WIDTH = 1000
local FRAME_HEIGHT = 620
local TITLE_HEIGHT = 30
local FOOTER_HEIGHT = 24
local NAV_WIDTH = 160
local NAV_BUTTON_HEIGHT = 22
local NAV_BUTTON_PAD = 2
local CONTENT_PADDING = 10

local frame
local navFrame
local contentArea
local pages = {}
local pageOrder = {}
local selectedKey

---Makes a frame act as a drag handle for the main window.
---@param handleFrame Frame
local function ConfigureDragHandle(handleFrame)
    handleFrame:EnableMouse(true)
    handleFrame:RegisterForDrag("LeftButton")
    handleFrame:SetScript("OnDragStart", function() frame:StartMoving() end)
    handleFrame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
end

---Creates a nav button with hover and selected textures.
---@param label string
---@return Button
local function CreateNavButton(label)
    local btn = CreateFrame("Button", nil, navFrame)
    btn:SetHeight(NAV_BUTTON_HEIGHT)

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    local selected = btn:CreateTexture(nil, "BACKGROUND")
    selected:SetAllPoints()
    selected:SetColorTexture(0.3, 0.5, 0.8, 0.3)
    selected:Hide()
    btn.selectedTexture = selected

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", 6, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetText(label)

    return btn
end

---Shows a page, building its panel on first use.
---@param key string
local function SelectPage(key)
    local page = pages[key]
    if not page then return end

    if not page.panel then
        page.panel = CreateFrame("Frame", nil, contentArea)
        page.panel:SetPoint("TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
        page.panel:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
        page.panel:Hide()
        page.builder(page.panel)
    end

    for _, other in pairs(pages) do
        if other ~= page and other.panel then
            other.panel:Hide()
        end
        other.button.selectedTexture:SetShown(other == page)
    end

    selectedKey = key
    page.panel:Show()
end

local function CreateMainFrame()
    if frame then return end

    frame = CreateFrame("Frame", "TwintopQOLWindow", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    -- Anchor before clamping; see the note in News.lua.
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnHide", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "TwintopQOLWindow") -- ESC to close

    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(TITLE_HEIGHT)
    titleBar:SetPoint("TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", -4, -4)
    ConfigureDragHandle(titleBar)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", 8, 0)
    titleText:SetText(L["TwintopQOL"])

    local closeX = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeX:SetScript("OnClick", function() frame:Hide() end)

    local titleDivider = frame:CreateTexture(nil, "ARTWORK")
    titleDivider:SetHeight(1)
    titleDivider:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT")
    titleDivider:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT")
    titleDivider:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    navFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    navFrame:SetWidth(NAV_WIDTH)
    navFrame:SetPoint("TOPLEFT", 4, -(TITLE_HEIGHT + 4))
    navFrame:SetPoint("BOTTOMLEFT", 4, 4 + FOOTER_HEIGHT + 1)
    navFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 8,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    navFrame:SetBackdropColor(0, 0, 0, 0.3)
    ConfigureDragHandle(navFrame)

    local navDivider = frame:CreateTexture(nil, "ARTWORK")
    navDivider:SetWidth(1)
    navDivider:SetPoint("TOPLEFT", navFrame, "TOPRIGHT")
    navDivider:SetPoint("BOTTOMLEFT", navFrame, "BOTTOMRIGHT")
    navDivider:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    local footer = CreateFrame("Frame", nil, frame)
    footer:SetHeight(FOOTER_HEIGHT)
    footer:SetPoint("BOTTOMLEFT", 4, 4)
    footer:SetPoint("BOTTOMRIGHT", -4, 4)
    ConfigureDragHandle(footer)

    local footerDivider = frame:CreateTexture(nil, "ARTWORK")
    footerDivider:SetHeight(1)
    footerDivider:SetPoint("BOTTOMLEFT", footer, "TOPLEFT")
    footerDivider:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")
    footerDivider:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    local versionText = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionText:SetPoint("LEFT", 8, 0)
    versionText:SetTextColor(0.6, 0.6, 0.6, 1)
    versionText:SetText(ADDON_VERSION)

    local newsBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    newsBtn:SetSize(100, 20)
    newsBtn:SetPoint("RIGHT", -4, 0)
    newsBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    newsBtn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    newsBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    local newsHighlight = newsBtn:CreateTexture(nil, "HIGHLIGHT")
    newsHighlight:SetAllPoints()
    newsHighlight:SetColorTexture(1, 1, 1, 0.1)
    local newsText = newsBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    newsText:SetPoint("CENTER")
    newsText:SetText(L["FooterNews"])
    newsBtn:SetScript("OnClick", function() TwintopQOL.News:Show() end)

    contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", navFrame, "TOPRIGHT", 1, 0)
    contentArea:SetPoint("BOTTOMRIGHT", -4, 4 + FOOTER_HEIGHT + 1)

    local yOffset = -4
    for _, key in ipairs(pageOrder) do
        local page = pages[key]
        page.button = CreateNavButton(page.label)
        page.button:SetPoint("TOPLEFT", 4, yOffset)
        page.button:SetPoint("RIGHT", -4, 0)
        page.button:SetScript("OnClick", function() SelectPage(key) end)
        yOffset = yOffset - NAV_BUTTON_HEIGHT - NAV_BUTTON_PAD
    end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

---Adds a page to the nav list. Pages must be registered before the window is first shown.
---@param key string
---@param label string
---@param builder fun(panel: Frame) Fills the page's panel; called the first time the page is shown.
function TwintopQOL.Window:RegisterPage(key, label, builder)
    pages[key] = { key = key, label = label, builder = builder }
    pageOrder[#pageOrder + 1] = key
end

---@return Frame
function TwintopQOL.Window:GetFrame()
    CreateMainFrame()
    return frame
end

---Opens the window on the given page, or on the last page shown.
---@param key string|nil
function TwintopQOL.Window:Show(key)
    CreateMainFrame()
    frame:Show()
    frame:Raise()
    SelectPage(key or selectedKey or pageOrder[1])
end

function TwintopQOL.Window:Hide()
    if frame then
        frame:Hide()
    end
end

---Closes the window if it is already open on the given page; otherwise opens it there.
---@param key string|nil
function TwintopQOL.Window:Toggle(key)
    if frame and frame:IsShown() and (key == nil or key == selectedKey) then
        self:Hide()
    else
        self:Show(key)
    end
end
