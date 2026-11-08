local _, TwintopQOL = ...

local L = setmetatable({}, { __index = function(t, k)
    local v = tostring(k)
    rawset(t, k, v)
    return v
end })

-- Use existing localization strings provided by Blizzard for some things.
-- Source: https://www.townlong-yak.com/framexml/live/GlobalStrings.lua

L["OK"] = OKAY
L["Yes"] = YES
L["No"] = NO
L["Close"] = CLOSE
L["ChannelSay"] = SAY
L["ChannelYell"] = YELL
L["ChannelRaid"] = RAID
L["ChannelRaidWarning"] = RAID_WARNING
L["ChannelParty"] = PARTY
L["ChannelEmote"] = EMOTE
L["ErrNotInGroup"] = ERR_NOT_IN_GROUP
L["ErrNotInRaid"] = ERR_NOT_IN_RAID
L["ErrNotInInstanceGroup"] = ERR_NOT_IN_INSTANCE_GROUP
L["ErrNotInGuild"] = ERR_GUILD_PLAYER_NOT_IN_GUILD

TwintopQOL.Localization = L
