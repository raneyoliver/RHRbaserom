includeonce

; Shared FreeRAM Definitions

; Large blocks of ram
if read1($00FFD5) == $23
    !objectool_level_flags_freeram = $409400    ; 13 bytes
    !toggles_freeram_bank = $409450             ; 16 bytes reserved, 6 used
    !retry_freeram =  $40A400
else
    !objectool_level_flags_freeram = $7FA400    ; 13 bytes
    !toggles_freeram_bank = $7FA450             ; 16 bytes reserved, 6 used
    !retry_freeram = $7FB400
endif

; If you're looking to update or add freeram definitions do check the RAM Map first:
; https://www.smwcentral.net/?p=memorymap&game=smw&region[]=ram&type=Empty

; Resource FreeRAM (sorted by used address)
!sprite_scroll_fix_position_freeram         = $0DC3|!addr ; 4 bytes
!block_duplication_freeram                  = $13E6|!addr ; 1 byte
!sprite_scroll_fix_displacement_freeram     = $1487|!addr ; 4 bytes
!triangles_fix_freeram                      = $14BE|!addr ; 1 byte
!goal_point_reward_fix_freeram              = $15E8|!addr ; 1 byte
!extended_nstl_freeram                      = $1869|!addr ; 2 bytes
!screen_scrolling_pipes_freeram             = $18C5|!addr ; 5 bytes
!skull_raft_fix_freeram                     = $18E6|!addr ; 1 byte
!capespin_direction_freeram                 = $1923|!addr ; 1 byte
!double_hit_fix_freeram                     = $1DFD|!addr ; 1 byte

; addresses used by some resources to toggle their behaviour
; these all use a freed bank of ram addresses defined above
!toggle_lr_scroll_freeram                   = !toggles_freeram_bank   ; 1 byte
!toggle_statusbar_freeram                   = !toggles_freeram_bank+1 ; 1 byte
!toggle_spinjump_fireball_freeram           = !toggles_freeram_bank+2 ; 1 byte
!toggle_block_duplication_freeram           = !toggles_freeram_bank+3 ; 1 byte
!toggle_capespin_direction_freeram          = !toggles_freeram_bank+4 ; 1 byte
!toggle_springboard_fixes_freeram           = !toggles_freeram_bank+5 ; 1 byte
!toggle_retry_indicator_freeram             = !toggles_freeram_bank+6 ; 1 byte

;------------------------------------------------------------------------------
; RHR / Luigi SA-1 FreeRAM (live bus addresses used by inserted code)
; Full map + free ranges: docs/freeram-registry.md
; Do not allocate overlapping bytes; update the registry when adding addresses.
;------------------------------------------------------------------------------
if read1($00FFD5) == $23
    !rhr_mario_exgfx_freeram                = $41A000 ; 4 bytes (mario_exgfx)
    !rhr_luigi_index                        = $41A01A ; 1 byte
    !rhr_is_mario                           = $41A026 ; 1 byte (also GFX trigger)
    !rhr_luigi_held_item_index              = $41B82E ; 1 byte
    !rhr_mario_held_item_index              = $41B82F ; 1 byte
    !rhr_luigi_tp_x_lo                      = $41B830 ; 1 byte — NOT for debug
    !rhr_luigi_tp_x_hi                      = $41B831 ; 1 byte
    !rhr_luigi_tp_y_lo                      = $41B832 ; 1 byte
    !rhr_luigi_tp_y_hi                      = $41B833 ; 1 byte
    !rhr_luigi_freeze_backup                = $41B900 ; ~660 bytes (22*30)
    !rhr_luigi_slot_swap_scratch            = $41BB00 ; 62 bytes (overlaps freeze window — see registry)
    !rhr_debug_freeram                      = $41B839 ; preferred 1-byte debug scratch
    !rhr_luigi_held_item_1686_backup        = $41B844 ; 1 byte ($1686 while Luigi holds)
else
    !rhr_mario_exgfx_freeram                = $7FA000
    !rhr_luigi_index                        = $7FA01A
    !rhr_is_mario                           = $7FA026
    !rhr_luigi_held_item_index              = $7FB82E
    !rhr_mario_held_item_index              = $7FB82F
    !rhr_luigi_tp_x_lo                      = $7FB830
    !rhr_luigi_tp_x_hi                      = $7FB831
    !rhr_luigi_tp_y_lo                      = $7FB832
    !rhr_luigi_tp_y_hi                      = $7FB833
    !rhr_luigi_freeze_backup                = $7FB900
    !rhr_luigi_slot_swap_scratch            = $7FBB00
    !rhr_debug_freeram                      = $7FB839
    !rhr_luigi_held_item_1686_backup        = $7FB844
endif