-- Builds every main window page, clicks the Jokes Configuration checkboxes, and runs every slash command.
local driver = {}
-- Desktop Lua 5.1 library, which the workspace's WoW runtime config leaves undefined.
local debug = (_G --[[@as table<string, any>]]).debug

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

---Calls a frame's OnClick script the way a click would.
---@param name string
local function Click(name)
	local frame = assert(_G[name], name .. " was never created")
	local onClick = assert(frame.__scripts.OnClick, name .. " has no OnClick")
	onClick(frame, "LeftButton")
end

function driver.afterEvents(ctx)
	local ns = ctx.ns
	local failures = 0

	for _, key in ipairs({ "jokesConfig", "jokesList", "talents", "about" }) do
		failures = failures + Check("page " .. key, function()
			ns.Window:Show(key)
		end)
	end

	failures = failures + Check("Jokes Configuration checkboxes", function()
		ns.Window:Show("jokesConfig")
		Click("TwintopQOLJokesEnabled")
		Click("TwintopQOLJokesContent_raidMythic")
		Click("TwintopQOLJokesNoRepeats")
		Click("TwintopQOLJokesEnabled")
	end)

	for _, command in ipairs({ "", "joke", "jokes", "talents", "df", "news", "silly on", "silly off", "silly", "help" }) do
		failures = failures + Check("/tqol " .. command, function()
			SlashCmdList.TWINTOPQOL(command)
		end)
	end

	-- A Mythic raid wipe, with wipe jokes on.
	_G.TwintopQOLSaved.jokesConfig.enabled = true
	failures = failures + ctx.stubs.fireEvents("ENCOUNTER_END:1;Boss;16;20;0", ctx.addonName)

	return failures
end

return driver
