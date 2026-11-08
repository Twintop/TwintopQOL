-- Loads the addon as the WoW Forever client: checks the Forever-only content types, the Talents page's
-- dual spec config fallback, the flight timer's separate Frequent Flier times, and builds every main window page.
local driver = {}
-- Desktop Lua 5.1 libraries, which the workspace's WoW runtime config leaves undefined.
local desktop = _G --[[@as table<string, any>]]
local debug, require = desktop.debug, desktop.require
local taxi = require("taxi")

-- Content types the Jokes Configuration page offers on Forever, in order.
local FOREVER_CONTENT_TYPES = { "openWorld", "dungeonNormal", "raidNormal", "battleground" }
local SPEC_GROUP_CONFIG_ID = 42
-- The Adventure legacy tree, the config it gets here, and its Frequent Flier node.
local LEGACY_ADVENTURE_TREE = 1270
local LEGACY_CONFIG_ID = 77
local FREQUENT_FLIER_NODE = 110300

local specGroupLookups = 0
-- Whether the character has Frequent Flier learned. A check unlearns it, as a respec would.
local frequentFlier = true

---Runs one check and prints PASS or FAIL with the error.
---@param name string
---@param fn function
---@return number failures
local function Check(name, fn)
	local ok, err = xpcall(fn, function(e) return debug.traceback(tostring(e), 2) end)
	if ok then
		print("PASS  " .. name)
		return 0
	end
	print("FAIL  " .. name .. "\n    " .. tostring(err):gsub("\n", "\n    "))
	return 1
end

function driver.afterInstall()
	local G = _G --[[@as table<string, any>]]
	G.WOW_PROJECT_CAMELOT = 18
	G.WOW_PROJECT_ID = G.WOW_PROJECT_CAMELOT
	-- Forever only: the talent config of a dual spec group.
	G.C_SpecializationInfo.GetCombatConfigIDForSpecGroup = function(groupIndex)
		specGroupLookups = specGroupLookups + 1
		assert(groupIndex == 1, "expected the active spec group, got " .. tostring(groupIndex))
		return SPEC_GROUP_CONFIG_ID
	end
	taxi.Install()
	-- Forever only: legacy perks, with Frequent Flier making flights about 20% faster.
	G.Constants = { LegacyConsts = { LEGACY_TREE_ADVENTURE_ID = LEGACY_ADVENTURE_TREE } }
	G.C_Traits.GetConfigIDByTreeID = function(treeId)
		return treeId == LEGACY_ADVENTURE_TREE and LEGACY_CONFIG_ID or nil
	end
	local getNodeInfo = G.C_Traits.GetNodeInfo
	G.C_Traits.GetNodeInfo = function(configId, nodeId)
		if configId == LEGACY_CONFIG_ID and nodeId == FREQUENT_FLIER_NODE then
			return { activeRank = frequentFlier and 1 or 0 }
		end
		return getNodeInfo(configId, nodeId)
	end
end

function driver.afterEvents(ctx)
	local ns = ctx.ns
	local failures = 0

	failures = failures + Check("detects Forever", function()
		assert(ns.IsForever == true, "IsForever is " .. tostring(ns.IsForever))
	end)

	failures = failures + Check("Forever content types", function()
		local actual = table.concat(ns.Jokes.CONTENT_TYPES, ",")
		local expected = table.concat(FOREVER_CONTENT_TYPES, ",")
		assert(actual == expected, "got " .. actual)
	end)

	for _, key in ipairs({ "generalGeneral", "generalFlightTimer", "jokesConfig", "jokesList", "talents", "about" }) do
		failures = failures + Check("page " .. key, function()
			ns.Window:Show(key)
		end)
	end

	failures = failures + Check("no checkboxes for content Forever lacks", function()
		ns.Window:Show("jokesConfig")
		-- rawget: the stubs answer any unknown global.
		for _, contentType in ipairs(FOREVER_CONTENT_TYPES) do
			assert(rawget(_G, "TwintopQOLJokesContent_" .. contentType), contentType .. " checkbox missing")
		end
		assert(rawget(_G, "TwintopQOLJokesContent_raidMythic") == nil, "raidMythic checkbox was created")
	end)

	-- The stub Show doesn't run OnShow, so a dual spec swap with the page showing triggers the rescan.
	ns.Window:Show("talents")
	failures = failures + ctx.stubs.fireEvents("ACTIVE_TALENT_GROUP_CHANGED:1;2", ctx.addonName)
	failures = failures + Check("Talents falls back to the spec group config", function()
		assert(specGroupLookups > 0, "GetCombatConfigIDForSpecGroup was never called")
	end)

	-- A 40-player raid wipe, with wipe jokes on.
	_G.TwintopQOLSaved.jokesConfig.enabled = true
	failures = failures + ctx.stubs.fireEvents("ENCOUNTER_END:1;Boss;9;40;0", ctx.addonName)

	-- The flight timer, turned on.
	ns.FlightTimer:SetShowBar(true)
	ns.FlightTimer:SetShowTooltips(true)
	local flightTimer = _G.TwintopQOLSaved.flightTimer

	failures = failures + Check("flight timer times Frequent Flier flights apart", function()
		taxi.Fly(taxi.DIRECT, 50)
		local recorded = flightTimer.frequentFlierTimes[taxi.DIRECT_ROUTE]
		assert(recorded == 50, "recorded " .. tostring(recorded))
		assert(flightTimer.times[taxi.DIRECT_ROUTE] == nil, "recorded it as a flight without the perk too")
		taxi.Fly(taxi.DIRECT, 50, function(elapsed)
			if elapsed == 10 then
				local text = taxi.GetBarText()
				assert(text:find("0:40", 1, true) and not text:find("~", 1, true), "the bar reads " .. text)
			end
		end)
	end)

	failures = failures + Check("flight timer estimates across a Frequent Flier respec", function()
		frequentFlier = false
		local text = taxi.HoverButton(taxi.DIRECT)
		assert(text:find("Flight time: ~1:00", 1, true), "without the perk, the tooltip reads " .. text)
		taxi.Fly(taxi.DIRECT, 58)
		assert(flightTimer.times[taxi.DIRECT_ROUTE] == 58, "recorded " .. tostring(flightTimer.times[taxi.DIRECT_ROUTE]))
		assert(flightTimer.frequentFlierTimes[taxi.DIRECT_ROUTE] == 50, "changed the Frequent Flier time")
		text = taxi.HoverButton(taxi.DIRECT)
		assert(text:find("Flight time: 0:58", 1, true) and not text:find("~", 1, true), "without the perk, the tooltip reads " .. text)
		frequentFlier = true
		text = taxi.HoverButton(taxi.DIRECT)
		assert(text:find("Flight time: 0:50", 1, true) and not text:find("~", 1, true), "with the perk, the tooltip reads " .. text)
		assert(ns.FlightTimer:GetRouteCount() == 1, "counted " .. ns.FlightTimer:GetRouteCount() .. " routes")
	end)

	return failures
end

return driver
