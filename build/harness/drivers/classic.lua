-- Loads the addon as a talent tab client, Classic Era or The Burning Crusade Classic by the interface number smoke.ps1
-- passes: checks the flavor flags and rank spell table, builds every main window page, and checks the Talents page reads
-- the talent tabs, picks each talent's spell from the table, exports the tab columns, and shows the talent tooltip. Also
-- flies the flight timer through a flight with a stop on the way, and checks the flight master window's tooltips.
local driver = {}
-- Desktop Lua 5.1 libraries, which the workspace's WoW runtime config leaves undefined.
local desktop = _G --[[@as table<string, any>]]
local debug, require = desktop.debug, desktop.require
local taxi = require("taxi")

-- Of the stubs' six talents, these two get a learned rank 2 and an unlearned rank 0; the rest stay at rank 1.
local LEARNED_TALENT = 121
local UNLEARNED_TALENT = 123
-- Rank 1 of talent 134, which differs between the two clients' Talent tables.
local CLASSIC_SPELL_134 = 12165
local TBC_SPELL_134 = 29888

local talentQueries = 0
local tooltipTalents = {}

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

---The first harness frame matching a predicate.
---@param predicate fun(frame: table): boolean
---@return table?
local function FindFrame(predicate)
	for _, frame in ipairs((_G --[[@as table<string, any>]]).__harness.frames) do
		if predicate(frame) then
			return frame
		end
	end
	return nil
end

function driver.afterInstall()
	local G = _G --[[@as table<string, any>]]
	taxi.Install()
	local getTalentInfo = G.C_SpecializationInfo.GetTalentInfo
	G.C_SpecializationInfo.GetTalentInfo = function(query)
		talentQueries = talentQueries + 1
		assert(query.groupIndex == 1, "expected the active talent group, got " .. tostring(query.groupIndex))
		local info = getTalentInfo(query)
		if info.talentID == LEARNED_TALENT then
			info.rank = 2
		elseif info.talentID == UNLEARNED_TALENT then
			info.rank = 0
		end
		return info
	end
	G.GameTooltip.SetTalent = function(_, talentId)
		tooltipTalents[#tooltipTalents + 1] = talentId
	end
end

function driver.afterEvents(ctx)
	local ns = ctx.ns
	local L = ns.Localization
	local failures = 0
	local isTbc = select(4, GetBuildInfo()) >= 20000

	failures = failures + Check("detects " .. (isTbc and "TBC" or "Classic Era"), function()
		assert(ns.IsClassicEra == not isTbc, "IsClassicEra is " .. tostring(ns.IsClassicEra))
		assert(ns.IsTBC == isTbc, "IsTBC is " .. tostring(ns.IsTBC))
		assert(not ns.IsForever, "IsForever is set")
	end)

	failures = failures + Check("loads this client's rank spell table", function()
		local ranks = assert(ns.TalentRankSpells, "TalentRankSpells is missing")
		local expected = isTbc and TBC_SPELL_134 or CLASSIC_SPELL_134
		assert(ranks[134] and ranks[134][1] == expected, "talent 134's rank 1 is " .. tostring(ranks[134] and ranks[134][1]))
	end)

	for _, key in ipairs({ "generalGeneral", "generalFlightTimer", "jokesConfig", "jokesList", "talents", "about" }) do
		failures = failures + Check("page " .. key, function()
			ns.Window:Show(key)
		end)
	end

	-- The stub Show doesn't run OnShow, so learning a talent with the page showing triggers the rescan.
	ns.Window:Show("talents")
	talentQueries = 0
	failures = failures + ctx.stubs.fireEvents("PLAYER_TALENT_UPDATE", ctx.addonName)
	failures = failures + Check("Talents reads every talent tab", function()
		assert(talentQueries == 6, "expected 6 talent queries, got " .. talentQueries)
	end)

	failures = failures + Check("Talents exports the tab columns and rank spells", function()
		local exportButton = assert(FindFrame(function(frame)
			return frame.__type == "Button" and frame.__text == L["TalentsExport"] and frame.__scripts.OnClick ~= nil
		end), "no Export button")
		exportButton.__scripts.OnClick(exportButton, "LeftButton")
		local text = (_G --[[@as table<string, any>]]).TwintopQOLTalentsExportFrame.editBox:GetText()
		assert(text:find(L["TalentsColumnTalentId"], 1, true), "no Talent ID column")
		assert(not text:find(L["TalentsColumnEntryId"], 1, true), "has the trait tree Entry ID column")
		local learned = "\t" .. ns.TalentRankSpells[LEARNED_TALENT][2] .. "\t" .. LEARNED_TALENT .. "\t"
		assert(text:find(learned, 1, true), "talent " .. LEARNED_TALENT .. " doesn't show its rank 2 spell")
		local unlearned = "\t" .. ns.TalentRankSpells[UNLEARNED_TALENT][1] .. "\t" .. UNLEARNED_TALENT .. "\t"
		assert(text:find(unlearned, 1, true), "talent " .. UNLEARNED_TALENT .. " doesn't show its rank 1 spell")
	end)

	failures = failures + Check("Talents shows the talent tooltip", function()
		local row = assert(FindFrame(function(frame) return rawget(frame, "talentId") == LEARNED_TALENT end), "no row for talent " .. LEARNED_TALENT)
		row.__scripts.OnEnter(row)
		assert(tooltipTalents[#tooltipTalents] == LEARNED_TALENT, "SetTalent got " .. tostring(tooltipTalents[#tooltipTalents]))
	end)

	-- A 40-player raid wipe, with wipe jokes on.
	_G.TwintopQOLSaved.jokesConfig.enabled = true
	failures = failures + ctx.stubs.fireEvents("ENCOUNTER_END:1;Boss;9;40;0", ctx.addonName)

	-- The flight timer, turned on.
	ns.FlightTimer:SetShowBar(true)
	ns.FlightTimer:SetShowTooltips(true)

	failures = failures + Check("flight timer times a flight with a stop", function()
		taxi.Fly(taxi.TWO_HOPS, 45)
		local recorded = _G.TwintopQOLSaved.flightTimer.times[taxi.TWO_HOPS_ROUTE]
		assert(recorded == 45, "recorded " .. tostring(recorded))
	end)

	failures = failures + Check("flight master tooltips show a route's time", function()
		local text = taxi.HoverButton(taxi.TWO_HOPS)
		assert(text:find("Menethil Harbor", 1, true) and text:find("Flight time: 0:45", 1, true), "the tooltip reads " .. text)
		text = taxi.HoverButton(taxi.DIRECT)
		assert(not text:find("Flight time", 1, true), "an untimed route has a time: " .. text)
	end)

	return failures
end

return driver
