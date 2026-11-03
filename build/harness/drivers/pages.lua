-- Builds every main window page, clicks the General and Jokes Configuration settings, and runs every slash command.
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

	for _, key in ipairs({ "generalGeneral", "jokesConfig", "jokesList", "talents", "about" }) do
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

	failures = failures + Check("General checkbox and response", function()
		ns.Window:Show("generalGeneral")
		Click("TwintopQOLReadyCheckEnabled")
		local responseBox = (_G --[[@as table<string, any>]]).TwintopQOLReadyCheckResponse
		responseBox:SetText("Ready!")
		responseBox.__scripts.OnTextChanged(responseBox, true)
		assert(_G.TwintopQOLSaved.readyCheck.response == "Ready!", "response wasn't saved")
		Click("TwintopQOLReadyCheckEnabled")
	end)

	for _, command in ipairs({ "", "joke", "jokes", "talents", "df", "news", "help" }) do
		failures = failures + Check("/tqol " .. command, function()
			SlashCmdList.TWINTOPQOL(command)
		end)
	end

	-- A Mythic raid wipe, with wipe jokes on.
	_G.TwintopQOLSaved.jokesConfig.enabled = true
	failures = failures + ctx.stubs.fireEvents("ENCOUNTER_END:1;Boss;16;20;0", ctx.addonName)

	-- Answering Ready to a ready check, with the response on.
	_G.TwintopQOLSaved.readyCheck.enabled = true
	failures = failures + ctx.stubs.fireEvents("READY_CHECK_CONFIRM:player;1", ctx.addonName)

	return failures
end

return driver
