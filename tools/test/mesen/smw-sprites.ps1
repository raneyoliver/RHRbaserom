# SA-1 sprite table bus addresses (from OliverClone.asm %define_sprite_table).
# Custom sprite number OliverClone = $14 (tools/pixi/list.txt).

$script:SmwSprite = @{
    NumVanilla   = 0x3200   # !9E
    # Live speeds via MCP: SA-1 DP mirror ($3000+), not absolute $00B6/$009E (stale).
    YSpeed       = 0x309E   # !AA with D=$3000
    XSpeed       = 0x30B6   # !B6 with D=$3000
    YLo          = 0x3216   # !D8
    XLo          = 0x322C   # !E4
    Status       = 0x3242   # !14C8
    YHi          = 0x3258   # !14D4
    XHi          = 0x326E   # !14E0
    Blocked      = 0x334A   # !1588
    CustomNum    = 0x6083   # !7FAB9E
    CustomBits   = 0x6040   # !7FAB10
}

# OliverClone freeram (Config.asm / OliverClone.asm)
$script:CloneRam = @{
    BouncingSpeed  = 0x41A023
    LandingTimer   = 0x41B834
    PreviousXSpeed = 0x41B835
    JumpHeld       = 0x41A005
    OnPlatform     = 0x41A00E
    PreviousState  = 0x41A00F
    CloneIndex     = 0x41A01A   # from clone_item.toml / asm
}

$script:OliverCloneExtra = 0x14  # pixi list slot extra bit number
