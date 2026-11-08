-- Builds every main window page, clicks the General and Jokes Configuration settings, runs every slash command, tells
-- jokes in each channel /tqol joke takes, and flies the flight timer through new, timed, estimated, interrupted, and missed flights, checking the flight map's
-- tooltips along the way and the bar and tooltips each turned off. Then sets the timer bar's lock, size, texture,
-- font, and colors, watching its preview.
local driver = {}
-- Desktop Lua 5.1 libraries, which the workspace's WoW runtime config leaves undefined.
local desktop = _G --[[@as table<string, any>]]
local debug, require = desktop.debug, desktop.require
local taxi = require("taxi")

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

function driver.afterInstall()
	local G = _G --[[@as table<string, any>]]
	taxi.Install()
	-- Dropdowns keep their menu's generator, which the stubs drop, so a check can list and pick their choices.
	local createFrame = G.CreateFrame
	G.CreateFrame = function(frameType, ...)
		local frame = createFrame(frameType, ...)
		if frameType == "DropdownButton" then
			frame.SetupMenu = function(self, generator) self.__generator = generator end
		end
		return frame
	end
end

---Runs a dropdown's menu generator, as opening it does.
---@param dropdown table
---@return table<string, table> radios Each radio by its text: its isSelected, setSelected, data, and initializer.
local function GetRadios(dropdown)
	local radios = {}
	local root = { SetScrollMode = function() end }
	function root:CreateRadio(text, isSelected, setSelected, data)
		local radio = { isSelected = isSelected, setSelected = setSelected, data = data }
		function radio:AddInitializer(initializer) self.initializer = initializer end
		radios[text] = radio
		return radio
	end
	dropdown.__generator(dropdown, root)
	return radios
end

---Flies the flight timer through a run of flights, checking what it shows and what it records.
---@param ctx table The driver context.
---@return number failures
local function CheckFlightTimer(ctx)
	local ns = ctx.ns
	local flightTimer = _G.TwintopQOLSaved.flightTimer
	local times = flightTimer.times
	local failures = 0

	failures = failures + Check("flight timer is off until turned on", function()
		assert(flightTimer.showBar == false and flightTimer.showTooltips == false, "the bar or the tooltips start on")
		taxi.Fly(taxi.DIRECT, 60, function(elapsed)
			if elapsed == 20 then
				local bar = taxi.GetBar()
				assert(flightTimer.inFlight == nil and not (bar and bar:IsShown()), "timing a flight before it's turned on")
			end
		end)
		assert(times[taxi.DIRECT_ROUTE] == nil, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
	end)

	failures = failures + Check("flight timer checkboxes turn it on", function()
		ns.Window:Show("generalFlightTimer")
		for _, name in ipairs({ "TwintopQOLFlightTimerShowBar", "TwintopQOLFlightTimerShowTooltips" }) do
			local checkbox = _G[name]
			checkbox.GetChecked = function() return true end
			Click(name)
			-- Back to the stubs' GetChecked, which reads unchecked, so a click turns it off again.
			checkbox.GetChecked = nil
		end
		assert(flightTimer.showBar == true and flightTimer.showTooltips == true, "the bar is " .. tostring(flightTimer.showBar) .. ", the tooltips " .. tostring(flightTimer.showTooltips))
	end)

	failures = failures + Check("flight map tooltips wait for a time", function()
		taxi.LoadFlightMap()
		for _, slot in ipairs({ taxi.DIRECT, taxi.TWO_HOPS }) do
			local text = taxi.HoverPin(slot)
			assert(text:find("Ironforge", 1, true) or text:find("Menethil", 1, true), "the tooltip reads " .. text)
			assert(not text:find("Flight time", 1, true), "slot " .. slot .. " has a time before any flight: " .. text)
		end
	end)

	failures = failures + Check("flight timer times a new route", function()
		taxi.Fly(taxi.DIRECT, 60, function(elapsed)
			if elapsed == 20 then
				local text = taxi.GetBarText()
				assert(text:find("0:20", 1, true) and text:find("Timing flight to Ironforge", 1, true), "the bar reads " .. text)
			end
		end)
		assert(times[taxi.DIRECT_ROUTE] == 60, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
		assert(not taxi.GetBar():IsShown(), "the bar is still up after landing")
		assert(flightTimer.inFlight == nil, "the landed flight is still saved")
	end)

	failures = failures + Check("flight timer keeps the fastest time", function()
		taxi.Fly(taxi.DIRECT, 70)
		assert(times[taxi.DIRECT_ROUTE] == 60, "a slower flight replaced it: " .. tostring(times[taxi.DIRECT_ROUTE]))
		taxi.Fly(taxi.DIRECT, 55)
		assert(times[taxi.DIRECT_ROUTE] == 55, "a faster flight didn't replace it: " .. tostring(times[taxi.DIRECT_ROUTE]))
	end)

	failures = failures + Check("flight timer counts down a timed route", function()
		taxi.Fly(taxi.DIRECT, 55, function(elapsed)
			if elapsed == 20 then
				local text = taxi.GetBarText()
				assert(text:find("0:35", 1, true) and text:find("Ironforge", 1, true) and not text:find("Timing", 1, true), "the bar reads " .. text)
				assert(flightTimer.inFlight and flightTimer.inFlight.route == taxi.DIRECT_ROUTE, "the flight isn't saved for a reload")
			end
		end)
	end)

	failures = failures + Check("flight map tooltips show a route's time", function()
		local text = taxi.HoverPin(taxi.DIRECT)
		assert(text:find("Flight time: 0:55", 1, true) and not text:find("~", 1, true), "the tooltip reads " .. text)
		text = taxi.HoverPin(1)
		assert(not text:find("Flight time", 1, true), "the flight point you're at has a time: " .. text)
	end)

	failures = failures + Check("flight timer estimates a route from its legs", function()
		local text = taxi.HoverPin(taxi.TWO_HOPS)
		assert(not text:find("Flight time", 1, true), "estimated with a leg untimed: " .. text)
		times[taxi.SECOND_LEG_ROUTE] = 30
		text = taxi.HoverPin(taxi.TWO_HOPS)
		assert(text:find("Flight time: ~1:25", 1, true), "the tooltip reads " .. text)
	end)

	failures = failures + Check("flight timer files a route by its stops", function()
		taxi.Fly(taxi.TWO_HOPS, 90, function(elapsed)
			if elapsed == 5 then
				local text = taxi.GetBarText()
				assert(text:find("~1:20", 1, true) and text:find("Menethil Harbor", 1, true), "the bar reads " .. text)
			end
		end)
		assert(times[taxi.TWO_HOPS_ROUTE] == 90, "recorded " .. tostring(times[taxi.TWO_HOPS_ROUTE]))
		local text = taxi.HoverPin(taxi.TWO_HOPS)
		assert(text:find("Flight time: 1:30", 1, true) and not text:find("~", 1, true), "the tooltip reads " .. text)
	end)

	failures = failures + Check("flight timer drops a flight cut short", function()
		taxi.Fly(taxi.TWO_HOPS, 30, function(elapsed)
			if elapsed == 10 then
				TaxiRequestEarlyLanding()
			end
		end)
		assert(times[taxi.TWO_HOPS_ROUTE] == 90, "recorded the early landing: " .. tostring(times[taxi.TWO_HOPS_ROUTE]))
	end)

	failures = failures + Check("flight timer gives up on a flight never taken", function()
		taxi.MissFlight(taxi.DIRECT)
		assert(not taxi.GetBar():IsShown(), "the bar is still up")
		assert(times[taxi.DIRECT_ROUTE] == 55, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
	end)

	failures = failures + Check("flight timer times flights with the bar off", function()
		ns.Window:Show("generalFlightTimer")
		Click("TwintopQOLFlightTimerShowBar")
		assert(flightTimer.showBar == false, "the checkbox didn't turn the bar off")
		taxi.Fly(taxi.DIRECT, 50, function(elapsed)
			if elapsed == 10 then
				assert(not taxi.GetBar():IsShown(), "the bar shows while off")
			end
		end)
		assert(times[taxi.DIRECT_ROUTE] == 50, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
		local text = taxi.HoverPin(taxi.DIRECT)
		assert(text:find("Flight time: 0:50", 1, true), "the tooltip reads " .. text)
	end)

	failures = failures + Check("flight timer shows the bar turned on mid-flight", function()
		taxi.Fly(taxi.DIRECT, 50, function(elapsed)
			if elapsed == 10 then
				ns.FlightTimer:SetShowBar(true)
			elseif elapsed == 11 then
				local text = taxi.GetBarText()
				assert(taxi.GetBar():IsShown() and text:find("0:39", 1, true), "the bar reads " .. text)
			end
		end)
	end)

	failures = failures + Check("flight timer times flights with the tooltips off", function()
		Click("TwintopQOLFlightTimerShowTooltips")
		assert(flightTimer.showTooltips == false, "the checkbox didn't turn the tooltips off")
		local text = taxi.HoverPin(taxi.DIRECT)
		assert(not text:find("Flight time", 1, true), "the tooltip has a time while off: " .. text)
		taxi.Fly(taxi.DIRECT, 45)
		assert(times[taxi.DIRECT_ROUTE] == 45, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
	end)

	failures = failures + Check("flight timer stops with both off", function()
		taxi.Fly(taxi.DIRECT, 40, function(elapsed)
			if elapsed == 10 then
				Click("TwintopQOLFlightTimerShowBar")
				assert(not taxi.GetBar():IsShown(), "the bar is still up")
				assert(flightTimer.inFlight == nil, "the flight is still followed")
			end
		end)
		taxi.Fly(taxi.DIRECT, 40, function(elapsed)
			if elapsed == 10 then
				assert(flightTimer.inFlight == nil and not taxi.GetBar():IsShown(), "timing a flight with both off")
			end
		end)
		assert(times[taxi.DIRECT_ROUTE] == 45, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
	end)

	failures = failures + Check("Flight Timer page", function()
		ns.FlightTimer:SetShowBar(true)
		ns.FlightTimer:SetShowTooltips(true)
		Click("TwintopQOLFlightTimerResetPosition")
		Click("TwintopQOLFlightTimerResetTimes")
		StaticPopupDialogs.TWINTOPQOL_FLIGHT_TIMES_RESET.OnAccept()
		assert(ns.FlightTimer:GetRouteCount() == 0, "times are left after the reset")
	end)

	failures = failures + Check("flight timer leaves a loading screen out", function()
		taxi.Fly(taxi.DIRECT, 40, function(elapsed)
			if elapsed == 10 then
				assert(ctx.stubs.fireEvents("PLAYER_LEAVING_WORLD", ctx.addonName) == 0, "PLAYER_LEAVING_WORLD failed")
				taxi.Wait(15)
				assert(ctx.stubs.fireEvents("PLAYER_ENTERING_WORLD", ctx.addonName) == 0, "PLAYER_ENTERING_WORLD failed")
			end
		end)
		assert(times[taxi.DIRECT_ROUTE] == 40, "recorded " .. tostring(times[taxi.DIRECT_ROUTE]))
	end)

	return failures
end

---Sets the timer bar's lock, size, texture, font, and colors from the Flight Timer page, watching the bar's preview.
---@param ctx table The driver context.
---@return number failures
local function CheckTimerBar(ctx)
	local ns = ctx.ns
	local G = _G --[[@as table<string, any>]]
	local flightTimer = G.TwintopQOLSaved.flightTimer
	ns.Window:Show("generalFlightTimer")
	-- The stub Show doesn't run OnShow, so the checks run the page's.
	local panel = G.TwintopQOLFlightTimerShowBar.__parent
	local failures = 0

	failures = failures + Check("timer bar previews while its page is open", function()
		panel.__scripts.OnShow(panel)
		local text = taxi.GetBarText()
		assert(taxi.GetBar():IsShown() and text:find("Preview: drag to move", 1, true), "the bar reads " .. text)
		assert(taxi.GetBarColor() == "0.2,0.55,0.9", "the bar's color is " .. taxi.GetBarColor())
		assert(taxi.GetBarTexture() == "Interface\\TargetingFrame\\UI-StatusBar", "the bar's texture is " .. tostring(taxi.GetBarTexture()))
		taxi.Fly(taxi.DIRECT, 40, function(elapsed)
			if elapsed == 10 then
				text = taxi.GetBarText()
				assert(text:find("Ironforge", 1, true), "mid-flight, the bar reads " .. text)
			end
		end)
		text = taxi.GetBarText()
		assert(taxi.GetBar():IsShown() and text:find("Preview", 1, true), "after landing, the bar reads " .. text)
		ns.FlightTimer:SetShowBar(false)
		assert(not taxi.GetBar():IsShown(), "the preview shows with the bar off")
		ns.FlightTimer:SetShowBar(true)
		panel.__scripts.OnHide(panel)
		assert(not taxi.GetBar():IsShown(), "the preview stays up after the page closes")
		panel.__scripts.OnShow(panel)
	end)

	failures = failures + Check("timer bar resizes", function()
		local width, height = G.TwintopQOLFlightTimerWidth, G.TwintopQOLFlightTimerHeight
		width.__scripts.OnValueChanged(width, 300)
		height.__scripts.OnValueChanged(height, 30)
		assert(flightTimer.width == 300 and flightTimer.height == 30, "saved " .. flightTimer.width .. "x" .. flightTimer.height)
		local bar = assert(taxi.GetBar(), "no bar")
		assert(bar:GetWidth() == 302 and bar:GetHeight() == 32, "the bar is " .. bar:GetWidth() .. "x" .. bar:GetHeight())
		-- A typed value is kept to the slider's range.
		width.EditBox:SetText("1000")
		width.EditBox.__scripts.OnEnterPressed(width.EditBox)
		assert(width:GetValue() == 600, "typing 1000 set the slider to " .. width:GetValue())
	end)

	failures = failures + Check("timer bar locks", function()
		local bar = assert(taxi.GetBar(), "no bar")
		bar.EnableMouse = function(self, enabled) self.__mouse = enabled end
		local checked = true
		G.TwintopQOLFlightTimerLock.GetChecked = function() return checked end
		Click("TwintopQOLFlightTimerLock")
		assert(flightTimer.locked == true and bar.__mouse == false, "locked is " .. tostring(flightTimer.locked) .. ", mouse " .. tostring(bar.__mouse))
		assert(taxi.GetBarText():find("Preview: locked", 1, true), "the bar reads " .. taxi.GetBarText())
		checked = false
		Click("TwintopQOLFlightTimerLock")
		assert(flightTimer.locked == false and bar.__mouse == true, "locked is " .. tostring(flightTimer.locked) .. ", mouse " .. tostring(bar.__mouse))
	end)

	failures = failures + Check("timer bar takes a LibSharedMedia texture", function()
		local radios = GetRadios(G.TwintopQOLFlightTimerTexture)
		assert(radios.Blizzard and radios.Solid, "the dropdown lists no Blizzard or Solid texture")
		assert(radios.Blizzard.isSelected(radios.Blizzard.data) and not radios.Solid.isSelected(radios.Solid.data), "the saved texture isn't the one checked")
		-- Each row draws its texture behind its name.
		local button = CreateFrame("Button")
		button.fontString = button:CreateFontString()
		button.fontString.GetUnboundedStringWidth = function() return 60 end
		button.AttachTexture = function(self) return self:CreateTexture() end
		local rowWidth, rowHeight = radios.Solid.initializer(button)
		assert(rowWidth == 61 and rowHeight == 20, "the row is " .. tostring(rowWidth) .. "x" .. tostring(rowHeight))
		radios.Solid.setSelected(radios.Solid.data)
		assert(flightTimer.texture == "Solid", "saved " .. tostring(flightTimer.texture))
		assert(taxi.GetBarTexture() == "Interface\\Buttons\\WHITE8X8", "the bar's texture is " .. tostring(taxi.GetBarTexture()))
	end)

	failures = failures + Check("timer bar picks up a texture registered late", function()
		flightTimer.texture = "Late"
		ns.FlightTimer:ApplyAppearance()
		assert(taxi.GetBarTexture() == "Interface\\TargetingFrame\\UI-StatusBar", "an unregistered texture drew " .. tostring(taxi.GetBarTexture()))
		LibStub("LibSharedMedia-3.0"):Register("statusbar", "Late", "Interface\\Late")
		assert(taxi.GetBarTexture() == "Interface\\Late", "after it registered, the bar drew " .. tostring(taxi.GetBarTexture()))
	end)

	failures = failures + Check("timer bar takes a LibSharedMedia font and size", function()
		assert(taxi.GetBarFont() == "Fonts\\FRIZQT__.TTF,10", "the bar's font is " .. taxi.GetBarFont())
		LibStub("LibSharedMedia-3.0"):Register("font", "Driver Font", "Fonts\\Driver.ttf")
		local radios = GetRadios(G.TwintopQOLFlightTimerFont)
		local default, driverFont = radios["Friz Quadrata TT"], radios["Driver Font"]
		assert(default and driverFont, "the dropdown lists no Friz Quadrata TT or Driver Font")
		assert(default.isSelected(default.data) and not driverFont.isSelected(driverFont.data), "the saved font isn't the one checked")
		-- Each row writes its name in its font, at the menu's size, and fits the name to it.
		local button = CreateFrame("Button")
		local fontString = button:CreateFontString() --[[@as table]]
		button.fontString = fontString
		fontString:SetText("Driver Font")
		fontString.SetFont = function(self, path, size) self.__font = path .. "," .. size end
		fontString.SetTextToFit = function(self, text) self.__fitted = text end
		local rowWidth = driverFont.initializer(button)
		assert(fontString.__font == "Fonts\\Driver.ttf,12" and fontString.__fitted == "Driver Font",
			"the row's font is " .. tostring(fontString.__font) .. ", fitted to " .. tostring(fontString.__fitted))
		assert(rowWidth == nil, "the row sized itself, to " .. tostring(rowWidth))
		driverFont.setSelected(driverFont.data)
		assert(flightTimer.fontFace == "Driver Font", "saved " .. tostring(flightTimer.fontFace))
		assert(taxi.GetBarFont() == "Fonts\\Driver.ttf,10", "the bar's font is " .. taxi.GetBarFont())

		local fontSize = G.TwintopQOLFlightTimerFontSize
		fontSize.__scripts.OnValueChanged(fontSize, 16)
		assert(flightTimer.fontSize == 16, "saved the font size as " .. tostring(flightTimer.fontSize))
		assert(taxi.GetBarFont() == "Fonts\\Driver.ttf,16", "the bar's font is " .. taxi.GetBarFont())
	end)

	failures = failures + Check("timer bar picks up a font registered late", function()
		flightTimer.fontFace = "Late Font"
		ns.FlightTimer:ApplyAppearance()
		assert(taxi.GetBarFont() == "Fonts\\FRIZQT__.TTF,16", "an unregistered font drew " .. taxi.GetBarFont())
		LibStub("LibSharedMedia-3.0"):Register("font", "Late Font", "Fonts\\Late.ttf")
		assert(taxi.GetBarFont() == "Fonts\\Late.ttf,16", "after it registered, the bar drew " .. taxi.GetBarFont())
	end)

	failures = failures + Check("timer bar colors", function()
		local picker = G.ColorPickerFrame
		local info
		local picked = { 1, 0, 0 }
		picker.SetupColorPickerAndShow = function(_, shown) info = shown end
		picker.GetColorRGB = function() return picked[1], picked[2], picked[3] end
		local swatch = G.TwintopQOLFlightTimerColor
		swatch.__scripts.OnClick(swatch)
		assert(info and info.r == 0.2 and not info.hasOpacity, "the picker opened on " .. tostring(info and info.r))
		info.swatchFunc()
		assert(taxi.GetBarColor() == "1,0,0", "picking red made the bar " .. taxi.GetBarColor())
		info.cancelFunc({ r = 0.2, g = 0.55, b = 0.9 })
		assert(taxi.GetBarColor() == "0.2,0.55,0.9", "canceling made the bar " .. taxi.GetBarColor())
		info.swatchFunc()

		local timingSwatch = G.TwintopQOLFlightTimerTimingColor
		picked = { 0, 1, 0 }
		timingSwatch.__scripts.OnClick(timingSwatch)
		info.swatchFunc()
		local color = flightTimer.timingColor
		assert(color.r == 0 and color.g == 1 and color.b == 0, "saved the timing color as " .. color.r .. "," .. color.g .. "," .. color.b)
		-- The route through the second flight point has no time, and neither does its second leg.
		taxi.Fly(taxi.TWO_HOPS, 30, function(elapsed)
			if elapsed == 5 then
				assert(taxi.GetBarColor() == "0,1,0", "timing a new route, the bar is " .. taxi.GetBarColor())
			end
		end)
		taxi.Fly(taxi.DIRECT, 40, function(elapsed)
			if elapsed == 5 then
				assert(taxi.GetBarColor() == "1,0,0", "on a timed route, the bar is " .. taxi.GetBarColor())
			end
		end)
		panel.__scripts.OnHide(panel)
	end)

	return failures
end

---Tells jokes with /tqol joke and a channel, solo and in each kind of group, checking where each one goes.
---@param ctx table The driver context.
---@return number failures
local function CheckJokeChannels(ctx)
	local G = _G --[[@as table<string, any>]]
	local ns = ctx.ns
	local failures = 0
	local isInGroup, isInRaid, isInGuild, print = G.IsInGroup, G.IsInRaid, G.IsInGuild, ns.Print
	local sent, printed = {}, {}
	G.C_ChatInfo.SendChatMessage = function(message, channel, _, target)
		sent[#sent + 1] = { message = message, channel = channel, target = target }
	end
	ns.Print = function(_, message) printed[#printed + 1] = message end

	-- Puts the player in a home or instance group, as a party or a raid. No category leaves every group.
	local function Join(category, raid)
		local function InCategory(c) return category ~= nil and (c == nil or c == category) end
		G.IsInGroup = InCategory
		G.IsInRaid = function(c) return raid == true and InCategory(c) end
	end

	-- Runs a command and checks the one joke it sent, or with no channel, that it sent none and said why.
	local function Expect(command, channel, target)
		sent, printed = {}, {}
		SlashCmdList.TWINTOPQOL(command)
		if channel then
			assert(#sent == 1, command .. " sent " .. #sent .. " jokes")
			assert(sent[1].channel == channel, command .. " went to " .. tostring(sent[1].channel) .. ", not " .. channel)
			assert(sent[1].target == target, command .. " went to " .. tostring(sent[1].target))
			assert(type(sent[1].message) == "string" and sent[1].message ~= "", command .. " sent an empty joke")
			assert(#printed == 0, command .. " printed " .. tostring(printed[1]))
		else
			assert(#sent == 0, command .. " sent a joke to " .. tostring(sent[1] and sent[1].channel))
			assert(#printed == 1, command .. " printed " .. #printed .. " lines")
		end
	end

	failures = failures + Check("/tqol joke <channel> solo", function()
		Join(nil)
		Expect("joke say", "SAY")
		Expect("joke YELL", "YELL")
		Expect("joke e", "EMOTE")
		Expect("joke whisper Bob-Realm", "WHISPER", "Bob-Realm")
		Expect("joke w")
		Expect("joke party")
		Expect("joke raid")
		Expect("joke rw")
		Expect("joke instance")
		Expect("joke guild")
		Expect("joke officer")
		Expect("joke trade")
		sent, printed = {}, {}
		SlashCmdList.TWINTOPQOL("joke")
		assert(#sent == 0 and #printed == 0, "joke did something solo")
	end)

	failures = failures + Check("/tqol joke <channel> in a home party", function()
		Join(G.LE_PARTY_CATEGORY_HOME)
		Expect("joke", "PARTY")
		Expect("joke party", "PARTY")
		Expect("joke instance", "PARTY")
		Expect("joke raid")
	end)

	failures = failures + Check("/tqol joke <channel> in a home raid", function()
		Join(G.LE_PARTY_CATEGORY_HOME, true)
		Expect("joke", "RAID")
		Expect("joke raid", "RAID")
		Expect("joke instance", "RAID")
		Expect("joke party", "PARTY")
		Expect("joke rw", "RAID_WARNING")
	end)

	failures = failures + Check("/tqol joke <channel> in an instance group", function()
		Join(G.LE_PARTY_CATEGORY_INSTANCE)
		Expect("joke", "INSTANCE_CHAT")
		Expect("joke party", "INSTANCE_CHAT")
		Expect("joke instance", "INSTANCE_CHAT")
		Expect("joke raid")
		Join(G.LE_PARTY_CATEGORY_INSTANCE, true)
		Expect("joke raid", "INSTANCE_CHAT")
	end)

	failures = failures + Check("/tqol joke <channel> in a guild", function()
		Join(nil)
		G.IsInGuild = function() return true end
		Expect("joke guild", "GUILD")
		Expect("joke o", "OFFICER")
	end)

	G.IsInGroup, G.IsInRaid, G.IsInGuild, ns.Print = isInGroup, isInRaid, isInGuild, print
	G.C_ChatInfo.SendChatMessage = nil
	return failures
end

function driver.afterEvents(ctx)
	local ns = ctx.ns
	local failures = 0

	for _, key in ipairs({ "generalGeneral", "generalFlightTimer", "jokesConfig", "jokesList", "talents", "about" }) do
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
	failures = failures + CheckJokeChannels(ctx)

	-- A Mythic raid wipe, with wipe jokes on.
	_G.TwintopQOLSaved.jokesConfig.enabled = true
	failures = failures + ctx.stubs.fireEvents("ENCOUNTER_END:1;Boss;16;20;0", ctx.addonName)

	-- Answering Ready to a ready check, with the response on.
	_G.TwintopQOLSaved.readyCheck.enabled = true
	failures = failures + ctx.stubs.fireEvents("READY_CHECK_CONFIRM:player;1", ctx.addonName)

	failures = failures + CheckFlightTimer(ctx)
	failures = failures + CheckTimerBar(ctx)

	return failures
end

return driver
