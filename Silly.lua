local _, TwintopQOL = ...
TwintopQOL.Silly = TwintopQOL.Silly or {}

local L = TwintopQOL.Localization

local function SillyEventHandler(self, event, ...)
    if event == "READY_CHECK_CONFIRM" then
        local player, ready = ...
        if ready and player == "player" then
            C_ChatInfo.SendChatMessage(L["SillyReadyCheckResponse"], "SAY")
        end
    elseif event == "ENCOUNTER_END" then
        local _, _, _, _, success = ...
        if success ~= 1 then
            C_Timer.After(0, function()
                C_Timer.After(3, function()
                    TwintopQOL.Jokes:Send()
                end)
            end)
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", SillyEventHandler)

function TwintopQOL.Silly:Enable()
    eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
    eventFrame:RegisterEvent("ENCOUNTER_END")
end

function TwintopQOL.Silly:Disable()
    eventFrame:UnregisterEvent("READY_CHECK_CONFIRM")
    eventFrame:UnregisterEvent("ENCOUNTER_END")
end
