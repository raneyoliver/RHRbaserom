# MCP automation extensions for Hoshiruna Mesen2-Expanded DebugPipeServer.cs
#
# These handlers must be merged into UI/Debugger/Utilities/DebugPipeServer.cs
# and Mesen rebuilt. Until then, use automation.lua + run-session.ps1.
#
# Adds MCP tools:
#   load_state_slot   { slot: 1 }
#   load_state_file   { path: "C:/.../state.mss" }
#   set_controller_input { port: 0, right: true, left: false, ... }
#   run_frames        { count: 5 }

@'
// --- Add to tool list (ListTools) ---
tools.Add((JsonNode)MakeToolDef("load_state_slot",
    "Load savestate from Mesen slot file (e.g. slot 1 -> RHRv5_1.mss).",
    new JsonObject { ["type"] = "object", ["required"] = new JsonArray { (JsonNode)"slot" },
        ["properties"] = new JsonObject { ["slot"] = new JsonObject { ["type"] = "integer" } } }));
tools.Add((JsonNode)MakeToolDef("load_state_file",
    "Load savestate from .mss file path.",
    new JsonObject { ["type"] = "object", ["required"] = new JsonArray { (JsonNode)"path" },
        ["properties"] = new JsonObject { ["path"] = new JsonObject { ["type"] = "string" } } }));
tools.Add((JsonNode)MakeToolDef("set_controller_input",
    "Hold controller buttons for player port until cleared.",
    new JsonObject { ["type"] = "object",
        ["properties"] = new JsonObject {
            ["port"] = new JsonObject { ["type"] = "integer", ["default"] = 0 },
            ["right"] = new JsonObject { ["type"] = "boolean" },
            ["left"] = new JsonObject { ["type"] = "boolean" },
            ["up"] = new JsonObject { ["type"] = "boolean" },
            ["down"] = new JsonObject { ["type"] = "boolean" },
            ["a"] = new JsonObject { ["type"] = "boolean" },
            ["b"] = new JsonObject { ["type"] = "boolean" },
            ["start"] = new JsonObject { ["type"] = "boolean" },
            ["select"] = new JsonObject { ["type"] = "boolean" }
        }}));
tools.Add((JsonNode)MakeToolDef("run_frames",
    "Resume emulation for N frames then pause.",
    new JsonObject { ["type"] = "object",
        ["properties"] = new JsonObject { ["count"] = new JsonObject { ["type"] = "integer", ["default"] = 1 } } }));

// --- Add to tools/call switch ---
"load_state_slot" => HandleLoadStateSlot(id, args),
"load_state_file" => HandleLoadStateFile(id, args),
"set_controller_input" => HandleSetControllerInput(id, args),
"run_frames" => HandleRunFrames(id, args),

// --- Handler implementations (uses EmuApi + injected Lua for input) ---
private string HandleLoadStateSlot(JsonNode id, JsonObject? args)
{
    int slot = args?["slot"]?.GetValue<int>() ?? 1;
    EmuApi.LoadState((uint)slot);
    return MakeToolSuccess(id, new JsonObject { ["success"] = true, ["slot"] = slot });
}

private string HandleLoadStateFile(JsonNode id, JsonObject? args)
{
    string? path = args?["path"]?.GetValue<string>();
    if(string.IsNullOrWhiteSpace(path)) return MakeToolError(id, "path required");
    EmuApi.LoadStateFile(path);
    return MakeToolSuccess(id, new JsonObject { ["success"] = true, ["path"] = path });
}

private static string BuildInputLua(JsonObject? args)
{
    static string B(JsonObject? a, string k) => a?[k]?.GetValue<bool?>() == true ? "true" : "false";
    return $"emu.addEventCallback(function() emu.setInput({{right={B(args,"right")},left={B(args,"left")},up={B(args,"up")},down={B(args,"down")},a={B(args,"a")},b={B(args,"b")},start={B(args,"start")},select={B(args,"select")}}}, {args?["port"]?.GetValue<int>() ?? 0}) end, emu.eventType.inputPolled)";
}

private string HandleSetControllerInput(JsonNode id, JsonObject? args)
{
    string lua = BuildInputLua(args);
    DebugApi.LoadScript("mcp_input", ConfigManager.HomeFolder, lua, -1);
    return MakeToolSuccess(id, new JsonObject { ["success"] = true });
}

private string HandleRunFrames(JsonNode id, JsonObject? args)
{
    int count = args?["count"]?.GetValue<int>() ?? 1;
    CpuType cpu = EmuApi.GetRomInfo().ConsoleType.GetMainCpuType();
    DebugApi.ResumeExecution();
    DebugApi.Step(cpu, count, StepType.PpuFrame);
    return MakeToolSuccess(id, new JsonObject { ["success"] = true, ["count"] = count });
}
'@ | Set-Content -Path (Join-Path $PSScriptRoot "mcp-automation-handlers.snippet.cs") -Encoding UTF8

Write-Host "Wrote mcp-automation-handlers.snippet.cs"
Write-Host "Next: merge into Hoshiruna DebugPipeServer.cs and rebuild Mesen.exe"
