-- Loads the addon as the WoW Forever client: checks the Forever-only content types, the Talents page's
-- dual spec config fallback, and builds every main window page.
local driver = {}
-- Desktop Lua 5.1 library, which the workspace's WoW runtime config leaves undefined.
local debug = (_G --[[@as table<string, any>]]).debug

-- Content types the Jokes Configuration page offers on Forever, in order.
local FOREVER_CONTENT_TYPES = { "openWorld", "dungeonNormal", "raidNormal", "battleground" }
local SPEC_GROUP_CONFIG_ID = 42

local specGroupLookups = 0

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

	for _, key in ipairs({ "generalGeneral", "jokesConfig", "jokesList", "talents", "about" }) do
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

	return failures
end

return driver
