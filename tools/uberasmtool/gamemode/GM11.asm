; Gamemode 11 - Load Level (Mario Start!)
init:
    jsl CleanupLuigiCarryOnDeath_transition
    jsl retry_level_init_1_init
    jsl retry_level_transition_init
    rtl
