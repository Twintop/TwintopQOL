local _, TwintopQOL = ...
TwintopQOL.ReadyCheck = TwintopQOL.ReadyCheck or {}

local L = TwintopQOL.Localization

-- Chat channels the response can go to, in dropdown order.
TwintopQOL.ReadyCheck.CHANNELS = { "SAY", "YELL", "RAID", "RAID_WARNING", "PARTY", "EMOTE" }

---@param channel string
---@return boolean
local function IsKnownChannel(channel)
    return tContains(TwintopQOL.ReadyCheck.CHANNELS, channel)
end

---Whether the player is in a group that can hear the channel.
---@param channel string
---@return boolean
local function CanSendTo(channel)
    if channel == "RAID" or channel == "RAID_WARNING" then
        return IsInRaid()
    elseif channel == "PARTY" then
        return IsInGroup(LE_PARTY_CATEGORY_HOME)
    end
    return true
end

---Fills in missing ready check settings. Called once saved variables are loaded.
function TwintopQOL.ReadyCheck:Init()
    -- The ready check response used to be silly mode, so an existing save keeps whatever it had.
    if TwintopQOLSaved.readyCheck == nil then
        TwintopQOLSaved.readyCheck = { enabled = TwintopQOLSaved.sillyEnabled == true }
    end

    local config = TwintopQOLSaved.readyCheck
    if config.response == nil then
        config.response = L["SillyReadyCheckResponse"]
    end
    if not IsKnownChannel(config.channel) then
        config.channel = "SAY"
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:SetScript("OnEvent", function(_, _, unit, isReady)
    local config = TwintopQOLSaved.readyCheck
    if not (isReady and unit == "player" and config.enabled) then return end

    local response = strtrim(config.response)
    if response ~= "" and CanSendTo(config.channel) then
        C_ChatInfo.SendChatMessage(response, config.channel)
    end
end)
