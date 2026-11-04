-- Smoke-load harness: loads a WoW addon's TOC file list in order under stubbed APIs.
-- Usage: lua5.1 load.lua <addonDir> <tocRelPath> [classId] [fireEvents]
local addonDir, tocRel, classIdArg, fireEvents = ...
-- Desktop Lua 5.1 libraries, which the workspace's WoW runtime config leaves undefined.
local desktop = _G --[[@as table<string, any>]]
local os, io, debug, package, require, loadfile = desktop.os, desktop.io, desktop.debug, desktop.package, desktop.require, desktop.loadfile
assert(addonDir and tocRel, "usage: load.lua <addonDir> <tocRelPath> [classId] [fireEvents]")
local classId = tonumber(classIdArg) or 5
local harnessDir = arg[0]:match("^(.*)[/\\]") or "."
package.path = harnessDir .. "/?.lua;" .. package.path

-- Optional driver: TQOL_DRIVER names a Lua file returning hooks that run after the stubs install, after the files load,
-- and after the events (see README.md).
local driver = nil
local driverPath = os.getenv("TQOL_DRIVER")
if driverPath and driverPath ~= "" then
	driver = assert(loadfile(driverPath))()
end

local function normalize(p)
	p = p:gsub("\\", "/")
	return p
end

local function dirname(p)
	return p:match("^(.*)/[^/]*$") or "."
end

-- Parse TOC metadata and file list
local tocPath = normalize(addonDir .. "/" .. tocRel)
local metadata = {}
local files = {}

local function readFile(path)
	local f, err = io.open(path, "rb")
	if not f then return nil, err end
	local s = f:read("*a")
	f:close()
	-- strip UTF-8 BOM
	if s:sub(1, 3) == "\239\187\191" then s = s:sub(4) end
	return s
end

local function addXml(xmlPath)
	local content = assert(readFile(xmlPath), "cannot read " .. xmlPath)
	local base = dirname(xmlPath)
	-- Strip XML comments
	content = content:gsub("<!%-%-.-%-%->", "")
	for tag, attrs in content:gmatch("<(%a+)%s+([^>]-)/?>") do
		if tag == "Script" or tag == "Include" then
			local file = attrs:match('file%s*=%s*"([^"]+)"')
			if file then
				local full = normalize(base .. "/" .. file)
				if full:lower():match("%.xml$") then
					addXml(full)
				else
					files[#files + 1] = full
				end
			end
		end
	end
end

do
	local content = assert(readFile(tocPath), "cannot read " .. tocPath)
	for line in content:gmatch("[^\r\n]+") do
		local key, value = line:match("^##%s*([%w%-]+):%s*(.-)%s*$")
		if key then
			metadata[key] = value
		elseif not line:match("^#") and line:match("%S") then
			local rel = line:match("^%s*(.-)%s*$")
			local full = normalize(addonDir .. "/" .. rel)
			if full:lower():match("%.xml$") then
				addXml(full)
			else
				files[#files + 1] = full
			end
		end
	end
end

-- Optional interface number: TQOL_INTERFACE loads the TOC as that flavor's client would, since one TOC lists them all.
local interfaceOverride = os.getenv("TQOL_INTERFACE")
if interfaceOverride and interfaceOverride ~= "" then
	metadata.Interface = interfaceOverride
end

-- Stubs
local stubs = require("stubs")
-- The addon name is the TOC file name, as the client derives it.
local addonName = tocRel:match("([^/\\]+)%.toc$")
-- Optional saved variables: TQOL_SAVED names a WoW SavedVariables file (assigns the globals it declares).
local savedVariables = nil
local savedPath = os.getenv("TQOL_SAVED")
if savedPath and savedPath ~= "" then
	local chunk = assert(loadfile(savedPath))
	local sandbox = setmetatable({}, { __index = _G })
	setfenv(chunk, sandbox)
	chunk()
	savedVariables = {}
	for name in tostring(metadata.SavedVariables or ""):gmatch("[^,%s]+") do
		if rawget(sandbox, name) ~= nil then savedVariables[name] = sandbox[name] end
	end
end
local env = stubs.install({ addonName = addonName, metadata = metadata, classId = classId, savedVariables = savedVariables })

local ns = {}
local failures = 0
local loaded = 0

local driverContext = { ns = ns, stubs = stubs, addonName = addonName, addonDir = addonDir, tocRel = tocRel, classId = classId, harnessDir = harnessDir }
---Runs one of the driver's hooks; an error, or the failure count afterEvents returns, fails the run.
---@param name "afterInstall"|"afterLoad"|"afterEvents"
local function RunHook(name)
	local hook = driver and driver[name]
	if hook == nil then
		return
	end
	local ok, result = xpcall(function() return hook(driverContext) end, function(e)
		return debug.traceback(tostring(e), 2)
	end)
	if not ok then
		failures = failures + 1
		print("DRIVER ERROR " .. name .. "\n    " .. tostring(result):gsub("\n", "\n    "))
	elseif type(result) == "number" then
		failures = failures + result
	end
end

RunHook("afterInstall")
for _, path in ipairs(files) do
	local rel = path:sub(#normalize(addonDir) + 2)
	local chunk, err = loadfile(path)
	if not chunk then
		failures = failures + 1
		print("SYNTAX  " .. rel .. "\n    " .. tostring(err))
	else
		local ok, rerr = xpcall(function() return chunk(addonName, ns) end, function(e)
			return debug.traceback(tostring(e), 2)
		end)
		if ok then
			loaded = loaded + 1
		else
			failures = failures + 1
			print("ERROR   " .. rel .. "\n    " .. tostring(rerr):gsub("\n", "\n    "))
		end
	end
end
print(string.format("Loaded %d files, %d failures", loaded, failures))
local loadedCleanly = failures == 0
if loadedCleanly then
	RunHook("afterLoad")
end

local timerFailures = 0
if fireEvents and fireEvents ~= "" and failures == 0 then
	local eventFailures
	eventFailures, timerFailures = stubs.fireEvents(fireEvents, addonName)
	failures = failures + eventFailures
end

if loadedCleanly then
	RunHook("afterEvents")
end

if stubs.finish then
	stubs.finish()
end
if timerFailures > 0 then
	print(string.format("Note: %d deferred (C_Timer) callback(s) failed inside stubbed UI code; informational only.", timerFailures))
end
os.exit(failures == 0 and 0 or 1)
