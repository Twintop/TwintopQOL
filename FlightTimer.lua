local _, TwintopQOL = ...
TwintopQOL.FlightTimer = TwintopQOL.FlightTimer or {}

local L = TwintopQOL.Localization
local SharedMedia = LibStub("LibSharedMedia-3.0")

-- Seconds from taking a flight to lifting off, after which it counts as never taken (too poor, shapeshifted, ...).
local TAKEOFF_TIMEOUT = 5
-- Point, relative point, x, y, against UIParent.
local DEFAULT_POINT = { "CENTER", "CENTER", 0, 150 }
-- The bar's look until the player changes it. Its size leaves out the 1 pixel border.
local DEFAULT_WIDTH = 250
local DEFAULT_HEIGHT = 18
local DEFAULT_TEXTURE = "Blizzard"
local DEFAULT_COLOR = { r = 0.2, g = 0.55, b = 0.9 }
local DEFAULT_TIMING_COLOR = { r = 0.4, g = 0.4, b = 0.4 }
-- The size of GameFontHighlightSmall, which the bar's texts are made with. The default font is the game's own.
local DEFAULT_FONT_SIZE = 10
-- What the bar draws while its texture's name isn't registered with LibSharedMedia.
local FALLBACK_TEXTURE_PATH = "Interface\\TargetingFrame\\UI-StatusBar"
-- The preview's fill and time.
local PREVIEW_FILL = 0.6
local PREVIEW_SECONDS = 83
-- WoW Forever's Frequent Flier legacy perk, node 110300 of the Adventure legacy tree, makes flights about 20% faster.
-- Flights with and without it are timed apart; the speed only estimates one's time from the other's.
local FREQUENT_FLIER_NODE = 110300
local FREQUENT_FLIER_SPEED = 1.2
-- Calls that can take the player off a flight before it lands, which would make its time too short.
local INTERRUPTING_CALLS = { "TaxiRequestEarlyLanding", "AcceptBattlefieldPort", "AcceptProposal", "LFGTeleport" }

-- The slot a hop of the route to a slot starts (isSource) or ends at. Annotated without its parameters.
local TaxiGetNodeSlot = TaxiGetNodeSlot --[[@as fun(slot: number, hop: number, isSource: boolean): number]]

---A flight taken from a flight master. Saved as TwintopQOLSaved.flightTimer.inFlight once airborne, so a UI reload
---picks it back up.
---@class TwintopQOL.Flight
---@field route string The node ID of every stop, origin to destination: "12>34>56".
---@field destination string
---@field frequentFlier boolean The character has WoW Forever's Frequent Flier perk.
---@field expected number|nil Seconds the flight should take; nil when there's nothing to go on.
---@field estimated boolean|nil The expected time isn't one this route was flown in, at this character's speed.
---@field requested number GetTime() when the flight was taken.
---@field start number|nil GetTime() at takeoff.
---@field leftWorld number|nil GetTime() when a loading screen began mid-flight.
---@field interrupted boolean|nil Something may have ended the flight early, so its time isn't kept.

-- Follows the flight frame by frame while there is one, whether the bar shows or not.
local tracker
local bar
local statusBar
local destinationText
local timeText
---@type TwintopQOL.Flight|nil
local flight
-- The options page is open, so the bar shows a preview when there's no flight.
local preview = false
-- The whole seconds last shown, so the text changes only when it has to.
local shownSeconds

---The fastest time of each route, flown with or without Frequent Flier.
---@param frequentFlier boolean
---@return table<string, number>
local function GetTimes(frequentFlier)
    local config = TwintopQOLSaved.flightTimer
    return frequentFlier and config.frequentFlierTimes or config.times
end

---A route's recorded time at this character's speed, or else one estimated from its time at the other speed.
---@param route string
---@param frequentFlier boolean
---@return number|nil seconds
---@return boolean estimated
local function LookUpTime(route, frequentFlier)
    local recorded = GetTimes(frequentFlier)[route]
    if recorded then
        return recorded, false
    end
    local other = GetTimes(not frequentFlier)[route]
    if other then
        return frequentFlier and other / FREQUENT_FLIER_SPEED or other * FREQUENT_FLIER_SPEED, true
    end
    return nil, false
end

---How long a route should take: its own time, or else the sum of its legs' times when every leg has one.
---@param route string
---@param frequentFlier boolean
---@return number|nil seconds
---@return boolean estimated
local function GetRouteTime(route, frequentFlier)
    local seconds, estimated = LookUpTime(route, frequentFlier)
    if seconds then
        return seconds, estimated
    end

    local stops = {}
    for stop in route:gmatch("[^>]+") do
        stops[#stops + 1] = stop
    end
    if #stops < 3 then
        return nil, false
    end
    local total = 0
    for i = 2, #stops do
        local leg = LookUpTime(stops[i - 1] .. ">" .. stops[i], frequentFlier)
        if not leg then
            return nil, false
        end
        total = total + leg
    end
    return total, true
end

---@param seconds number Whole seconds.
---@param estimated boolean|nil
---@return string
local function FormatTime(seconds, estimated)
    local text = string.format(L["FlightTimerTime"], math.floor(seconds / 60), seconds % 60)
    if estimated then
        return string.format(L["FlightTimerEstimate"], text)
    end
    return text
end

---Shows the time left on a route with an expected time, or the time flown on one without.
---@param current TwintopQOL.Flight
---@param elapsed number Seconds since takeoff.
local function UpdateBar(current, elapsed)
    local seconds
    if current.expected then
        local remaining = math.max(current.expected - elapsed, 0)
        statusBar:SetValue(remaining)
        seconds = math.ceil(remaining)
    else
        seconds = math.floor(elapsed)
    end
    if seconds ~= shownSeconds then
        shownSeconds = seconds
        timeText:SetText(FormatTime(seconds, current.estimated))
    end
end

---Puts the bar where the player left it, or at the default spot.
local function PlaceBar()
    local point = TwintopQOLSaved.flightTimer.point or DEFAULT_POINT
    bar:ClearAllPoints()
    bar:SetPoint(point[1], UIParent, point[2], point[3], point[4])
end

---The file of the bar's texture, or the default bar while its name isn't registered.
---@return string
local function GetTexturePath()
    return SharedMedia:Fetch("statusbar", TwintopQOLSaved.flightTimer.texture, true) or FALLBACK_TEXTURE_PATH
end

---The file of the bar's font, or the game's font while its name isn't registered.
---@return string
local function GetFontPath()
    return SharedMedia:Fetch("font", TwintopQOLSaved.flightTimer.fontFace, true) or STANDARD_TEXT_FONT
end

---Sizes the bar, draws its texture and font, and locks or unlocks it, from the settings.
local function StyleBar()
    local config = TwintopQOLSaved.flightTimer
    bar:SetSize(config.width + 2, config.height + 2)
    -- Locked, it lets clicks through to the world as well as staying put.
    bar:EnableMouse(not config.locked)
    statusBar:SetStatusBarTexture(GetTexturePath())
    -- The texts keep their template's color and shadow.
    local fontPath = GetFontPath()
    destinationText:SetFont(fontPath, config.fontSize, "")
    timeText:SetFont(fontPath, config.fontSize, "")
end

local function CreateBar()
    bar = CreateFrame("Frame", "TwintopQOLFlightTimer", UIParent, "BackdropTemplate")
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    bar:SetBackdropColor(0, 0, 0, 0.5)
    bar:SetBackdropBorderColor(0, 0, 0, 1)
    bar:SetClampedToScreen(true)
    bar:SetMovable(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self) self:StartMoving() end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- The position lives in our saved variables, not the client's layout cache.
        self:SetUserPlaced(false)
        local point, _, relativePoint, x, y = self:GetPoint()
        TwintopQOLSaved.flightTimer.point = { point, relativePoint, x, y }
    end)
    bar:SetScript("OnHide", bar.StopMovingOrSizing)
    bar:Hide()

    statusBar = CreateFrame("StatusBar", nil, bar)
    statusBar:SetPoint("TOPLEFT", 1, -1)
    statusBar:SetPoint("BOTTOMRIGHT", -1, 1)

    timeText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetPoint("RIGHT", -6, 0)

    destinationText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    destinationText:SetPoint("LEFT", 6, 0)
    destinationText:SetPoint("RIGHT", timeText, "LEFT", -6, 0)
    destinationText:SetJustifyH("LEFT")
    destinationText:SetWordWrap(false)

    StyleBar()
    PlaceBar()
end

---@param color { r: number, g: number, b: number }
local function ColorBar(color)
    statusBar:SetStatusBarColor(color.r, color.g, color.b)
end

---Shows the bar for a flight: full and counting down with an expected time, counting up in the timing color without.
---@param current TwintopQOL.Flight
local function ShowBar(current)
    local config = TwintopQOLSaved.flightTimer
    if current.expected then
        statusBar:SetMinMaxValues(0, current.expected)
        destinationText:SetText(current.destination)
        ColorBar(config.color)
    else
        statusBar:SetMinMaxValues(0, 1)
        statusBar:SetValue(1)
        destinationText:SetText(string.format(L["FlightTimerTiming"], current.destination))
        ColorBar(config.timingColor)
    end

    shownSeconds = nil
    UpdateBar(current, current.start and (GetTime() - current.start) or 0)
    bar:Show()
end

---Shows a made-up flight on the bar, so its look and position can be set without flying.
local function ShowPreview()
    local config = TwintopQOLSaved.flightTimer
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(PREVIEW_FILL)
    ColorBar(config.color)
    destinationText:SetText(config.locked and L["FlightTimerPreviewLocked"] or L["FlightTimerPreview"])
    timeText:SetText(FormatTime(PREVIEW_SECONDS))
    -- The next flight sets its own time text.
    shownSeconds = nil
    bar:Show()
end

---Shows the current flight on the bar, or the preview while the options page is open, or puts the bar away.
local function RefreshBar()
    local showBar = TwintopQOLSaved.flightTimer.showBar
    if showBar and (flight or preview) and not bar then
        CreateBar()
    end
    if showBar and flight then
        ShowBar(flight)
    elseif showBar and preview then
        ShowPreview()
    elseif bar then
        bar:Hide()
    end
end

---Ends the current flight's timer.
local function StopFlight()
    flight = nil
    TwintopQOLSaved.flightTimer.inFlight = nil
    tracker:Hide()
    RefreshBar()
end

---Records the flight's time, unless something may have cut it short, and ends its timer.
---@param current TwintopQOL.Flight
---@param duration number Seconds from takeoff to landing.
local function Land(current, duration)
    if not current.interrupted then
        local times = GetTimes(current.frequentFlier)
        local seconds = math.floor(duration * 10 + 0.5) / 10
        local fastest = times[current.route]
        if fastest == nil or seconds < fastest then
            times[current.route] = seconds
        end
    end
    StopFlight()
end

---Waits for takeoff, then follows the flight until it lands.
local function OnUpdate()
    local current = flight
    if not current then
        tracker:Hide()
        return
    end

    local now = GetTime()
    if not current.start then
        if UnitOnTaxi("player") then
            current.start = now
            TwintopQOLSaved.flightTimer.inFlight = current
        elseif now - current.requested > TAKEOFF_TIMEOUT then
            StopFlight()
        end
        return
    end

    if current.leftWorld then
        return
    elseif UnitOnTaxi("player") then
        if bar and bar:IsShown() then
            UpdateBar(current, now - current.start)
        end
    else
        Land(current, now - current.start)
    end
end

-- Named so the smoke harness can step it.
tracker = CreateFrame("Frame", "TwintopQOLFlightTimerTracker")
tracker:Hide()
tracker:SetScript("OnUpdate", OnUpdate)

---Starts following a flight, with the bar up if it's on.
---@param current TwintopQOL.Flight
local function StartFlight(current)
    flight = current
    tracker:Show()
    RefreshBar()
end

---Flights are timed while the bar or the tooltips show their times.
---@return boolean
local function IsTiming()
    local config = TwintopQOLSaved.flightTimer
    return config.showBar or config.showTooltips
end

---Whether this character has WoW Forever's Frequent Flier perk.
---@return boolean
local function HasFrequentFlier()
    -- Legacy perks exist only on WoW Forever.
    local legacy = Constants and (Constants --[[@as table<string, any>]]).LegacyConsts
    local treeId = legacy and legacy.LEGACY_TREE_ADVENTURE_ID
    if not treeId then
        return false
    end
    local configId = C_Traits.GetConfigIDByTreeID(treeId)
    local node = configId and C_Traits.GetNodeInfo(configId, FREQUENT_FLIER_NODE)
    return node ~= nil and (node.activeRank or 0) > 0
end

---Maps the open flight map's slots to taxi node IDs.
---@return table<number, number>
local function GetNodeIds()
    local mapIds = { GetTaxiMapID() }
    -- The retail flight map can move on to another map than the one it opened on (Zaralek Cavern from the Dragon Isles).
    -- Each map lists only its own nodes, but a slot is the same node on every map.
    local viewedMapId = FlightMapFrame and FlightMapFrame:GetMapID()
    if viewedMapId then
        mapIds[#mapIds + 1] = viewedMapId
    end

    local nodeIds = {}
    for _, mapId in ipairs(mapIds) do
        for _, node in ipairs(C_TaxiMap.GetAllTaxiNodes(mapId) or {}) do
            nodeIds[node.slotIndex] = node.nodeID
        end
    end
    return nodeIds
end

---The route to a slot, as the node ID of every stop from the origin to the destination: "12>34>56". Routes are told
---apart by their stops because a character that knows fewer flight points flies a longer way to the same place.
---@param slot number
---@return string|nil route Nil when a stop can't be found on the flight map.
local function GetRoute(slot)
    local hops = GetNumRoutes(slot)
    if not hops or hops < 1 then
        return nil
    end

    local nodeIds = GetNodeIds()
    local origin = nodeIds[TaxiGetNodeSlot(slot, 1, true)]
    if not origin then
        return nil
    end
    local stops = { origin }
    for hop = 1, hops do
        local stop = nodeIds[TaxiGetNodeSlot(slot, hop, false)]
        if not stop then
            return nil
        end
        stops[#stops + 1] = stop
    end
    return table.concat(stops, ">")
end

-- After the client takes the flight, the flight map is still open for reading.
hooksecurefunc("TakeTaxiNode", function(slot)
    if not IsTiming() or TaxiNodeGetType(slot) ~= "REACHABLE" or GetMoney() < TaxiNodeCost(slot) then
        return
    end

    local route = GetRoute(slot)
    if not route then
        return
    end

    local frequentFlier = HasFrequentFlier()
    local expected, estimated = GetRouteTime(route, frequentFlier)
    local name = TaxiNodeName(slot)
    ---@type TwintopQOL.Flight
    local current = {
        route = route,
        -- "Ironforge, Dun Morogh" shows as "Ironforge".
        destination = name:match("^(.-), ") or name,
        frequentFlier = frequentFlier,
        expected = expected,
        estimated = estimated,
        requested = GetTime()
    }
    TwintopQOLSaved.flightTimer.inFlight = nil
    StartFlight(current)
end)

local function Interrupt()
    if flight then
        flight.interrupted = true
    end
end

for _, name in ipairs(INTERRUPTING_CALLS) do
    if _G[name] then
        hooksecurefunc(name, Interrupt)
    end
end
if C_SummonInfo and C_SummonInfo.ConfirmSummon then
    hooksecurefunc(C_SummonInfo, "ConfirmSummon", Interrupt)
end

---Adds the flight time to a flight point's tooltip on the flight map.
---@param owner table The flight map button or pin the tooltip belongs to.
---@param slot number|nil
local function AddTooltipTime(owner, slot)
    if not TwintopQOLSaved.flightTimer.showTooltips or not slot or GameTooltip:GetOwner() ~= owner
        or TaxiNodeGetType(slot) ~= "REACHABLE" then
        return
    end

    local route = GetRoute(slot)
    if not route then
        return
    end
    local seconds, estimated = GetRouteTime(route, HasFrequentFlier())
    if not seconds then
        return
    end
    GameTooltip:AddLine(string.format(L["FlightTimerTooltip"], FormatTime(math.floor(seconds + 0.5), estimated)), 1, 1, 1)
    GameTooltip:Show()
end

local taxiFrameHooked = false
local flightMapHooked = false

---Hooks the flight point tooltips of the flight maps loaded so far.
---@return boolean done Both are hooked.
local function HookTooltips()
    -- The flight master window of the Classic clients, which every flight point button calls on mouseover.
    if not taxiFrameHooked and TaxiNodeOnButtonEnter then
        hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
            AddTooltipTime(button, button:GetID())
        end)
        taxiFrameHooked = true
    end
    -- The retail flight map, which loads on demand. Its pins copy the mixin's methods when made, after it loads.
    if not flightMapHooked and FlightMap_FlightPointPinMixin then
        hooksecurefunc(FlightMap_FlightPointPinMixin, "OnMouseEnter", function(pin)
            AddTooltipTime(pin, pin.taxiNodeData and pin.taxiNodeData.slotIndex)
        end)
        flightMapHooked = true
    end
    return taxiFrameHooked and flightMapHooked
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
if not HookTooltips() then
    eventFrame:RegisterEvent("ADDON_LOADED")
end
eventFrame:SetScript("OnEvent", function(self, event, _, isReloadingUi)
    if event == "ADDON_LOADED" then
        if HookTooltips() then
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        if flight and flight.start then
            flight.leftWorld = GetTime()
        end
    elseif flight then
        -- A loading screen mid-flight. The flight waits it out, so its time leaves it out.
        if flight.start and flight.leftWorld then
            flight.start = flight.start + GetTime() - flight.leftWorld
        end
        flight.leftWorld = nil
    else
        -- Entering the world after a load. A UI reload keeps the flight going and GetTime() counting, so its timer
        -- carries on. A logout pauses the flight, so a flight saved before one is dropped.
        local config = TwintopQOLSaved.flightTimer
        local saved = config.inFlight
        config.inFlight = nil
        if saved and isReloadingUi and IsTiming() and saved.start and saved.start <= GetTime() and UnitOnTaxi("player") then
            saved.leftWorld = nil
            config.inFlight = saved
            StartFlight(saved)
        end
    end
end)

-- Another addon can register the bar's texture or font after the bar is drawn with the fallback.
SharedMedia.RegisterCallback(TwintopQOL.FlightTimer, "LibSharedMedia_Registered", function(_, mediaType, name)
    local config = TwintopQOLSaved.flightTimer
    if bar and ((mediaType == "statusbar" and name == config.texture) or (mediaType == "font" and name == config.fontFace)) then
        TwintopQOL.FlightTimer:ApplyAppearance()
    end
end)

---@param color { r: number, g: number, b: number }
---@return { r: number, g: number, b: number }
local function CopyColor(color)
    return { r = color.r, g = color.g, b = color.b }
end

---Fills in missing flight timer settings. Called once saved variables are loaded.
function TwintopQOL.FlightTimer:Init()
    TwintopQOLSaved.flightTimer = TwintopQOLSaved.flightTimer or {}
    local config = TwintopQOLSaved.flightTimer
    -- Off until the player turns it on, like every feature.
    if config.showBar == nil then
        config.showBar = false
    end
    if config.showTooltips == nil then
        config.showTooltips = false
    end
    if config.locked == nil then
        config.locked = false
    end
    config.width = config.width or DEFAULT_WIDTH
    config.height = config.height or DEFAULT_HEIGHT
    config.texture = config.texture or DEFAULT_TEXTURE
    config.color = config.color or CopyColor(DEFAULT_COLOR)
    -- The color while a route is timed for the first time, counting up.
    config.timingColor = config.timingColor or CopyColor(DEFAULT_TIMING_COLOR)
    -- LibSharedMedia's default font is the game's own, under its name in the client's language.
    config.fontFace = config.fontFace or SharedMedia:GetDefault("font")
    config.fontSize = config.fontSize or DEFAULT_FONT_SIZE
    -- The fastest time of each route, in seconds, by route: flown without Frequent Flier, and with it.
    config.times = config.times or {}
    config.frequentFlierTimes = config.frequentFlierTimes or {}
end

---Puts the bar up or away for the current flight, or stops timing it once nothing shows its time.
local function ApplySettings()
    if IsTiming() then
        RefreshBar()
    else
        StopFlight()
    end
end

---Shows or hides the timer bar, for a flight in progress too. Turning off both it and the tooltips stops the timing.
---@param show boolean
function TwintopQOL.FlightTimer:SetShowBar(show)
    TwintopQOLSaved.flightTimer.showBar = show
    ApplySettings()
end

---Shows or hides flight times on the flight map's tooltips. Turning off both them and the bar stops the timing.
---@param show boolean
function TwintopQOL.FlightTimer:SetShowTooltips(show)
    TwintopQOLSaved.flightTimer.showTooltips = show
    ApplySettings()
end

---Shows the bar's preview while there's no flight, for the options page while it's open.
---@param shown boolean
function TwintopQOL.FlightTimer:SetPreview(shown)
    preview = shown
    RefreshBar()
end

---Redraws the bar after its size, texture, colors, font, or lock change in the settings.
function TwintopQOL.FlightTimer:ApplyAppearance()
    if bar then
        StyleBar()
        RefreshBar()
    end
end

---@return number count The routes with a recorded time, with or without Frequent Flier.
function TwintopQOL.FlightTimer:GetRouteCount()
    local config = TwintopQOLSaved.flightTimer
    local count = 0
    for _ in pairs(config.times) do
        count = count + 1
    end
    for route in pairs(config.frequentFlierTimes) do
        if not config.times[route] then
            count = count + 1
        end
    end
    return count
end

---Forgets every recorded flight time.
function TwintopQOL.FlightTimer:ResetTimes()
    wipe(TwintopQOLSaved.flightTimer.times)
    wipe(TwintopQOLSaved.flightTimer.frequentFlierTimes)
end

---Moves the bar back to its default spot.
function TwintopQOL.FlightTimer:ResetPosition()
    TwintopQOLSaved.flightTimer.point = nil
    if bar then
        PlaceBar()
    end
end
