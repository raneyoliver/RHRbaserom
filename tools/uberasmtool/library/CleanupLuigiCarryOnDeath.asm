; Vanilla SMW preserves the sprite Mario carries across a level transition,
; but it only restores vanilla tables. Custom Luigi therefore reappears in the
; reloaded level as status $09 with $9E=$36 and no PIXI identity: an invisible
; sprite that Mario can still pick up.
;
; Retry reloads the level after death, so drop the carried custom Luigi (and
; anything he was holding) while the old level is being torn down.
;
; Timing note: at $71=$09 in gamemode $14 Luigi is already back to $09, and the
; carried $0B state only reappears during the fade-to-level gamemodes. The
; cleanup therefore runs on those transitions, gated by a death flag so normal
; door/pipe transitions are untouched.

%define_sprite_table("14C8", $14C8, $3242)
%define_sprite_table("7FAB10", $7FAB10, $6040)
%define_sprite_table("7FAB9E", $7FAB9E, $6083)

!SprSize = $16
!LuigiSpriteNumber = $14
!LuigiHeldItemIndex = $41B82E
!MarioHeldItemIndex = $41B82F
!DeathPending = $41B846
!HeldInteractionDebug = $41B839
!HeldClipDebug = $41B83A

; Gamemode $14 main: remember that this level ended in a death.
death_watch:
    php
    sep #$30
    lda $71
    cmp #$09
    bne +
    lda #$01
    sta.l !DeathPending
    lda #$D0
    sta.l !HeldInteractionDebug
+
    plp
    rtl

; Gamemode $14 init: a new level is running, so the death is fully handled.
clear_flag:
    php
    sep #$30
    lda #$00
    sta.l !DeathPending
    plp
    rtl

; Fade-to-level / load-level gamemodes: erase the carried Luigi before the
; level loader can preserve him into the new room.
transition:
    php
    sep #$30

    lda.l !DeathPending
    beq .return

    ; One-shot: the first transition hook after death performs the cleanup.
    ; Leaving the flag armed erased the NEXT level's freshly spawned Luigi
    ; (gamemode $12 runs after the new sprite tables are loaded).
    lda #$00
    sta.l !DeathPending

    ; Mario is not carrying anything into the reloaded level.
    stz $1470|!addr
    stz $148F|!addr
    stz $1498|!addr

    ; Erase whatever Luigi was holding; the new level spawns its own copy.
    lda.l !LuigiHeldItemIndex
    cmp #$FF
    beq .clearIndices
    cmp #!SprSize
    bcs .clearIndices
    tax
    stz !14C8,x

.clearIndices
    lda #$FF
    sta.l !LuigiHeldItemIndex
    sta.l !MarioHeldItemIndex

    ; Find the canonical custom Luigi. Recycled slots can keep a stale
    ; 7FAB9E=$14, so require the PIXI custom bit as well.
    ldx #$00
.loop
    lda !7FAB10,x
    and #$08
    beq .next
    lda !7FAB9E,x
    cmp #!LuigiSpriteNumber
    bne .next

    lda !14C8,x
    sta.l !HeldClipDebug+1
    txa
    sta.l !HeldClipDebug
    lda #$D2
    sta.l !HeldInteractionDebug
    stz !14C8,x
    bra .return

.next
    inx
    cpx #!SprSize
    bne .loop

.return
    plp
    rtl
