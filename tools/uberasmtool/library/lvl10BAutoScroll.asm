; Level 10B: immediate, constant horizontal autoscroll to the right.
; Based on lvl22AutoScroll.asm, without start/stop screens or speed changes.

!NoLRScroll = 1
!Speed = $00
!FractionSpeed = $94

!ScrollDir = $55
; Shared with level 22's mutually-exclusive level code.
!FractionBits = $0E19|!addr

init:
    stz !FractionBits
    rtl

main:
    lda $9D
    ora $13D4|!addr
    ora $71
    bne .return

if !NoLRScroll
    stz $1401|!addr
    stz $13FD|!addr
endif

    ; Keep horizontal scrolling enabled and force its direction right.
    stz $1411|!addr
    lda #$02
    sta !ScrollDir

    ; Constant !Speed + !FractionSpeed pixels per frame, forever.
    clc
if !FractionSpeed != $00
    lda !FractionBits
    adc #!FractionSpeed
    sta !FractionBits
endif
    lda $1462|!addr
    adc #!Speed
    sta $1462|!addr
    lda $1463|!addr
    adc #$00
    sta $1463|!addr

.return
    rtl
