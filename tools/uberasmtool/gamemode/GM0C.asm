; Gamemode 0C - Load Overworld
init:
    ;JSL NoOverworld_SkipOW
    jsl retry_reset_init
    jsl retry_load_overworld_init
    rtl
