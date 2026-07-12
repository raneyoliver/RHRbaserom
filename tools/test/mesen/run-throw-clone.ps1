# Throw Luigi (OliverClone) while holding Right - mid-air throw scenario.
#
# Savestate: Mario airborne, carrying Luigi. Script clears grab (Y/X) and holds
# Right so Mario throws, then waits N game frames while logging clone speeds.
#
# Prereqs: Mesen + MCP running (start-mcp.ps1, Tools -> MCP Server -> Start)
#
# Usage:
#   .\run-throw-clone.ps1 -Slot 1 -Frames 30
#   .\run-throw-clone.ps1 -Slot 1 -Frames 30 -SampleEvery 1

param(
    [int]$Slot = 1,
    [int]$Frames = 30,
    [int]$SampleEvery = 2
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "automation-io.ps1")
. (Join-Path $PSScriptRoot "smw-addrs.ps1")
. (Join-Path $PSScriptRoot "smw-sprites.ps1")

$savestatePath = Join-Path $env:USERPROFILE "Documents\Mesen2\SaveStates\RHRv5_$Slot.mss"
if (-not (Test-Path $savestatePath)) {
    throw "Savestate slot $Slot not found: $savestatePath"
}
if (-not (Get-Process -Name "Mesen" -ErrorAction SilentlyContinue)) {
    throw "Mesen is not running."
}
if (-not (Wait-McpPort -TimeoutSec 30)) {
    throw "MCP not available on :51234."
}

$tools = Invoke-MesenMcpListTools
foreach ($t in @("load_state_slot", "set_controller_input", "run_frames")) {
    if ($t -notin $tools) { throw "Missing MCP tool $t - rebuild patched Mesen." }
}

function Read-U8([int]$Address) {
    return [Convert]::ToInt32((Read-McpHex $Address 1).Split(' ')[0], 16)
}

function Find-OliverCloneSlot {
    # Prefer freeram index if valid
    $idx = Read-U8 $CloneRam.CloneIndex
    if ($idx -lt 22) {
        $st = Read-U8 ($SmwSprite.Status + $idx)
        $bits = Read-U8 ($SmwSprite.CustomBits + $idx)
        if ($st -ne 0 -and (($bits -band 0x08) -ne 0)) {
            $num = Read-U8 ($SmwSprite.CustomNum + $idx)
            if ($num -eq $OliverCloneExtra) { return $idx }
        }
    }
    for ($i = 0; $i -lt 22; $i++) {
        $st = Read-U8 ($SmwSprite.Status + $i)
        if ($st -eq 0) { continue }
        $bits = Read-U8 ($SmwSprite.CustomBits + $i)
        if (($bits -band 0x08) -eq 0) { continue }
        $num = Read-U8 ($SmwSprite.CustomNum + $i)
        if ($num -eq $OliverCloneExtra) { return $i }
    }
    return -1
}

function Get-CloneSnapshot([int]$SlotIndex, [string]$Label) {
    $st  = Read-U8 ($SmwSprite.Status + $SlotIndex)
    $xLo = Read-U8 ($SmwSprite.XLo + $SlotIndex)
    $xHi = Read-U8 ($SmwSprite.XHi + $SlotIndex)
    $yLo = Read-U8 ($SmwSprite.YLo + $SlotIndex)
    $yHi = Read-U8 ($SmwSprite.YHi + $SlotIndex)
    $b6  = Read-U8 ($SmwSprite.XSpeed + $SlotIndex)
    $aa  = Read-U8 ($SmwSprite.YSpeed + $SlotIndex)
    $blk = Read-U8 ($SmwSprite.Blocked + $SlotIndex)
    $x = $xLo + ($xHi -shl 8)
    $y = $yLo + ($yHi -shl 8)
    $snap = [ordered]@{
        Label = $Label
        Slot  = $SlotIndex
        Status = $st
        X = $x
        Y = $y
        B6 = $b6
        AA = $aa
        Blocked = $blk
        Bounce = Read-U8 $CloneRam.BouncingSpeed
        LandT  = Read-U8 $CloneRam.LandingTimer
        PrevB6 = Read-U8 $CloneRam.PreviousXSpeed
        OnPlat = Read-U8 $CloneRam.OnPlatform
        Frame  = Read-U8 $SmwAddr.FrameCounter
        Ctrl15 = Read-U8 $SmwAddr.ControllerHeld
        Ctrl17 = Read-U8 $SmwAddr.ControllerHeld2
    }
    Write-Host ("{0}: slot=`${1:X2} 14C8=`${2:X2} X=`${3:X4} Y=`${4:X4} B6=`${5:X2} AA=`${6:X2} 1588=`${7:X2}" -f `
        $Label, $SlotIndex, $st, $x, $y, $b6, $aa, $blk)
    Write-Host ("         bounce=`${0:X2} landT=`${1:X2} prevB6=`${2:X2} onPlat=`${3:X2} `$13=`${4:X2} `$15=`${5:X2} `$17=`${6:X2}" -f `
        $snap.Bounce, $snap.LandT, $snap.PrevB6, $snap.OnPlat, $snap.Frame, $snap.Ctrl15, $snap.Ctrl17)
    return [pscustomobject]$snap
}

Write-Host "Loading savestate slot $Slot..."
try {
    $load = Invoke-MesenMcp "load_state_slot" @{ slot = $Slot } -TimeoutSec 30
} catch {
    $load = Invoke-MesenMcp "load_state_file" @{ path = $savestatePath } -TimeoutSec 30
}
if (-not $load.success) { throw "Savestate load failed" }
Start-Sleep -Milliseconds 200
Invoke-MesenMcp "pause" @{} | Out-Null
Start-Sleep -Milliseconds 100

$cloneSlot = Find-OliverCloneSlot
if ($cloneSlot -lt 0) { throw "OliverClone (extra `$14) not found in sprite slots" }
Write-Host ("Found OliverClone in slot `${0:X2}" -f $cloneSlot)

$before = Get-CloneSnapshot $cloneSlot "Baseline (held)"

Write-Host "Input: Right held, grab (Y/X) released - throw Luigi"
Invoke-MesenMcp "set_controller_input" @{
    port = 0
    right = $true
    left = $false
    up = $false
    down = $false
    a = $false
    b = $false
    x = $false
    y = $false
    start = $false
    select = $false
} | Out-Null

$samples = [System.Collections.Generic.List[object]]::new()
$samples.Add($before) | Out-Null

$remaining = $Frames
$step = [Math]::Max(1, $SampleEvery)
Write-Host "Running $Frames game frames (sample every $step)..."
while ($remaining -gt 0) {
    $chunk = [Math]::Min($step, $remaining)
    $run = Invoke-MesenMcp "run_frames" @{ count = $chunk } -TimeoutSec ([Math]::Max(30, $chunk * 5))
    if (-not $run.success -and $run.game_frames_advanced -lt 1) {
        throw "run_frames stalled: $($run | ConvertTo-Json -Compress)"
    }
    $remaining -= $chunk
    $samples.Add((Get-CloneSnapshot $cloneSlot ("f+{0}" -f ($Frames - $remaining)))) | Out-Null
}

Invoke-MesenMcp "set_controller_input" @{ port = 0 } | Out-Null

Write-Host ""
Write-Host "=== Speed trace (B6=X AA=Y) ==="
Write-Host "frame   14C8   B6   AA   bounce landT prevB6   X      Y"
foreach ($s in $samples) {
    Write-Host ("`${0:X2}    `${1:X2}   `${2:X2}  `${3:X2}   `${4:X2}    `${5:X2}   `${6:X2}   `${7:X4} `${8:X4}" -f `
        $s.Frame, $s.Status, $s.B6, $s.AA, $s.Bounce, $s.LandT, $s.PrevB6, $s.X, $s.Y)
}

$firstAir = $samples | Where-Object { $_.Status -ne 0x0B } | Select-Object -First 1
$after = $samples[-1]
Write-Host ""
if ($firstAir) {
    Write-Host ("First non-carried status: 14C8=`${0:X2} B6=`${1:X2} AA=`${2:X2}" -f $firstAir.Status, $firstAir.B6, $firstAir.AA)
}
Write-Host ("End: B6=`${0:X2} AA=`${1:X2}  deltaX=`${2:X4}" -f $after.B6, $after.AA, (($after.X - $before.X) -band 0xFFFF))
Write-Host ""
Write-Host "Done. If B6 drops to 00 when bounce rises, check HandleLandingBounce / PreviousXSpeed."
