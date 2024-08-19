; Gamemode 10 - Fade to Level (black)
init:
    ;JSL NoOverworld_PreLoadLevel
    jsl retry_level_transition_init
    jsl toggles_ram_clear_init
    jsl uberasm_objects_gm10_init
    rtl
