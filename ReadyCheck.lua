local _, TwintopQOL = ...
TwintopQOL.ReadyCheck = TwintopQOL.ReadyCheck or {}

local L = TwintopQOL.Localization

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
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:SetScript("OnEvent", function(_, _, unit, isReady)
    local config = TwintopQOLSaved.readyCheck
    if not (isReady and unit == "player" and config.enabled) then return end

    local response = strtrim(config.response)
    if response ~= "" then
        C_ChatInfo.SendChatMessage(response, "SAY")
    end
end)
