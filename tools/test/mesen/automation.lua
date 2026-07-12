-- Mesen automation bridge: load savestates, inject controller input, run frames, read RAM.
-- Launched with: Mesen.exe <rom> automation.lua
-- Commands via MESEN_AUTOMATION_DIR/cmd.txt -> result.txt

local automationDir = os.getenv("MESEN_AUTOMATION_DIR")
if not automationDir or automationDir == "" then
	automationDir = "tools/test/mesen/.automation"
end
automationDir = automationDir:gsub("\\", "/")

local cmdPath = automationDir .. "/cmd.txt"
local resultPath = automationDir .. "/result.txt"

local heldInput = {
	right = false, left = false, up = false, down = false,
	a = false, b = false, start = false, select = false
}
local runFramesLeft = 0
local runFramesTotal = 0
local readySent = false
local bootFrames = 0

local function writeResult(status, extra)
	local lines = { "status=" .. status }
	if extra then
		for k, v in pairs(extra) do
			lines[#lines + 1] = k .. "=" .. tostring(v)
		end
	end
	local f = io.open(resultPath, "w")
	if f then
		f:write(table.concat(lines, "\n"))
		f:close()
	end
end

local function readCmdLines()
	local f = io.open(cmdPath, "r")
	if not f then return nil end
	local lines = {}
	for line in f:lines() do
		if line ~= "" then lines[#lines + 1] = line end
	end
	f:close()
	os.remove(cmdPath)
	return lines
end

local function getSavestatePathForSlot(slot)
	local info = emu.getRomInfo()
	local name = info.name or "RHRv5"
	name = name:gsub("%.smc$", ""):gsub("%.sfc$", ""):gsub("%.fig$", "")
	local home = os.getenv("USERPROFILE") or ""
	return home:gsub("\\", "/") .. "/Documents/Mesen2/SaveStates/" .. name .. "_" .. slot .. ".mss"
end

local function loadStateFile(path)
	local f = io.open(path, "rb")
	if not f then
		return false, "file not found: " .. path
	end
	local data = f:read("*all")
	f:close()
	if not data or #data == 0 then
		return false, "empty savestate"
	end
	local ok = emu.loadSavestate(data)
	if ok then
		return true
	end
	return false, "loadSavestate returned false"
end

local function parseBool(s)
	return s == "1" or s == "true" or s == "yes"
end

local function processCommand(lines)
	if not lines or #lines == 0 then return end
	local cmd = lines[1]:lower()

	if cmd == "load_slot" then
		local slot = tonumber(lines[2] or "1") or 1
		local path = getSavestatePathForSlot(slot)
		local ok, err = loadStateFile(path)
		if ok then
			writeResult("ok", { command = "load_slot", slot = slot, path = path })
		else
			writeResult("error", { command = "load_slot", message = err or "load failed", path = path })
		end
		return
	end

	if cmd == "load_file" then
		local path = lines[2]
		if not path then
			writeResult("error", { command = "load_file", message = "missing path" })
			return
		end
		local ok, err = loadStateFile(path)
		if ok then
			writeResult("ok", { command = "load_file", path = path })
		else
			writeResult("error", { command = "load_file", message = err or "load failed", path = path })
		end
		return
	end

	if cmd == "set_input" then
		for i = 2, #lines do
			local k, v = lines[i]:match("^(%w+)%s+(.+)$")
			if k and heldInput[k] ~= nil then
				heldInput[k] = parseBool(v)
			end
		end
		writeResult("ok", { command = "set_input" })
		return
	end

	if cmd == "clear_input" then
		for k, _ in pairs(heldInput) do heldInput[k] = false end
		writeResult("ok", { command = "clear_input" })
		return
	end

	if cmd == "run_frames" then
		local n = tonumber(lines[2] or "1") or 1
		if n < 1 then n = 1 end
		runFramesTotal = n
		runFramesLeft = n
		emu.resume()
		writeResult("running", { command = "run_frames", frames = n })
		return
	end

	if cmd == "pause" then
		emu.breakExecution()
		writeResult("ok", { command = "pause" })
		return
	end

	if cmd == "read_u16" then
		local addr = tonumber(lines[2] or "0")
		if not addr then
			writeResult("error", { command = "read_u16", message = "bad address" })
			return
		end
		local lo = emu.read(addr, emu.memType.snesMemory)
		local hi = emu.read(addr + 1, emu.memType.snesMemory)
		local value = lo + hi * 256
		writeResult("ok", { command = "read_u16", address = string.format("0x%X", addr), value = value })
		return
	end

	if cmd == "read_u8" then
		local addr = tonumber(lines[2] or "0")
		if not addr then
			writeResult("error", { command = "read_u8", message = "bad address" })
			return
		end
		local value = emu.read(addr, emu.memType.snesMemory)
		writeResult("ok", { command = "read_u8", address = string.format("0x%X", addr), value = value })
		return
	end

	writeResult("error", { command = cmd, message = "unknown command" })
end

emu.addEventCallback(function()
	emu.setInput(heldInput, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
	bootFrames = bootFrames + 1
	if not readySent and bootFrames >= 30 and emu.getRomInfo().name then
		readySent = true
		writeResult("ready", { rom = emu.getRomInfo().name })
	end

	if runFramesLeft > 0 then
		runFramesLeft = runFramesLeft - 1
		if runFramesLeft == 0 then
			emu.breakExecution()
			writeResult("ok", { command = "run_frames", frames = runFramesTotal })
		end
		return
	end

	local lines = readCmdLines()
	if lines then
		processCommand(lines)
	end
end, emu.eventType.startFrame)

writeResult("starting", {})
