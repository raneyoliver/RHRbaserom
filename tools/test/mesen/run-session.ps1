# Automated Mesen test session via MCP (patched Mesen2-Expanded).
# SA-1 ROM: player/game RAM in $0000-$1FFF is read at $6000-$7FFF (!addr).
#
# Prereqs:
#   1. Mesen running with RHRv5.smc
#   2. .\start-mcp.ps1
#   3. Mesen: Tools -> MCP Server -> Start
#
# Usage:
#   .\run-session.ps1 -Slot 1 -WalkRight -Frames 20

param(
    [int]$Slot = 1,
    [switch]$WalkRight,
    [switch]$WalkLeft,
    [int]$Frames = 5,
    [switch]$Launch,
    [string]$RomPath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "automation-io.ps1")
. (Join-Path $PSScriptRoot "smw-addrs.ps1")

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$mesenExe = Join-Path $repoRoot "tools\mesen2-expanded\Mesen.exe"

$savestatePath = Join-Path $env:USERPROFILE "Documents\Mesen2\SaveStates\RHRv5_$Slot.mss"
if (-not (Test-Path $savestatePath)) {
    throw "Savestate slot $Slot not found: $savestatePath (save in Mesen to slot $Slot first)"
}

if ($Launch) {
    if (-not $RomPath) {
        $RomPath = Join-Path $repoRoot "workspace\RHRv5.smc"
    }
    if (-not (Test-Path $mesenExe)) { throw "Mesen not found. Run build-mesen-expanded.ps1 or download-mesen-expanded.ps1" }
    if (-not (Test-Path $RomPath)) { throw "ROM not found: $RomPath" }
    Write-Host "Launching Mesen with ROM..."
    Get-Process -Name "Mesen" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    Start-Process -FilePath $mesenExe -ArgumentList "`"$RomPath`""
    Start-Sleep -Seconds 4
    Write-Host "Restart MCP: start-mcp.ps1, then Mesen Tools -> MCP Server -> Start"
} elseif (-not (Get-Process -Name "Mesen" -ErrorAction SilentlyContinue)) {
    throw "Mesen is not running. Open Mesen (or use -Launch to start it with the ROM)."
}

if (-not (Wait-McpPort -TimeoutSec 30)) {
    throw "MCP not available on :51234. Run start-mcp.ps1, then Mesen Tools -> MCP Server -> Start."
}

$tools = Invoke-MesenMcpListTools
$required = @("load_state_slot", "set_controller_input", "run_frames")
$missing = $required | Where-Object { $_ -notin $tools }
if ($missing.Count -gt 0) {
    throw "Patched Mesen required. Missing MCP tools: $($missing -join ', '). Run build-mesen-expanded.ps1 and restart Mesen."
}

function Read-PlayerSnapshot([string]$Label) {
    $xHex = Read-McpHex $SmwAddr.PlayerX 2
    $yHex = Read-McpHex $SmwAddr.PlayerY 2
    $xnHex = Read-McpHex $SmwAddr.PlayerXNext 2
    $xsHex = Read-McpHex $SmwAddr.PlayerXScreen 2
    $snap = [ordered]@{
        Label     = $Label
        X         = Read-McpU16 $SmwAddr.PlayerX
        Y         = Read-McpU16 $SmwAddr.PlayerY
        XNext     = Read-McpU16 $SmwAddr.PlayerXNext
        YNext     = Read-McpU16 $SmwAddr.PlayerYNext
        XScreen   = Read-McpU16 $SmwAddr.PlayerXScreen
        XHex      = $xHex
        YHex      = $yHex
        XNextHex  = $xnHex
        XScreenHex= $xsHex
        GameMode  = [Convert]::ToInt32((Read-McpHex $SmwAddr.GameMode 1).Split(' ')[0], 16)
        Frame     = [Convert]::ToInt32((Read-McpHex $SmwAddr.FrameCounter 1).Split(' ')[0], 16)
        Ctrl      = [Convert]::ToInt32((Read-McpHex $SmwAddr.ControllerHeld 1).Split(' ')[0], 16)
        XSpeed    = [Convert]::ToInt32((Read-McpHex $SmwAddr.PlayerXSpeed 1).Split(' ')[0], 16)
    }
    if ($snap.XSpeed -ge 0x80) { $snap.XSpeed = $snap.XSpeed - 256 }

    Write-Host ("{0}:" -f $Label)
    Write-Host ("  gameMode=`${0:X4}={1:X2}  frame=`$13={2}  `$15={3:X2}  XSpeed={4}" -f $SmwAddr.GameMode, $snap.GameMode, $snap.Frame, $snap.Ctrl, $snap.XSpeed)
    Write-Host ("  Xcur  = {0}  [{1}]  (bus `${2:X4})" -f (Format-SmwU16 $snap.X $snap.XHex), $snap.XHex, $SmwAddr.PlayerX)
    Write-Host ("  Ycur  = {0}  [{1}]  (bus `${2:X4})" -f (Format-SmwU16 $snap.Y $snap.YHex), $snap.YHex, $SmwAddr.PlayerY)
    Write-Host ("  Xnext = {0}  [{1}]  (bus `${2:X4})" -f (Format-SmwU16 $snap.XNext $snap.XNextHex), $snap.XNextHex, $SmwAddr.PlayerXNext)
    Write-Host ("  Xscrn = {0}  [{1}]  (bus `${2:X4})" -f (Format-SmwU16 $snap.XScreen $snap.XScreenHex), $snap.XScreenHex, $SmwAddr.PlayerXScreen)
    return [pscustomobject]$snap
}

Write-Host "Loading savestate slot $Slot via MCP..."
try {
    $load = Invoke-MesenMcp "load_state_slot" @{ slot = $Slot } -TimeoutSec 30
} catch {
    Write-Host "  Slot load failed ($($_.Exception.Message)), trying savestate file..."
    $load = Invoke-MesenMcp "load_state_file" @{ path = $savestatePath } -TimeoutSec 30
}
if (-not $load.success) { throw "Failed to load savestate slot $Slot" }
Write-Host "  Savestate loaded"

# Settle, then pause so SA-1 RAM reads are stable before the baseline snapshot.
Start-Sleep -Milliseconds 200
Invoke-MesenMcp "pause" @{} | Out-Null
Start-Sleep -Milliseconds 100

try {
    $dbg = Invoke-MesenMcp "debugger_status" @{} -TimeoutSec 5
    Write-Host ("  Debugger: running={0} paused={1} stopped={2}" -f $dbg.debugger_running, $dbg.emulation_paused, $dbg.execution_stopped)
} catch {
    Write-Host "  Debugger status unavailable: $($_.Exception.Message)"
}

Write-Host "SA-1: DP=`$3000 (player/ctrl/frame), |!addr=`$6000 (game mode)"
$before = Read-PlayerSnapshot "After load (baseline)"

if ($WalkRight -or $WalkLeft) {
    $input = @{ port = 0 }
    if ($WalkRight) { $input.right = $true; $input.left = $false }
    if ($WalkLeft) { $input.left = $true; $input.right = $false }
    $setIn = Invoke-MesenMcp "set_controller_input" $input -TimeoutSec 10
    Write-Host "Input set (script_id=$($setIn.script_id))"

    Write-Host "Walking $(if ($WalkRight) { 'right' } else { 'left' }) for $Frames frames (wait until `$3013 advances)..."
    $timeout = [Math]::Max(60, $Frames * 5)
    $run = Invoke-MesenMcp "run_frames" @{ count = $Frames } -TimeoutSec $timeout
    if (-not $run.success) {
        throw ("run_frames failed: game_frames={0}/{1} ppu={2} method={3}" -f `
            $run.game_frames_advanced, $Frames, $run.frames_advanced, $run.method)
    }
    Write-Host ("  game `$13: {0} -> {1} (advanced {2})  PPU {3} -> {4}  method={5}" -f `
        $run.game_frame_before, $run.game_frame_after, $run.game_frames_advanced, `
        $run.frame_before, $run.frame_after, $run.method)

    Start-Sleep -Milliseconds 100
}

$after = Read-PlayerSnapshot "After frames"

if ($WalkRight -or $WalkLeft) {
    Invoke-MesenMcp "set_controller_input" @{ port = 0 } | Out-Null
}

Write-Host ""
Write-Host ("Deltas: Xcur={0}  Ycur={1}  Xnext={2}  Xscreen={3}  frame=`$13 {4}->{5}" -f `
    ($after.X - $before.X), ($after.Y - $before.Y), ($after.XNext - $before.XNext), `
    ($after.XScreen - $before.XScreen), $before.Frame, $after.Frame)

Write-Host ""
Write-Host "=== MCP CPU state ==="
try {
    $cpu = Invoke-MesenMcp "get_cpu_state" @{ cpu_type = 0 }
    Write-Host ("PC={0:X4} A={1:X2} X={2:X2} Y={3:X2}" -f $cpu.PC, $cpu.A, $cpu.X, $cpu.Y)
} catch {
    Write-Host "CPU read failed: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "Session complete."
