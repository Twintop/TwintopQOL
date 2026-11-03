local _, TwintopQOL = ...
TwintopQOL.Silly = TwintopQOL.Silly or {}

local L = TwintopQOL.Localization

local function SillyEventHandler(self, event, ...)
    if event == "READY_CHECK_CONFIRM" then
        local player, ready = ...
        if ready and player == "player" then
            C_ChatInfo.SendChatMessage(L["SillyReadyCheckResponse"], "SAY")
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", SillyEventHandler)

function TwintopQOL.Silly:Enable()
    eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
end

function TwintopQOL.Silly:Disable()
    eventFrame:UnregisterEvent("READY_CHECK_CONFIRM")
end
