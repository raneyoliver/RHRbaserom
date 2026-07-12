local dir = os.getenv("MESEN_AUTOMATION_DIR")
if not dir then dir = "C:/Users/Oliver/Documents/Super Mario World/RHRbaserom/tools/test/mesen/.automation" end
dir = dir:gsub("\\", "/")
local f = io.open(dir .. "/result.txt", "w")
if f then
	f:write("status=ready\nsource=minimal\n")
	f:close()
end
