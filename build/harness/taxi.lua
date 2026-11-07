-- A fake flight master and clock for the drivers that take flights: three flight points, the third reached through the
-- second, helpers that fly the flight timer through a flight frame by frame, and both flight maps' flight point
-- tooltips. See README.md.
local taxi = {}

-- Slot by slot: the node ID, name, and type the flight master gives, and the slot each hop of the route starts from.
local NODES = {
	{ nodeID = 2, name = "Stormwind, Elwynn", type = "CURRENT" },
	{ nodeID = 6, name = "Ironforge, Dun Morogh", type = "REACHABLE", hopSources = { 1 } },
	{ nodeID = 7, name = "Menethil Harbor, Wetlands", type = "REACHABLE", hopSources = { 1, 2 } },
}

-- The slots to fly to, and the routes the flight timer files them under.
taxi.DIRECT = 2
taxi.DIRECT_ROUTE = "2>6"
taxi.TWO_HOPS = 3
taxi.TWO_HOPS_ROUTE = "2>6>7"
-- The second leg of TWO_HOPS, from the second flight point to the third, which this flight master can't fly on its own.
taxi.SECOND_LEG_ROUTE = "6>7"

local now = 1000
local onTaxi = false
-- What GameTooltip holds: the frame it was last set to, and its lines since.
local tooltipOwner
local tooltipLines = {}

---Records what's put on GameTooltip, for the tooltip helpers below to read.
---@param tooltip table
local function InstallTooltip(tooltip)
	tooltip.SetOwner = function(_, owner)
		tooltipOwner = owner
		tooltipLines = {}
	end
	tooltip.GetOwner = function() return tooltipOwner end
	tooltip.AddLine = function(_, text) tooltipLines[#tooltipLines + 1] = text end
end

---Makes status bars keep the color and texture they're given, and their texts the font, which the stubs drop, so the
---bar's look can be read.
---@param G table<string, any>
local function InstallStatusBars(G)
	local createFrame = G.CreateFrame
	G.CreateFrame = function(frameType, ...)
		local frame = createFrame(frameType, ...)
		if frameType == "StatusBar" then
			frame.SetStatusBarColor = function(self, r, g, b) self.__color = { r, g, b } end
			frame.SetStatusBarTexture = function(self, texture) self.__texture = texture end
			local createFontString = frame.CreateFontString
			frame.CreateFontString = function(self, ...)
				local fontString = createFontString(self, ...)
				fontString.SetFont = function(text, path, size) text.__font = path .. "," .. size end
				return fontString
			end
		end
		return frame
	end
end

---Replaces the clock, the player's taxi state, the flight master APIs, and the Classic flight master window's tooltip.
---Call from a driver's afterInstall.
function taxi.Install()
	local G = _G --[[@as table<string, any>]]
	InstallStatusBars(G)
	-- The retail flight map loads on demand, so its pin mixin is missing, not stubbed, until taxi.LoadFlightMap.
	local globalsMeta = getmetatable(G)
	local stubGlobal = globalsMeta.__index
	globalsMeta.__index = function(t, k)
		if k == "FlightMap_FlightPointPinMixin" then
			return nil
		end
		return stubGlobal(t, k)
	end
	InstallTooltip(G.GameTooltip)
	-- What the Classic flight master window's flight point buttons call on mouseover.
	G.TaxiNodeOnButtonEnter = function(button)
		G.GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		G.GameTooltip:AddLine(G.TaxiNodeName(button:GetID()))
		G.GameTooltip:Show()
	end
	G.GetTime = function() return now end
	G.UnitOnTaxi = function(unit) return unit == "player" and onTaxi end
	G.GetMoney = function() return 10000 end
	G.GetTaxiMapID = function() return 1415 end
	G.NumTaxiNodes = function() return #NODES end
	G.TaxiNodeName = function(slot) return NODES[slot].name end
	G.TaxiNodeGetType = function(slot) return NODES[slot].type end
	G.TaxiNodeCost = function() return 50 end
	G.GetNumRoutes = function(slot) return #(NODES[slot].hopSources or {}) end
	-- Each hop ends where the next one starts, and the last ends at the slot itself.
	G.TaxiGetNodeSlot = function(slot, hop, isSource)
		local sources = NODES[slot].hopSources
		if isSource then
			return sources[hop]
		end
		return sources[hop + 1] or slot
	end
	G.C_TaxiMap = {
		GetAllTaxiNodes = function()
			local nodes = {}
			for slot, node in ipairs(NODES) do
				nodes[#nodes + 1] = { slotIndex = slot, nodeID = node.nodeID, name = node.name }
			end
			return nodes
		end,
	}
	G.TakeTaxiNode = function() end
	G.TaxiRequestEarlyLanding = function() end
end

---The flight timer's bar, once the addon has made it.
---@return table?
function taxi.GetBar()
	return rawget(_G, "TwintopQOLFlightTimer")
end

---The bar's StatusBar, which holds its texts.
---@return table?
local function GetStatusBar()
	local bar = taxi.GetBar()
	for _, frame in ipairs((_G --[[@as table<string, any>]]).__harness.frames) do
		if bar and frame.__type == "StatusBar" and frame.__parent == bar then
			return frame
		end
	end
	return nil
end

---Every text on the bar, joined by " | ".
---@return string
function taxi.GetBarText()
	local statusBar = GetStatusBar()
	local texts = {}
	for _, frame in ipairs((_G --[[@as table<string, any>]]).__harness.frames) do
		if statusBar and frame.__type == "FontString" and frame.__parent == statusBar then
			texts[#texts + 1] = frame:GetText()
		end
	end
	return table.concat(texts, " | ")
end

---The bar's fill, which on a timed route is the seconds left.
---@return number
function taxi.GetBarValue()
	local statusBar = GetStatusBar()
	return statusBar and statusBar:GetValue() or 0
end

---The bar's color, as "r,g,b".
---@return string
function taxi.GetBarColor()
	local statusBar = GetStatusBar()
	local color = statusBar and statusBar.__color or {}
	return table.concat(color, ",")
end

---The file the bar's texture was last set to.
---@return string|nil
function taxi.GetBarTexture()
	local statusBar = GetStatusBar()
	return statusBar and statusBar.__texture
end

---The font the bar's texts were last set to, as "path,size", or each text's joined by " | " when they differ.
---@return string
function taxi.GetBarFont()
	local statusBar = GetStatusBar()
	local fonts = {}
	local same = true
	for _, frame in ipairs((_G --[[@as table<string, any>]]).__harness.frames) do
		if statusBar and frame.__type == "FontString" and frame.__parent == statusBar then
			local font = tostring(frame.__font)
			same = same and (#fonts == 0 or font == fonts[1])
			fonts[#fonts + 1] = font
		end
	end
	if same and #fonts > 0 then
		return fonts[1]
	end
	return table.concat(fonts, " | ")
end

---Moves the clock on without drawing a frame, as a loading screen does.
---@param seconds number
function taxi.Wait(seconds)
	now = now + seconds
end

---Moves the clock on and runs the flight timer's OnUpdate, as drawing a frame does while it follows a flight.
---@param seconds number
local function Step(seconds)
	now = now + seconds
	local tracker = rawget(_G, "TwintopQOLFlightTimerTracker")
	if tracker and tracker:IsShown() then
		tracker.__scripts.OnUpdate(tracker, seconds)
	end
end

---Takes the flight to a slot, lifts off half a second later, flies for whole seconds, and lands.
---@param slot number
---@param seconds number
---@param during fun(elapsed: number)|nil Called after each second of the flight.
function taxi.Fly(slot, seconds, during)
	TakeTaxiNode(slot)
	Step(0.5)
	onTaxi = true
	Step(0)
	for elapsed = 1, seconds do
		Step(1)
		if during then
			during(elapsed)
		end
	end
	onTaxi = false
	Step(0)
end

---Loads the retail flight map, a load-on-demand addon: makes its flight point pin mixin and sends ADDON_LOADED for it.
function taxi.LoadFlightMap()
	local G = _G --[[@as table<string, any>]]
	G.FlightMap_FlightPointPinMixin = {
		OnMouseEnter = function(pin)
			G.GameTooltip:SetOwner(pin, "ANCHOR_PRESERVE")
			G.GameTooltip:AddLine(pin.taxiNodeData.name)
			G.GameTooltip:Show()
		end,
	}
	for _, frame in ipairs(G.__harness.frames) do
		local onEvent = frame.__scripts.OnEvent
		if onEvent and frame.__events.ADDON_LOADED then
			onEvent(frame, "ADDON_LOADED", "Blizzard_FlightMap")
		end
	end
end

---Hovers a slot's flight point button on the Classic flight master window.
---@param slot number
---@return string text The tooltip's lines, joined by " | ".
function taxi.HoverButton(slot)
	local button = CreateFrame("Button")
	button:SetID(slot)
	TaxiNodeOnButtonEnter(button)
	return table.concat(tooltipLines, " | ")
end

---Hovers a slot's pin on the retail flight map. Call taxi.LoadFlightMap first.
---@param slot number
---@return string text The tooltip's lines, joined by " | ".
function taxi.HoverPin(slot)
	local G = _G --[[@as table<string, any>]]
	-- The map makes a pin from the mixin as it loads the slot's node.
	local pin = G.Mixin(CreateFrame("Frame"), G.FlightMap_FlightPointPinMixin)
	pin.taxiNodeData = { slotIndex = slot, name = NODES[slot].name }
	pin:OnMouseEnter()
	return table.concat(tooltipLines, " | ")
end

---Takes the flight to a slot and never lifts off, past the flight timer's takeoff timeout.
---@param slot number
function taxi.MissFlight(slot)
	TakeTaxiNode(slot)
	for _ = 1, 6 do
		Step(1)
	end
end

return taxi
