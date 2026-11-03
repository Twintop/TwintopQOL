local _, TwintopQOL = ...

TwintopQOL = TwintopQOL or {}
TwintopQOL.Data = TwintopQOL.Data or {}

local L = TwintopQOL.Localization

function TwintopQOL:Print(msg)
    print(string.format(L["ChatMessage"], msg))
end

local URL_POPUP = "TWINTOPQOL_URL"

StaticPopupDialogs[URL_POPUP] = {
    OnShow = function(self, data)
        self:SetWidth(450)
        self:SetFormattedText(L["UrlPopupText"], data.title)
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
    button1 = L["OK"],
    hasEditBox = true,
    hasWideEditBox = true,
    editBoxWidth = 400,
    timeout = 60,
    whileDead = true,
    closeButton = true,
    hideOnEscape = true
}

---Shows a popup with a URL selected and ready to copy.
---@param title string
---@param url string
function TwintopQOL:ShowUrl(title, url)
    StaticPopup_Show(URL_POPUP, nil, nil, { title = title, url = url })
end

-- Pretty-prints a table to chat. Handy for poking at Blizzard API return values.
function TwintopQOL:TablePrint(T, indent)
    if not indent then
        indent = 0
    end

    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(T) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end

        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. TwintopQOL:TablePrint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end

    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

-- Splits "foo bar baz" into ("foo", "bar baz"): first whitespace-delimited token
-- plus the remainder of the string.
function TwintopQOL:ParseCmdString(msg)
    if msg then
        while (strfind(msg, "  ") ~= nil) do
            msg = string.gsub(msg, "  ", " ")
        end
        local a, b, c = strfind(msg, "(%S+)")
        if a then
            return c, strsub(msg, b + 2)
        else
            return ""
        end
    end
    return ""
end

local function PrintHelp()
    TwintopQOL:Print(L["SlashHelp"])
end

SLASH_TWINTOPQOL1 = "/tqol"
SLASH_TWINTOPQOL2 = "/twintopqol"
SlashCmdList.TWINTOPQOL = function(msg)
    local cmd, subcmd = TwintopQOL:ParseCmdString(msg)

    if cmd == "" then
        TwintopQOL.Window:Toggle()
    elseif cmd == "joke" then
        TwintopQOL.Jokes:Send()
    elseif cmd == "jokes" then
        TwintopQOL.Window:Toggle("jokesList")
    elseif cmd == "silly" then
        local toggle = TwintopQOL:ParseCmdString(subcmd)
        if toggle == "on" then
            TwintopQOL.Silly:Enable()
            TwintopQOLSaved.sillyEnabled = true
            TwintopQOL:Print(L["SillyModeEnabled"])
        elseif toggle == "off" then
            TwintopQOL.Silly:Disable()
            TwintopQOLSaved.sillyEnabled = false
            TwintopQOL:Print(L["SillyModeDisabled"])
        else
            TwintopQOL:Print(L["SillyModeUsage"])
        end
    elseif cmd == "talents" or cmd == "df" then
        TwintopQOL.Window:Toggle("talents")
    elseif cmd == "news" then
        TwintopQOL.News:Toggle()
    else
        PrintHelp()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "TwintopQOL" then
        TwintopQOLSaved = TwintopQOLSaved or {}
        TwintopQOLSaved.seen = TwintopQOLSaved.seen or {}
        TwintopQOLSaved.news = TwintopQOLSaved.news or {}
        if TwintopQOLSaved.news.enabled == nil then
            TwintopQOLSaved.news.enabled = true
        end
        TwintopQOLSaved.news.lastUpdate = TwintopQOLSaved.news.lastUpdate or ""
        TwintopQOL.Jokes:Init()

        -- Restore silly mode from last session.
        if TwintopQOLSaved.sillyEnabled then
            TwintopQOL.Silly:Enable()
        end

        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        TwintopQOL.News:Init()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
