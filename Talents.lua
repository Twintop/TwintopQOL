local _, TwintopQOL = ...

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------
local ROW_HEIGHT = 18
local HEADER_HEIGHT = 22
local COLOR_ACTIVE = { 0.2, 0.9, 0.2 }
local COLOR_INACTIVE = { 1, 0.2, 0.2 }

-- Column definitions { key, header, width, align, sortKey }
-- sortKey (optional) sorts on a different field than the one displayed.
local COLUMNS = {
    { key = "icon",         header = "",           width = 22,  align = "CENTER" },
    { key = "name",         header = "Name",       width = 200, align = "LEFT" },
    { key = "spellId",      header = "Spell ID",   width = 70,  align = "RIGHT" },
    { key = "entryId",      header = "Entry ID",   width = 70,  align = "RIGHT" },
    { key = "nodeId",       header = "Node ID",    width = 70,  align = "RIGHT" },
    { key = "definitionId", header = "Def ID",     width = 70,  align = "RIGHT" },
    { key = "iconId",       header = "Icon ID",    width = 70,  align = "RIGHT" },
    { key = "treeId",       header = "Tree ID",    width = 60,  align = "RIGHT" },
    { key = "ranks",        header = "Ranks",      width = 55,  align = "CENTER", sortKey = "currentRank" },
    { key = "status",       header = "Status",     width = 70,  align = "CENTER", sortKey = "activeSort" },
}

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------
local frame
local titleText
local rowCountLabel
local scrollFrame
local scrollChild
local exportFrame
local headerButtons = {}
local rows = {}
local data = {}
local sortColumn = "order" -- original tree/node order until a header is clicked
local sortAscending = true

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function GetTotalColumnWidth()
    local total = 0
    for _, colDef in ipairs(COLUMNS) do
        total = total + colDef.width
    end
    return total + 8
end

local function GetSortField(key)
    for _, colDef in ipairs(COLUMNS) do
        if colDef.key == key then
            return colDef.sortKey or colDef.key
        end
    end
    return key
end

-- Walk the active talent config and collect every node's spell, along with
-- its entry/node/definition ids and rank info. A node is inactive when it is
-- unranked or its sub-tree (hero talents) is inactive.
local function GatherTalents()
    local result = {}
    local configId = C_ClassTalents.GetActiveConfigID()
    if configId == nil then
        return result, nil
    end
    local configInfo = C_Traits.GetConfigInfo(configId)
    if configInfo == nil then
        return result, configId
    end

    for _, treeId in pairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeId)
        for _, nodeId in pairs(nodes) do
            local node = C_Traits.GetNodeInfo(configId, nodeId)
            local entryId = nil

            if node.activeEntry ~= nil then
                entryId = node.activeEntry.entryID
            elseif node.nextEntry ~= nil then
                entryId = node.nextEntry.entryID
            elseif node.entryIDs ~= nil then
                entryId = node.entryIDs[1]
            end

            if entryId ~= nil then
                local entryInfo = C_Traits.GetEntryInfo(configId, entryId)
                if entryInfo ~= nil and entryInfo.definitionID ~= nil then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)

                    if definitionInfo ~= nil then
                        local spellId = definitionInfo.spellID or definitionInfo.overriddenSpellID

                        if spellId ~= nil then
                            local spellInfo = C_Spell.GetSpellInfo(spellId) --[[@as SpellInfo]]
                            local active = not (node.currentRank == 0 or node.subTreeActive == false)

                            result[#result + 1] = {
                                order = #result + 1,
                                iconId = spellInfo and spellInfo.originalIconID,
                                name = spellInfo and spellInfo.name or "?",
                                spellId = spellId,
                                entryId = entryId,
                                nodeId = nodeId,
                                definitionId = entryInfo.definitionID,
                                treeId = treeId,
                                ranks = node.currentRank .. "/" .. node.maxRanks,
                                currentRank = node.currentRank,
                                active = active,
                                activeSort = active and 1 or 0,
                                status = active and "Active" or "Inactive",
                            }
                        end
                    end
                end
            end
        end
    end
    return result, configId, configInfo
end

----------------------------------------------------------------------
-- Sorting
----------------------------------------------------------------------
local function SortData(list, col, asc)
    local sorted = {}
    for i, v in ipairs(list) do
        sorted[i] = v
    end
    table.sort(sorted, function(a, b)
        local va = a[col]
        local vb = b[col]
        if va == nil then va = "" end
        if vb == nil then vb = "" end
        if va == vb then
            -- Stable tie-break on original order
            return a.order < b.order
        end
        -- Attempt numeric comparison
        local na, nb = tonumber(va), tonumber(vb)
        if na and nb then
            if asc then return na < nb else return na > nb end
        end
        -- String comparison
        va = tostring(va)
        vb = tostring(vb)
        if asc then return va < vb else return va > vb end
    end)
    return sorted
end

----------------------------------------------------------------------
-- Row pool
----------------------------------------------------------------------
local function EnsureRows(count)
    for i = #rows + 1, count do
        local row = CreateFrame("Button", nil, scrollChild)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        row.cells = {}

        -- Alternating background
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        if i % 2 == 0 then
            bg:SetColorTexture(1, 1, 1, 0.04)
        else
            bg:SetColorTexture(0, 0, 0, 0)
        end

        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.1)

        local xOff = 4
        for c, colDef in ipairs(COLUMNS) do
            if colDef.key == "icon" then
                local tex = row:CreateTexture(nil, "ARTWORK")
                tex:SetSize(16, 16)
                tex:SetPoint("LEFT", row, "LEFT", xOff + 2, 0)
                row.icon = tex
            else
                local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                fs:SetPoint("LEFT", row, "LEFT", xOff + 2, 0)
                fs:SetWidth(colDef.width - 4)
                fs:SetJustifyH(colDef.align)
                fs:SetWordWrap(false)
                row.cells[c] = fs
            end
            xOff = xOff + colDef.width
        end

        -- Hover for spell tooltip, shift-click to link in chat
        row:SetScript("OnEnter", function(self)
            if self.spellId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self.spellId)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(self)
            if self.spellId and IsModifiedClick("CHATLINK") then
                local insertLink = (ChatFrameUtil and ChatFrameUtil.InsertLink) or ChatEdit_InsertLink
                insertLink(C_Spell.GetSpellLink(self.spellId))
            end
        end)

        rows[i] = row
    end
end

----------------------------------------------------------------------
-- Refresh display
----------------------------------------------------------------------
local function RefreshDisplay()
    if not frame or not frame:IsVisible() then return end

    local sorted = SortData(data, GetSortField(sortColumn), sortAscending)
    EnsureRows(#sorted)

    for _, row in ipairs(rows) do
        row:Hide()
    end

    for i, entry in ipairs(sorted) do
        local row = rows[i]
        row.spellId = entry.spellId

        if entry.iconId then
            row.icon:SetTexture(entry.iconId)
            row.icon:Show()
        else
            row.icon:Hide()
        end

        local color = entry.active and COLOR_ACTIVE or COLOR_INACTIVE
        for c, colDef in ipairs(COLUMNS) do
            local fs = row.cells[c]
            if fs then
                local val = entry[colDef.key]
                fs:SetText(val ~= nil and tostring(val) or "")
                fs:SetTextColor(color[1], color[2], color[3])
            end
        end
        row:Show()
    end

    scrollChild:SetHeight(math.max(1, #sorted * ROW_HEIGHT))

    local active = 0
    for _, entry in ipairs(data) do
        if entry.active then active = active + 1 end
    end
    rowCountLabel:SetText(#data .. " talents (" .. active .. " active)")
end

local function Rescan()
    local configId, configInfo
    data, configId, configInfo = GatherTalents()
    if frame then
        local subtitle = ""
        if configInfo and configInfo.name and configInfo.name ~= "" then
            subtitle = " - " .. configInfo.name
        end
        if configId then
            subtitle = subtitle .. " |cFF888888(Config " .. configId .. ")|r"
        end
        titleText:SetText("Talents" .. subtitle)
    end
    RefreshDisplay()
end

----------------------------------------------------------------------
-- Header bar
----------------------------------------------------------------------
local function UpdateHeaderArrows()
    for c, colDef in ipairs(COLUMNS) do
        local arrow = headerButtons[c].arrow
        if sortColumn == colDef.key then
            arrow:SetTexture(sortAscending and "Interface\\Buttons\\Arrow-Up-Up" or "Interface\\Buttons\\Arrow-Down-Up")
            arrow:Show()
        else
            arrow:Hide()
        end
    end
end

local function CreateHeaders(parent)
    local xOff = 4
    for c, colDef in ipairs(COLUMNS) do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(colDef.width, HEADER_HEIGHT)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", 4, 0)
        fs:SetPoint("RIGHT", -12, 0)
        fs:SetJustifyH(colDef.align)
        fs:SetText(colDef.header)

        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(10, 10)
        arrow:SetPoint("RIGHT", -2, 0)
        arrow:Hide()
        btn.arrow = arrow

        -- The icon column has nothing meaningful to sort on
        if colDef.key ~= "icon" then
            btn:SetScript("OnClick", function()
                if sortColumn == colDef.key then
                    sortAscending = not sortAscending
                else
                    sortColumn = colDef.key
                    sortAscending = true
                end
                UpdateHeaderArrows()
                RefreshDisplay()
            end)

            btn:SetScript("OnEnter", function()
                bg:SetColorTexture(0.25, 0.25, 0.25, 0.9)
            end)
            btn:SetScript("OnLeave", function()
                bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
            end)
        end

        headerButtons[c] = btn
        xOff = xOff + colDef.width
    end
    UpdateHeaderArrows()
end

----------------------------------------------------------------------
-- Export frame
----------------------------------------------------------------------
local function BuildTSV()
    local lines = {}
    local hdr = {}
    for _, colDef in ipairs(COLUMNS) do
        if colDef.key ~= "icon" then
            hdr[#hdr + 1] = colDef.header
        end
    end
    lines[#lines + 1] = table.concat(hdr, "\t")

    local sorted = SortData(data, GetSortField(sortColumn), sortAscending)
    for _, entry in ipairs(sorted) do
        local vals = {}
        for _, colDef in ipairs(COLUMNS) do
            if colDef.key ~= "icon" then
                local v = entry[colDef.key]
                vals[#vals + 1] = v ~= nil and tostring(v) or ""
            end
        end
        lines[#lines + 1] = table.concat(vals, "\t")
    end
    return table.concat(lines, "\n")
end

local function ShowExport()
    if not exportFrame then
        exportFrame = CreateFrame("Frame", "TwintopQOLTalentsExportFrame", frame, "BackdropTemplate")
        exportFrame:SetSize(600, 400)
        exportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        exportFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        exportFrame:SetFrameStrata("DIALOG")
        exportFrame:SetMovable(true)
        exportFrame:EnableMouse(true)
        exportFrame:RegisterForDrag("LeftButton")
        exportFrame:SetScript("OnDragStart", exportFrame.StartMoving)
        exportFrame:SetScript("OnDragStop", exportFrame.StopMovingOrSizing)

        local title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Export (Ctrl+A, Ctrl+C to copy)")

        local sf = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 12, -34)
        sf:SetPoint("BOTTOMRIGHT", -30, 40)

        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject("ChatFontNormal")
        eb:SetWidth(sf:GetWidth() or 540)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        sf:SetScrollChild(eb)
        exportFrame.editBox = eb

        local closeBtn = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
        closeBtn:SetSize(80, 22)
        closeBtn:SetPoint("BOTTOM", 0, 10)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function() exportFrame:Hide() end)
    end

    exportFrame.editBox:SetText(BuildTSV())
    exportFrame.editBox:HighlightText()
    exportFrame:Show()
end

----------------------------------------------------------------------
-- Build page
----------------------------------------------------------------------
---Fills the Talents page of the main window.
---@param panel Frame
local function BuildPage(panel)
    frame = panel

    titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText("Talents")

    -- Bottom toolbar
    local refreshBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    refreshBtn:SetSize(70, 22)
    refreshBtn:SetPoint("BOTTOMLEFT", 0, 0)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", Rescan)

    local exportBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportBtn:SetSize(70, 22)
    exportBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 6, 0)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", ShowExport)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    hint:SetText("Shift-click a row to link the spell")

    rowCountLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rowCountLabel:SetPoint("BOTTOMRIGHT", -4, 6)
    rowCountLabel:SetJustifyH("RIGHT")

    -- Header
    local header = CreateFrame("Frame", nil, panel)
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -28)
    header:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
    CreateHeaders(header)

    -- Vertical scroll frame below header
    scrollFrame = CreateFrame("ScrollFrame", "TwintopQOLTalentsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 30)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(GetTotalColumnWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    panel:SetScript("OnShow", Rescan)

    -- Keep the page in sync when talents change while it's open
    panel:RegisterEvent("TRAIT_CONFIG_UPDATED")
    panel:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    panel:SetScript("OnEvent", function(self)
        if self:IsVisible() then
            Rescan()
        end
    end)
end

TwintopQOL.Window:RegisterPage("talents", "Talents", BuildPage)
