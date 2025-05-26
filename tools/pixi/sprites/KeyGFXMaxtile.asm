KeyGFXNew:
    %GetDrawInfo()             ; Prepare drawing info

    ; --- Allocate one OAM slot using MaxTile Allocation Mode ---
    REP #$30                ; Set 16-bit accumulator and index registers.
    LDY.w #$0001              ; Request 1 slot for a 16x16 sprite.
    LDA.w #$0003                ; Set priority: 3 (lowest priority buffer)
    JSL $0084B0              ; Call allocation routine. (maxtile_get_slot)
    SEP #$20                ; Set 8-bit accumulator and index registers.
    BCC .draw_failed        ; Allocation failed? If so, skip drawing.

    ; Now, the allocated OAM entry pointer is in $3100 (main) and $3102 (attribute).
    
    ; Draw at position $00, $01
    LDX $3100               ; Load the OAM main pointer.
    LDA $00                 ; Load X position.
    STA $400000,x           ; Store X position.

    LDA $01                 ; Load Y position.
    STA $400001,x           ; Store Y position.

    ; Draw key tile (16x16)
    LDA #!GFX_KeyTile
    STA $400002,x           ; Store tile number.

    ; Use Palette 0 and minimum priority
    LDX $3102               ; Load the OAM attribute pointer.
    LDA.b #%00000000
    STA $400003,x           ; Store properties.

    ; --- Finalize the OAM allocation ---
    ; The finish routine takes:
    ;   A = number of slots allocated minus one (here, 1-1 = 0)
    ;   Y = tile size: use $02 for 16x16.
    SEP #$10                ; Set 8-bit index registers.
    LDA #$00                ; 1 slot - 1 = 0.
    LDY #$02                ; Tile size: 16x16.
    JSL $0084B4             ; Finalize OAM writing. (maxtile_finish_oam)
    
    LDX $15E9|!addr          ; Restore X register.
    RTS                     ; Return from subroutine.

.draw_failed:
    ; Allocation failed – either out of OAM slots or another error.
    RTS                     ; Exit without drawing.
