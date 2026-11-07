local _, TwintopQOL = ...

local locale = GetLocale()

if locale == "enGB" then
    local L = TwintopQOL.Localization

    L["AboutLocalization"] = "Localisation:"
    L["FlightTimerColor"] = "Bar colour"
    L["FlightTimerTimingColor"] = "Colour while timing a new route"
end
