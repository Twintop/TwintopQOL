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
local NAV_INDENT = 20
local CONTENT_PADDING = 10
local FOOTER_BUTTON_WIDTH = 120
local ICON_PATH = "Interface\\AddOns\\TwintopQOL\\Images\\"
local BLURPLE = { 0.345, 0.396, 0.949 }

local frame
local navFrame
local contentArea
-- Nav entries by key: pages have a builder, headers have children.
local pages = {}
local pageOrder = {}
-- Pages listed after every other nav entry.
local bottomOrder = {}
local selectedKey

---Makes a frame act as a drag handle for the main window.
---@param handleFrame Frame
local function ConfigureDragHandle(handleFrame)
    handleFrame:EnableMouse(true)
    handleFrame:RegisterForDrag("LeftButton")
    handleFrame:SetScript("OnDragStart", function() frame:StartMoving() end)
    handleFrame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
end

---Creates a nav button with hover and selected textures, plus an expand arrow for headers.
---@param label string
---@param isHeader boolean
---@param isMinor boolean Subsections and bottom pages use a smaller white font.
---@return Button
local function CreateNavButton(label, isHeader, isMinor)
    local btn = CreateFrame("Button", nil, navFrame)
    btn:SetHeight(NAV_BUTTON_HEIGHT)

    if isHeader then
        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(12, 12)
        arrow:SetPoint("RIGHT", -2, 0)
        arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        btn.arrow = arrow
    end

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    local selected = btn:CreateTexture(nil, "BACKGROUND")
    selected:SetAllPoints()
    selected:SetColorTexture(0.3, 0.5, 0.8, 0.3)
    selected:Hide()
    btn.selectedTexture = selected

    local text = btn:CreateFontString(nil, "OVERLAY", isMinor and "GameFontHighlightSmall" or "GameFontNormal")
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", 6, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetText(label)

    return btn
end

---Lays out the nav buttons, skipping the children of collapsed headers.
local function RefreshNav()
    local yOffset = -4
    local navKeys = {}
    for _, key in ipairs(pageOrder) do
        navKeys[#navKeys + 1] = key
    end
    for _, key in ipairs(bottomOrder) do
        navKeys[#navKeys + 1] = key
    end

    for _, key in ipairs(navKeys) do
        local entry = pages[key]
        entry.button:SetPoint("TOPLEFT", 4, yOffset)
        entry.button:SetPoint("RIGHT", -4, 0)
        yOffset = yOffset - NAV_BUTTON_HEIGHT - NAV_BUTTON_PAD

        if entry.children then
            -- Right-pointing when collapsed, down-pointing when expanded.
            entry.button.arrow:SetRotation(entry.collapsed and 0 or (-math.pi / 2))
            for _, childKey in ipairs(entry.children) do
                local child = pages[childKey]
                child.button:SetShown(not entry.collapsed)
                if not entry.collapsed then
                    child.button:SetPoint("TOPLEFT", 4 + NAV_INDENT, yOffset)
                    child.button:SetPoint("RIGHT", -4, 0)
                    yOffset = yOffset - NAV_BUTTON_HEIGHT - NAV_BUTTON_PAD
                end
            end
        end
    end
end

---Creates a footer button with an icon, a 1px border, and a hover tint.
---@param parent Frame
---@param label string
---@param iconPath string
---@param background number Gray level of the button background.
---@param border number[]|nil RGB border and hover tint; gray when nil.
---@param onClick function
---@return Button
local function CreateFooterButton(parent, label, iconPath, background, border, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(FOOTER_BUTTON_WIDTH, 20)
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    btn:SetBackdropColor(background, background, background, 1)
    btn:RegisterForClicks("AnyUp")

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    if border then
        btn:SetBackdropBorderColor(border[1], border[2], border[3], 1)
        highlight:SetColorTexture(border[1], border[2], border[3], 0.15)
    else
        btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        highlight:SetColorTexture(1, 1, 1, 0.1)
    end

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture(iconPath)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", 8, 0)
    text:SetText(label)

    btn:SetScript("OnClick", onClick)
    return btn
end

---Shows a page, building its panel on first use.
---@param key string
local function SelectPage(key)
    local page = pages[key]
    if not page or not page.builder then return end

    if page.parentKey then
        pages[page.parentKey].collapsed = false
        RefreshNav()
    end

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
    -- One strata below the News window and popups, so they always open on top of it.
    frame:SetFrameStrata("HIGH")
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

    -- Right to left, matching TwintopInsanityBar's footer.
    local discordBtn = CreateFooterButton(footer, L["FooterDiscord"], ICON_PATH .. "discord64.png", 0, BLURPLE, function()
        TwintopQOL:ShowUrl(L["FooterDiscord"], L["FooterDiscordUrl"])
    end)
    discordBtn:SetPoint("RIGHT", -4, 0)

    local kofiBtn = CreateFooterButton(footer, L["FooterKofi"], ICON_PATH .. "kofi.png", 0, nil, function()
        TwintopQOL:ShowUrl(L["FooterKofi"], L["FooterKofiUrl"])
    end)
    kofiBtn:SetPoint("RIGHT", discordBtn, "LEFT", -6, 0)

    local githubBtn = CreateFooterButton(footer, L["FooterGitHubIssues"], ICON_PATH .. "GitHub_Invertocat_White64.png", 0, nil, function()
        TwintopQOL:ShowUrl(L["FooterGitHubIssues"], L["GitHubIssuesUrl"])
    end)
    githubBtn:SetPoint("RIGHT", kofiBtn, "LEFT", -6, 0)

    local newsBtn = CreateFooterButton(footer, L["FooterNews"], ICON_PATH .. "newspaper.png", 0.1, nil, function()
        TwintopQOL.News:Show()
    end)
    newsBtn:SetPoint("RIGHT", githubBtn, "LEFT", -6, 0)

    contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", navFrame, "TOPRIGHT", 1, 0)
    contentArea:SetPoint("BOTTOMRIGHT", -4, 4 + FOOTER_HEIGHT + 1)

    for key, entry in pairs(pages) do
        entry.button = CreateNavButton(entry.label, entry.children ~= nil, entry.parentKey ~= nil or entry.isBottom == true)
        if entry.children then
            entry.button:SetScript("OnClick", function()
                entry.collapsed = not entry.collapsed
                RefreshNav()
            end)
        else
            entry.button:SetScript("OnClick", function() SelectPage(key) end)
        end
    end
    RefreshNav()
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

---Adds a collapsible header to the nav list. Its pages register with it as their parent.
---@param key string
---@param label string
function TwintopQOL.Window:RegisterHeader(key, label)
    pages[key] = { key = key, label = label, children = {}, collapsed = false }
    pageOrder[#pageOrder + 1] = key
end

---Adds a page to the nav list. Pages must be registered before the window is first shown.
---@param key string
---@param label string
---@param builder fun(panel: Frame) Fills the page's panel; called the first time the page is shown.
---@param parentKey string|nil A header registered with RegisterHeader.
function TwintopQOL.Window:RegisterPage(key, label, builder, parentKey)
    pages[key] = { key = key, label = label, builder = builder, parentKey = parentKey }
    if parentKey then
        table.insert(pages[parentKey].children, key)
    else
        pageOrder[#pageOrder + 1] = key
    end
end

---Adds a page that always sits at the bottom of the nav list.
---@param key string
---@param label string
---@param builder fun(panel: Frame) Fills the page's panel; called the first time the page is shown.
function TwintopQOL.Window:RegisterBottomPage(key, label, builder)
    pages[key] = { key = key, label = label, builder = builder, isBottom = true }
    bottomOrder[#bottomOrder + 1] = key
end

---A ChatConfigCheckButtonTemplate checkbox, which shows its tooltip field on hover.
---@class TwintopQOL.CheckButton : CheckButton
---@field tooltip string

---Creates a labeled checkbox for a settings page.
---@param parent Frame
---@param name string
---@param label string
---@param x number
---@param y number
---@return TwintopQOL.CheckButton
function TwintopQOL.Window:CreateCheckButton(parent, name, label, x, y)
    local checkbox = CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate") --[[@as TwintopQOL.CheckButton]]
    checkbox:SetPoint("TOPLEFT", x, y)
    _G[checkbox:GetName() .. "Text"]:SetText(label)
    return checkbox
end

---Colors a checkbox label green (enabled) or red (disabled) and sets it to match.
---@param checkbox CheckButton
---@param enable boolean
function TwintopQOL.Window:SetCheckboxOnOff(checkbox, enable)
    local text = _G[checkbox:GetName() .. "Text"]
    if enable then
        text:SetTextColor(0, 1, 0)
        text:SetText(L["Enabled"])
    else
        text:SetTextColor(1, 0, 0)
        text:SetText(L["Disabled"])
    end
end

---A slider from CreateSlider, with its title and the box that shows and takes its value.
---@class TwintopQOL.Slider : Slider, BackdropTemplate
---@field Title FontString
---@field EditBox EditBox

---Creates a horizontal slider with a title above it, its range at its ends, and a box below it to type a value into.
---Its top left goes where the slider is placed; the title sits above that.
---@param parent Frame
---@param name string
---@param title string
---@param minValue number
---@param maxValue number
---@param step number
---@param width number
---@param onChanged fun(value: number) Called with every new value, from dragging, the mouse wheel, or typing.
---@return TwintopQOL.Slider
function TwintopQOL.Window:CreateSlider(parent, name, title, minValue, maxValue, step, width, onChanged)
    local slider = CreateFrame("Slider", name, parent, "BackdropTemplate") --[[@as TwintopQOL.Slider]]
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(width, 17)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    slider.Title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.Title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2)
    slider.Title:SetText(title)

    local minText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    minText:SetText(tostring(minValue))
    local maxText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    maxText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    maxText:SetText(tostring(maxValue))

    local editBox = CreateFrame("EditBox", nil, slider, "BackdropTemplate")
    slider.EditBox = editBox
    editBox:SetSize(50, 16)
    editBox:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetJustifyH("CENTER")
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    editBox:SetBackdropColor(0, 0, 0, 1)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    -- Setting a slider to the value it has doesn't fire OnValueChanged, so the box starts out showing it.
    editBox:SetText(tostring(slider:GetValue()))
    editBox:SetScript("OnEnterPressed", function()
        local value = tonumber(editBox:GetText())
        if value then
            value = math.floor(value / step + 0.5) * step
            slider:SetValue(math.min(math.max(value, minValue), maxValue))
        end
        -- A typed value the slider already had doesn't change it, so the box is set back here.
        editBox:SetText(tostring(slider:GetValue()))
        editBox:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function()
        editBox:SetText(tostring(slider:GetValue()))
        editBox:ClearFocus()
    end)

    slider:SetScript("OnValueChanged", function(_, value)
        editBox:SetText(tostring(value))
        onChanged(value)
    end)
    slider:SetScript("OnMouseWheel", function(_, delta)
        slider:SetValue(math.min(math.max(slider:GetValue() + delta * step, minValue), maxValue))
    end)
    return slider
end

---A color swatch from CreateColorSwatch.
---@class TwintopQOL.ColorSwatch : Button, BackdropTemplate
---@field Color Texture
---@field Refresh fun(self: TwintopQOL.ColorSwatch) Shows the color it was made to show, as it is now.

---Creates a color swatch with a label to its right. Clicking it opens the color picker, which changes the color as it
---moves and puts it back on Cancel.
---@param parent Frame
---@param name string
---@param label string
---@param getColor fun(): number, number, number
---@param setColor fun(r: number, g: number, b: number)
---@return TwintopQOL.ColorSwatch
function TwintopQOL.Window:CreateColorSwatch(parent, name, label, getColor, setColor)
    local swatch = CreateFrame("Button", name, parent, "BackdropTemplate") --[[@as TwintopQOL.ColorSwatch]]
    swatch:SetSize(20, 20)
    swatch:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    swatch:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    swatch.Color = swatch:CreateTexture(nil, "ARTWORK")
    swatch.Color:SetPoint("TOPLEFT", 1, -1)
    swatch.Color:SetPoint("BOTTOMRIGHT", -1, 1)

    local text = swatch:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    text:SetText(label)

    function swatch:Refresh()
        self.Color:SetColorTexture(getColor())
    end

    swatch:SetScript("OnClick", function()
        local r, g, b = getColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r,
            g = g,
            b = b,
            hasOpacity = false,
            swatchFunc = function()
                setColor(ColorPickerFrame:GetColorRGB())
                swatch:Refresh()
            end,
            cancelFunc = function(previous)
                setColor(previous.r, previous.g, previous.b)
                swatch:Refresh()
            end
        })
    end)
    swatch:Refresh()
    return swatch
end

-- How a media dropdown's rows show their media, by media type. Each runs after the menu sets up the row, with the row
-- and the media's file, and returns the row's size when the menu can't measure it.
local mediaRows = {
    -- TwintopInsanityBar's texture rows: the texture runs from the name's left to the row's right edge.
    statusbar = function(button, path)
        local rightEdge = button:AttachTexture()
        rightEdge:SetSize(1, 18)
        rightEdge:SetPoint("RIGHT")
        local fontString = button.fontString

        local texture = button:AttachTexture()
        texture:SetTexture(path)
        texture:SetDrawLayer("BACKGROUND")
        texture:SetPoint("LEFT", fontString, "LEFT")
        texture:SetPoint("RIGHT", rightEdge, "LEFT")
        texture:SetSize(fontString:GetUnboundedStringWidth(), 16)
        fontString:SetDrawLayer("OVERLAY")

        -- The row's size, which the menu can't work out with the texture attached.
        return fontString:GetUnboundedStringWidth() + rightEdge:GetWidth(), 20
    end,
    -- The name in its own font, at the menu's size. The menu sets its text back to its own font when it reuses it.
    font = function(button, path)
        local fontString = button.fontString
        local _, size, flags = fontString:GetFont()
        fontString:SetFont(path, size, flags)
        -- The menu measures the row by its text, fitted to the menu's font before this.
        fontString:SetTextToFit(fontString:GetText())
    end
}

---Creates a dropdown of LibSharedMedia's status bar textures, each drawn behind its name, or its fonts, each name
---written in its font. The list is read each time it opens, so media other addons register later show up.
---@param parent Frame
---@param name string
---@param mediaType "statusbar"|"font"
---@param width number
---@param getName fun(): string The media name to check.
---@param setName fun(name: string)
---@return DropdownButton
function TwintopQOL.Window:CreateMediaDropdown(parent, name, mediaType, width, getName, setName)
    local sharedMedia = LibStub("LibSharedMedia-3.0")
    local showMedia = mediaRows[mediaType]
    local dropdown = CreateFrame("DropdownButton", name, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(width)

    local function IsSelected(mediaName)
        return mediaName == getName()
    end

    dropdown:SetupMenu(function(_, rootDescription)
        local paths = sharedMedia:HashTable(mediaType)
        for _, mediaName in ipairs(sharedMedia:List(mediaType)) do
            local radio = rootDescription:CreateRadio(mediaName, IsSelected, setName, mediaName)
            radio:AddInitializer(function(button)
                return showMedia(button, paths[mediaName])
            end)
        end
        rootDescription:SetScrollMode(400)
    end)
    -- Shown while the checked name isn't one LibSharedMedia has, such as one from an addon that isn't loaded.
    dropdown:SetDefaultText(string.format(L["MediaNotLoaded"], getName()))
    return dropdown
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
    local firstKey = pageOrder[1]
    if pages[firstKey].children then
        firstKey = pages[firstKey].children[1]
    end
    SelectPage(key or selectedKey or firstKey)
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

-- Stub panel in Blizzard's Options > AddOns list that points at the real window.
local blizzardStub = CreateFrame("Frame", "TwintopQOLPanel_BlizzardStub")
local stubTitle = blizzardStub:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
stubTitle:SetPoint("TOPLEFT", 16, -16)
stubTitle:SetText(L["TwintopQOL"])
local stubDesc = blizzardStub:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
stubDesc:SetPoint("TOPLEFT", stubTitle, "BOTTOMLEFT", 0, -8)
stubDesc:SetText(L["OpenOptionsDescription"])
local stubButton = CreateFrame("Button", nil, blizzardStub, "UIPanelButtonTemplate")
stubButton:SetSize(260, 30)
stubButton:SetPoint("TOPLEFT", stubDesc, "BOTTOMLEFT", 0, -12)
stubButton:SetText(L["OpenOptions"])
stubButton:SetScript("OnClick", function()
    TwintopQOL.Window:Show()
end)
local addonCategory = Settings.RegisterCanvasLayoutCategory(blizzardStub, L["TwintopQOL"])
Settings.RegisterAddOnCategory(addonCategory)
