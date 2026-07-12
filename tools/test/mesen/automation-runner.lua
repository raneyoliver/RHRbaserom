-- Headless automation runner for Mesen --testrunner mode.
-- Usage: Mesen.exe --testrunner RHRv5.smc automation-runner.lua

local slot = tonumber(os.getenv("MESEN_TEST_SLOT") or "1") or 1
local frames = tonumber(os.getenv("MESEN_TEST_FRAMES") or "5") or 5
local walkRight = (os.getenv("MESEN_TEST_WALK_RIGHT") or "1") == "1"

local outPath = os.getenv("MESEN_TEST_RESULT")
if not outPath or outPath == "" then
	outPath = "C:/Users/Oliver/Documents/Super Mario World/RHRbaserom/tools/test/mesen/.automation/result.txt"
end
outPath = outPath:gsub("\\", "/")

local function writeResult(status, extra)
	local lines = { "status=" .. status }
	if extra then
		for k, v in pairs(extra) do
			lines[#lines + 1] = k .. "=" .. tostring(v)
		end
	end
	local f = io.open(outPath, "w")
	if f then
		f:write(table.concat(lines, "\n"))
		f:close()
	end
end

local function getSavestatePath(s)
	local info = emu.getRomInfo()
	local name = (info.name or "RHRv5"):gsub("%.smc$", ""):gsub("%.sfc$", "")
	local home = os.getenv("USERPROFILE") or ""
	return home:gsub("\\", "/") .. "/Documents/Mesen2/SaveStates/" .. name .. "_" .. s .. ".mss"
end

local function readU16(addr)
	local lo = emu.read(addr, emu.memType.snesMemory)
	local hi = emu.read(addr + 1, emu.memType.snesMemory)
	return lo + hi * 256
end

local heldInput = { right = walkRight, left = false, up = false, down = false, a = false, b = false, start = false, select = false }
local framesLeft = 0
local phase = "load"
local marioBefore = 0

emu.addEventCallback(function()
	emu.setInput(heldInput, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
	if phase == "load" then
		local path = getSavestatePath(slot)
		local f = io.open(path, "rb")
		if not f then
			writeResult("error", { message = "savestate not found", path = path })
			emu.stop(1)
			return
		end
		local data = f:read("*all")
		f:close()
		if not emu.loadSavestate(data) then
			writeResult("error", { message = "loadSavestate failed", path = path })
			emu.stop(1)
			return
		end
		marioBefore = readU16(0x7E0094)
		phase = "run"
		framesLeft = frames
		emu.resume()
		return
	end

	if phase == "run" then
		if framesLeft > 0 then
			framesLeft = framesLeft - 1
			if framesLeft == 0 then
				local marioAfter = readU16(0x7E0094)
				writeResult("ok", {
					mario_x_before = marioBefore,
					mario_x_after = marioAfter,
					delta_x = marioAfter - marioBefore,
					slot = slot,
					frames = frames
				})
				emu.stop(0)
			end
		end
	end
end, emu.eventType.startFrame)

writeResult("starting", {})
