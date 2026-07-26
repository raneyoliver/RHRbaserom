$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "automation-io.ps1")
. (Join-Path $PSScriptRoot "smw-sprites.ps1")
. (Join-Path $PSScriptRoot "smw-addrs.ps1")

function U8([int]$a) { [Convert]::ToInt32((Read-McpHex $a 1).Split(' ')[0], 16) }

Invoke-MesenMcp "load_state_slot" @{ slot = 1 } | Out-Null
$li = U8 0x41A01A
$sh = U8 0x41B82E
Write-Host ("LH={0:X2} L={1:X2} L14={2:X2} L154C={3:X2} TR={4:X2}" -f $sh,$li,(U8 (0x3242+$li)),(U8 (0x32DC+$li)),(U8 0x41A016))
Write-Host ("1470={0:X2} 148F={1:X2} 187A={2:X2} 15@3015={3:X2} 15@0015={4:X2}" -f (U8 0x7470),(U8 0x748F),(U8 0x787A),(U8 0x3015),(U8 0x0015))
$px = Read-McpU16 $SmwAddr.PlayerX
$lx = (U8 ($SmwSprite.XLo+$li)) + ((U8 ($SmwSprite.XHi+$li)) -shl 8)
$ly = (U8 ($SmwSprite.YLo+$li)) + ((U8 ($SmwSprite.YHi+$li)) -shl 8)
$py = Read-McpU16 $SmwAddr.PlayerY
Write-Host ("Mario={0:X4},{1:X4} Luigi={2:X4},{3:X4}" -f $px,$py,$lx,$ly)

Invoke-MesenMcp "set_controller_input" @{
    port=0; right=$true; y=$true; left=$false; up=$false; down=$false
    a=$false; b=$false; x=$false; l=$false; r=$false; start=$false; select=$false
} | Out-Null

for ($f=0; $f -lt 40; $f++) {
    Invoke-MesenMcp "run_frames" @{ count = 1 } -TimeoutSec 15 | Out-Null
    $li = U8 0x41A01A
    $stL = U8 (0x3242+$li)
    $px = Read-McpU16 $SmwAddr.PlayerX
    $lx = (U8 ($SmwSprite.XLo+$li)) + ((U8 ($SmwSprite.XHi+$li)) -shl 8)
    $dx = $lx - $px
    if ($dx -gt 0x7FFF) { $dx -= 0x10000 }
    $near = [Math]::Abs($dx) -lt 0x18
    if ($stL -eq 0x0B -or $near -or $f -lt 2 -or ($f % 8 -eq 0)) {
        Write-Host ("f+{0} L14={1:X2} L154C={2:X2} TR={3:X2} 1470={4:X2} 148F={5:X2} 15={6:X2} dx={7} MarioY={8:X4} LuigiY={9:X4}" -f `
            $f,$stL,(U8 (0x32DC+$li)),(U8 0x41A016),(U8 0x7470),(U8 0x748F),(U8 0x3015),$dx,
            (Read-McpU16 $SmwAddr.PlayerY), ((U8 ($SmwSprite.YLo+$li))+((U8 ($SmwSprite.YHi+$li))-shl 8)))
    }
    if ($stL -eq 0x0B) { Write-Host "GRABBED"; break }
}
Invoke-MesenMcp "set_controller_input" @{ port = 0 } | Out-Null
