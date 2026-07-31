; Gamemode 0F - Fade to Level
init:
    jsl retry_fade_to_level_init
    rtl

main:
    jsl CleanupLuigiCarryOnDeath_transition
    jsl retry_fade_to_level_main
    rtl
