;===========================================================;
; Constant horizontal/vertical autoscroll UberASM by KevinM ;
;===========================================================;

; Change these to customize the autoscroll settings
!NoLRScroll     = 1     ;> 1 = no LR scroll, 0 = LR scroll enabled.
!Direction1     = 0     ;> 1 = vertical, 0 = horizontal.
!Direction2     = 0     ;> 1 = up/left, 0 = down/right.
!Teleport       = 0     ;> 1 = when the scroll stops, Mario will teleport based on the current screen exit.
!StartScreen    = $00   ;> Screen number where to start scrolling.
!Start1         = $0070
!StopScreen     = $0A   ;> Screen number where to stop scrolling.
;!Speed          = $00   ;> How many pixels to move each frame.
;!FractionSpeed  = $94   ;\ Fractional speed, used if you want more fine-tuned speed (e.g. 1.5 speed, 0.5, etc.)
                        ;| Goes from $00 to $FF, where $FF is almost equal to !Speed = $01
                        ;| So for example if you want 1.5 speed, you'd use !Speed = $01 and !FractionSpeed = $80
                        ;/ and for 0.5 speed you'd use !Speed = $00 and !FractionSpeed = $80.
!Speed0          = $00
!FractionSpeed0  = $94

!Speed1          = $01
!FractionSpeed1  = $D0 ;$B8

; Don't edit from here, unless you know what you're doing!
!ScrollDir      = $55
!FractionBits   = $0E19|!addr     ; 1 byte of freeram

if !Direction1
    !StopScroll = $1412|!addr
    !PosLow     = $1464|!addr
    !PosHigh    = $1465|!addr
else
    !StopScroll = $1411|!addr
    !PosLow     = $1462|!addr
    !PosHigh    = $1463|!addr
endif

if !Direction2
    !Instr1     = sec
    !Instr2     = sbc.b
    !Instr3     = bmi
    !Instr4     = bpl
    !StartPos   = (!StartScreen+1)<<8
    !StopPos    = (!StopScreen<<8)+1
else
    !Instr1     = clc
    !Instr2     = adc.b
    !Instr3     = bpl
    !Instr4     = bmi
    !StartPos   = (!StartScreen-1<<8)+1
    !StopPos    = !StopScreen<<8
endif

init:
    stz !FractionBits
    rtl

main:
    lda $9D
    ora $13D4|!addr
    ORA $71      ;\ Mario in cutscene?
    bne .return

if !NoLRScroll
    stz $1401|!addr
    stz $13FD|!addr
endif
    
    rep #$20
    lda !PosLow
    cmp.w #!StartPos
    sep #$20
    !Instr4 .return

    stz !StopScroll

if !Direction2
    stz !ScrollDir
else
    lda #$02
    sta !ScrollDir
endif
    
    rep #$20
    lda !PosLow
    cmp.w #!StopPos
    sep #$20
    !Instr3 .return2

    !Instr1
;if !FractionSpeed != $00
    ;Fraction bits based on screen we're currently at?

    rep #$20
    lda !PosLow
    cmp.w #!Start1
    sep #$20
    BCC .screen0

    BRA .screen1

.screen0
    lda !FractionBits
    !Instr2 #!FractionSpeed0
    sta !FractionBits

    lda !PosLow
    !Instr2 #!Speed0
    sta !PosLow
    lda !PosHigh
    !Instr2 #$00
    sta !PosHigh
    BRA .return

.screen1
    lda !FractionBits
    !Instr2 #!FractionSpeed1
    sta !FractionBits

    lda !PosLow
    !Instr2 #!Speed1
    sta !PosLow
    lda !PosHigh
    !Instr2 #$00
    sta !PosHigh
;endif

.return:
    rtl

.return2:
if !Teleport
    stz $88
    stz $89
    lda #$06
    sta $71
endif
    rtl
