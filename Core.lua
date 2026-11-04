local _, TwintopQOL = ...

TwintopQOL = TwintopQOL or {}
TwintopQOL.Data = TwintopQOL.Data or {}
local interfaceVersion = tonumber((select(4, GetBuildInfo())))

-- TwintopInsanityBar's client check: a project ID naming another flavor rules a client out, and the interface number
-- tells the rest apart. An unreadable project ID or interface number isn't evidence of a mismatch.
local function IsClient(projectId, lowestInterface, highestInterface)
    if WOW_PROJECT_ID ~= nil and projectId ~= nil and WOW_PROJECT_ID ~= projectId then
        return false
    end
    return interfaceVersion == nil or (interfaceVersion >= lowestInterface and interfaceVersion <= highestInterface)
end

-- WoW Forever (internally "Camelot"). WOW_PROJECT_CAMELOT is nil on retail.
TwintopQOL.IsForever = IsClient(WOW_PROJECT_CAMELOT, 16001, 19999)
-- Classic Era (Vanilla) and The Burning Crusade Classic (Anniversary), which have talent tabs instead of trait trees.
TwintopQOL.IsClassicEra = IsClient(WOW_PROJECT_CLASSIC, 11300, 15999)
TwintopQOL.IsTBC = IsClient(WOW_PROJECT_BURNING_CRUSADE_CLASSIC, 20000, 29999)

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
    local cmd = TwintopQOL:ParseCmdString(msg)

    if cmd == "" then
        TwintopQOL.Window:Toggle()
    elseif cmd == "joke" then
        TwintopQOL.Jokes:Send()
    elseif cmd == "jokes" then
        TwintopQOL.Window:Toggle("jokesList")
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
        TwintopQOL.ReadyCheck:Init()
        TwintopQOL.Jokes:Init()
        -- Both settings above started out as silly mode; it's carried over now.
        TwintopQOLSaved.sillyEnabled = nil

        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        -- Wait out the login sequence, which closes UISpecialFrames (the News window among them).
        C_Timer.After(0, function()
            C_Timer.After(1, function()
                TwintopQOL.News:Init()
            end)
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
