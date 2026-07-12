# SMW RAM for this SA-1 hack (uber_defines: !sa1=1, !dp=$3000, !addr=$6000).
#
# smwmemory.json lists lorom $7E:xxxx. On SA-1:
#   - DP-accessed vars (LDA $xx with D=$3000) live at $3000+offset  ← player/ctrl/frame
#   - Absolute |!addr vars live at $6000+offset                     ← game mode, etc.
# Empirically $30xx updates while game runs; $60xx player mirrors can be stale.

$script:SmwDpBase = 0x3000
$script:SmwAddrBase = 0x6000

function ConvertTo-SmwDpAddress {
    param([int]$Offset)
    return ($script:SmwDpBase + ($Offset -band 0xFFFF))
}

function ConvertTo-SmwAddrAddress {
    param([int]$Offset)
    $off = $Offset -band 0xFFFF
    if ($off -lt 0x2000) {
        return ($script:SmwAddrBase + $off)
    }
    return (0x7E0000 + $off)
}

$script:SmwAddr = @{
    # DP mirror ($3000) — live gameplay values
    ControllerHeld   = ConvertTo-SmwDpAddress 0x0015  # byetUDLR
    ControllerNew    = ConvertTo-SmwDpAddress 0x0016
    ControllerHeld2  = ConvertTo-SmwDpAddress 0x0017
    ControllerNew2   = ConvertTo-SmwDpAddress 0x0018
    FrameCounter     = ConvertTo-SmwDpAddress 0x0013  # increments every game frame
    FrameReady       = ConvertTo-SmwDpAddress 0x0010  # NMI gate (wait loop LDA $10)

    PlayerXScreen    = ConvertTo-SmwDpAddress 0x007E
    PlayerYScreen    = ConvertTo-SmwDpAddress 0x0080
    PlayerXSpeed     = ConvertTo-SmwDpAddress 0x007B

    PlayerXNext      = ConvertTo-SmwDpAddress 0x0094
    PlayerYNext      = ConvertTo-SmwDpAddress 0x0096
    PlayerX          = ConvertTo-SmwDpAddress 0x00D1
    PlayerY          = ConvertTo-SmwDpAddress 0x00D3

    # Absolute |!addr ($6000) — not always the same as DP mirror
    GameMode         = ConvertTo-SmwAddrAddress 0x0100
    LivesMinusOne    = ConvertTo-SmwAddrAddress 0x0DBE
    Coins            = ConvertTo-SmwAddrAddress 0x0DBF
    Pose             = ConvertTo-SmwAddrAddress 0x13E0
    Layer1X          = ConvertTo-SmwAddrAddress 0x1462
}

function Test-SmwButtonRight([int]$HeldByte) { return (($HeldByte -band 0x01) -ne 0) }
function Test-SmwButtonLeft([int]$HeldByte)  { return (($HeldByte -band 0x02) -ne 0) }

function Format-SmwU16 {
    param([int]$Value, [string]$RawHex)
    $parts = @($RawHex -split ' ')
    $lo = $parts[0]
    $hi = if ($parts.Count -gt 1) { $parts[1] } else { '??' }
    return ("{0} (0x{0:X4} lo={1} hi={2})" -f $Value, $lo, $hi)
}
