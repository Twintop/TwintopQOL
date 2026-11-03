local _, TwintopQOL = ...

-- Chat messages longer than this can't be sent.
local MAX_CHAT_LENGTH = 255
local RESET_POPUP = "TWINTOPQOL_JOKES_RESET"
local GUTTER_WIDTH = 40
-- Pixels scrolled sideways per shift + mouse wheel notch.
local H_SCROLL_STEP = 40
-- Room kept past the end of the longest line so the cursor there stays visible.
local LINE_END_PADDING = 20

local editBox
local scrollFrame
local gutter
local hSlider
local highlight
local measurer
local statusText
local dirty = false

-- Layout and cursor state. A multi-line EditBox only wraps at its own width, so
-- wrapping is avoided by sizing the box to its longest line. With no wrapping,
-- every text line is one row of the same height, which is what lets the row
-- highlight and line numbers be placed by simple arithmetic.
local lineNumbers = {}
local lineCount = 1
local lineHeight
local cursorX, cursorY = 0, 0
local cursorLine = 1
local layoutDirty = false
local cursorDirty = false

---Splits the editor text into jokes: one per line, trimmed, blank lines dropped.
---@param text string
---@return string[]
local function ParseJokes(text)
    local list = {}
    for line in text:gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            list[#list + 1] = line
        end
    end
    return list
end

local function UpdateStatus()
    local count = #ParseJokes(editBox:GetText())
    local source = TwintopQOL.Jokes:IsCustom() and "custom list" or "default list"
    local status = string.format("%d jokes (saved: %s)", count, source)
    if dirty then
        status = status .. "  |cFFFF8000Unsaved changes|r"
    end
    statusText:SetText(status)
end

local function GetLineHeight()
    return lineHeight or select(2, editBox:GetFont())
end

---Draws line numbers for the rows currently in view, offset by the vertical scroll.
local function UpdateLineNumbers()
    local lh = GetLineHeight()
    local scroll = scrollFrame:GetVerticalScroll()
    local first = math.floor(scroll / lh) + 1
    local last = math.min(lineCount, math.ceil((scroll + scrollFrame:GetHeight()) / lh))

    local shown = 0
    for line = first, last do
        shown = shown + 1
        local fs = lineNumbers[shown]
        if not fs then
            fs = gutter:CreateFontString(nil, "OVERLAY")
            fs:SetFontObject("ChatFontNormal")
            fs:SetJustifyH("RIGHT")
            lineNumbers[shown] = fs
        end
        fs:SetPoint("TOPRIGHT", gutter, "TOPRIGHT", -6, scroll - (line - 1) * lh)
        fs:SetText(line)
        if line == cursorLine then
            fs:SetTextColor(1, 0.82, 0)
        else
            fs:SetTextColor(0.5, 0.5, 0.5)
        end
        fs:Show()
    end

    for i = shown + 1, #lineNumbers do
        lineNumbers[i]:Hide()
    end
end

---Widens the edit box to fit its longest line and updates the sideways scroll range.
local function UpdateLayout()
    local widest = 0
    lineCount = 0
    for line in (editBox:GetText() .. "\n"):gmatch("(.-)\n") do
        lineCount = lineCount + 1
        measurer:SetText(line)
        widest = math.max(widest, measurer:GetUnboundedStringWidth())
    end

    local viewWidth = scrollFrame:GetWidth()
    local width = math.max(viewWidth, widest + LINE_END_PADDING)
    editBox:SetWidth(width)

    local maxScroll = math.max(0, width - viewWidth)
    hSlider:SetMinMaxValues(0, maxScroll)
    if maxScroll > 0 then
        hSlider:Enable()
    else
        hSlider:Disable()
    end

    UpdateLineNumbers()
end

---Scrolls just enough, vertically and sideways, to bring the cursor into view.
local function ScrollToCursor()
    scrollFrame:UpdateScrollChildRect()

    local lh = GetLineHeight()
    local top = -cursorY
    local scroll = scrollFrame:GetVerticalScroll()
    local viewHeight = scrollFrame:GetHeight()
    if top < scroll then
        scrollFrame:SetVerticalScroll(top)
    elseif top + lh > scroll + viewHeight then
        scrollFrame:SetVerticalScroll(math.min(top + lh - viewHeight, scrollFrame:GetVerticalScrollRange()))
    end

    local hScroll = hSlider:GetValue()
    local viewWidth = scrollFrame:GetWidth()
    if cursorX < hScroll then
        hSlider:SetValue(cursorX)
    elseif cursorX + LINE_END_PADDING > hScroll + viewWidth then
        hSlider:SetValue(cursorX + LINE_END_PADDING - viewWidth)
    end
end

---Fills the editor with the active joke list, discarding unsaved edits.
local function LoadJokes()
    editBox:SetText(table.concat(TwintopQOL.Jokes:GetList(), "\n"))
    editBox:SetCursorPosition(0)
    hSlider:SetValue(0)
    dirty = false
    layoutDirty = true
    UpdateStatus()
end

local function SaveJokes()
    local list = ParseJokes(editBox:GetText())
    TwintopQOL.Jokes:SetList(list)
    -- Reload from the saved list, so blank lines disappear and line numbers match jokes.
    LoadJokes()

    local tooLong = 0
    for i = 1, #list do
        if #list[i] > MAX_CHAT_LENGTH then
            tooLong = tooLong + 1
        end
    end

    TwintopQOL:Print(string.format("Saved %d jokes.", #list))
    if tooLong > 0 then
        TwintopQOL:Print(string.format("|cFFFF8000Warning:|r %d jokes are longer than %d characters and can't be sent in chat.", tooLong, MAX_CHAT_LENGTH))
    end
end

---Builds the editable text area: a line-number gutter, a multi-line edit box
---inside a scroll frame, and a horizontal scrollbar under it.
---@param parent Frame
local function BuildEditor(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetPoint("TOPLEFT", 0, -80)
    container:SetPoint("BOTTOMRIGHT", 0, 32)
    container:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    container:SetBackdropColor(0, 0, 0, 0.6)

    gutter = CreateFrame("Frame", nil, container)
    gutter:SetPoint("TOPLEFT", 8, -8)
    gutter:SetPoint("BOTTOMLEFT", 8, 30)
    gutter:SetWidth(GUTTER_WIDTH)
    gutter:SetClipsChildren(true)

    local separator = gutter:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(1, 1, 1, 0.15)
    separator:SetWidth(1)
    separator:SetPoint("TOPRIGHT", -2, 0)
    separator:SetPoint("BOTTOMRIGHT", -2, 0)

    scrollFrame = CreateFrame("ScrollFrame", "TwintopQOLJokesScrollFrame", container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", gutter, "TOPRIGHT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 30)

    hSlider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    hSlider:SetOrientation("HORIZONTAL")
    hSlider:SetHeight(17)
    hSlider:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -6)
    hSlider:SetPoint("TOPRIGHT", scrollFrame, "BOTTOMRIGHT", 0, -6)
    hSlider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })
    hSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    hSlider:SetMinMaxValues(0, 0)
    hSlider:SetValueStep(1)
    hSlider:SetObeyStepOnDrag(true)
    hSlider:SetValue(0)
    hSlider:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetHorizontalScroll(value)
    end)

    editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(600)
    editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
    scrollFrame:SetScrollChild(editBox)

    -- Current-row highlight, drawn behind the text.
    highlight = editBox:CreateTexture(nil, "BACKGROUND")
    highlight:SetColorTexture(1, 1, 1, 0.08)

    -- Hidden-in-practice font string used to measure line widths.
    measurer = container:CreateFontString(nil, "OVERLAY")
    measurer:SetFontObject("ChatFontNormal")
    measurer:SetAlpha(0)

    editBox:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            dirty = true
        end
        layoutDirty = true
        UpdateStatus()
    end)
    editBox:SetScript("OnCursorChanged", function(_, x, y, _, h)
        if h and h > 0 then
            lineHeight = h
        end
        cursorX, cursorY = x, y
        cursorLine = math.floor(-y / GetLineHeight() + 0.5) + 1
        highlight:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, y)
        highlight:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", 0, y)
        highlight:SetHeight(GetLineHeight())
        cursorDirty = true
        UpdateLineNumbers()
    end)
    -- Layout and scrolling wait a frame so the edit box has resized to its new text first.
    editBox:SetScript("OnUpdate", function()
        if layoutDirty then
            layoutDirty = false
            UpdateLayout()
        end
        if cursorDirty then
            cursorDirty = false
            ScrollToCursor()
        end
    end)

    scrollFrame:HookScript("OnVerticalScroll", UpdateLineNumbers)
    scrollFrame:SetScript("OnSizeChanged", function()
        layoutDirty = true
    end)

    -- Shift + mouse wheel scrolls sideways; plain wheel keeps the template's vertical scroll.
    local verticalWheel = scrollFrame:GetScript("OnMouseWheel")
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        if IsShiftKeyDown() then
            hSlider:SetValue(hSlider:GetValue() - delta * H_SCROLL_STEP)
        elseif verticalWheel then
            verticalWheel(self, delta)
        end
    end)

    -- Clicking anywhere in the text area (not just on existing text) starts editing.
    for _, region in ipairs({ container, gutter, scrollFrame }) do
        region:EnableMouse(true)
        region:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    end
end

---Fills the Jokes page of the main window.
---@param panel Frame
local function BuildPage(panel)
    local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText("Jokes")

    local instructions = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    instructions:SetPoint("TOPLEFT", 0, -26)
    instructions:SetPoint("TOPRIGHT", 0, -26)
    instructions:SetJustifyH("LEFT")
    instructions:SetText(string.format(
        "Enter |cFFFFCC00one joke per line|r. Blank lines are removed when you save. Click |cFFFFCC00Save|r to keep your changes; "
        .. "closing the window without saving discards them. Jokes longer than %d characters can't be sent in chat. "
        .. "Hold Shift and use the mouse wheel to scroll sideways.",
        MAX_CHAT_LENGTH))

    BuildEditor(panel)

    statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("BOTTOMLEFT", 4, 6)

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("BOTTOMRIGHT", 0, 0)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function() StaticPopup_Show(RESET_POPUP) end)

    local saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 22)
    saveBtn:SetPoint("RIGHT", resetBtn, "LEFT", -6, 0)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", SaveJokes)

    StaticPopupDialogs[RESET_POPUP] = {
        text = "Reset your joke list to the defaults? Your custom jokes will be lost.",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            TwintopQOL.Jokes:SetList(TwintopQOL.Jokes:GetDefaults())
            LoadJokes()
            TwintopQOL:Print("Joke list reset to the defaults.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    -- Unsaved edits survive switching pages, but closing the window discards them.
    local needsReload = true
    TwintopQOL.Window:GetFrame():HookScript("OnHide", function()
        needsReload = true
    end)
    panel:SetScript("OnShow", function()
        if needsReload then
            needsReload = false
            LoadJokes()
        end
    end)
end

TwintopQOL.Window:RegisterPage("jokes", "Jokes", BuildPage)
