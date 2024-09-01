
if read1($00FFD5) == $23		; check if the rom is sa-1
	sa1rom
	!SA1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000
	!bankA = $400000
    !SprSize = $16
else
	lorom
	!SA1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!bankA = $7E0000
    !SprSize = $0C
endif

; Does thing when Mario is touching the specified block.
; NOTE, however, that this only really works with blocks that
; have solid interaction by default. (So it'll be weird with, say, a door or moon.)

; jsl GetMap16_Main to get the map16 tile number
; jsl GetMap16_ActAs to get the map16 tile act as number

!TileNumber = $0131

!CustomTrigger = $7FC0FC

!FramesSinceButtonPressed = $41A028
!NumFramesBetweenSounds = $18

!NumPixelsBelowSprite = $0011
!NumPixelsBelowMario = $0021
!XOffset = $08

init:
    LDA #$00
    STA !FramesSinceButtonPressed
    RTL

main:

.checkPlayer
	JSR GetPositionBelowMario
    JSR GetMap16_ActAs
    CMP.b #!TileNumber
	BNE .checkSprites
	CPY.b #!TileNumber>>8
	BEQ ThingToDo

.checkSprites
	JSR CheckSprites
	BCC Nope

ThingToDo:
    LDA !CustomTrigger
    ;LDA $00
    REP #$20
    AND #$0001
    SEP #$20
    BNE .noSoundEffect

.soundEffect    ; only play sound when going from trigger == 0 to trigger == 1
    LDA !FramesSinceButtonPressed
    CMP #!NumFramesBetweenSounds
    BCC .noSoundEffect

    LDA #$29    ; 29 is correct.txt
	STA $1DFC|!addr ;$1DFC|!Base2

.noSoundEffect
    JSR SetCustomTrigger

    LDA #$00
    STA !FramesSinceButtonPressed

	BRA Return

Nope:
    JSR UnsetCustomTrigger

    LDA $9D
    BNE Return

    LDA !FramesSinceButtonPressed
    CMP #$FF
    BEQ Return

    INC A
    STA !FramesSinceButtonPressed

Return:
    RTL

CheckSprites:
	PHX
	LDX #!SprSize-1		;loop count (loop though all sprite number slots)

.Loop
	LDA !14C8,x			;load sprite status
	BEQ .nextSprite		;if non-existant, keep looping.

    LDA !7FAB9E,x
    CMP #$15
    BEQ .nextSprite     ; skip player indicator sprite

	JSR GetPositionBelowSprite
	JSR GetMap16_ActAs
	CMP.b #!TileNumber
	BNE .nextSprite
	CPY.b #!TileNumber>>8
	BNE .nextSprite

	PLX					;restore sprite index.
	SEC
	RTS					;return.

.nextSprite
	DEX					;decrement loop count by one
	BPL .Loop			;and loop while not negative.

	PLX					;restore sprite index.
	CLC
	RTS					;end? return.

GetPositionBelowSprite:
	LDA !14D4,x		; high Y
	XBA
	LDA !D8,x		; low Y
	REP #$20
	CLC : ADC #!NumPixelsBelowSprite
	STA $98
	SEP #$20

	LDA !14E0,x		; high X
	XBA
	LDA !E4,x		; low X
	CLC : ADC #!XOffset
    BCC .store

    XBA
    INC A
    XBA

.store
	REP #$20
	STA $9A
	SEP #$20

	STZ $1933|!addr

	RTS

GetPositionBelowMario:
    REP #$20
        LDA $D3			; PlayerPosYLow
        CLC : ADC #!NumPixelsBelowMario
        STA $98
    SEP #$20

	LDA $D2			; PlayerPosXHigh
	XBA
	LDA $D1			; PlayerPosXLow
	CLC : ADC #!XOffset
    BCC .store

    XBA
    INC A
    XBA

.store
	REP #$20
	STA $9A
	SEP #$20

	STZ $1933|!addr
	RTS

GetCustomTrigger:
    LDA !CustomTrigger
	STA $00
    RTS

SetCustomTrigger:
    REP #$20
        LDA !CustomTrigger
        ORA #$0001		;trigger 0 = 1st bit = 2^0 = #$1
        STA !CustomTrigger
	SEP #$20
    RTS

UnsetCustomTrigger:
	REP #$20
        LDA !CustomTrigger
        AND	#$0001^$FFFF	; invert the value to set it to 0.
        STA !CustomTrigger
	SEP #$20
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetBlock - SA-1 Hybrid version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this routine will get Map16 value
; If position is invalid range, will return 0xFFFF.
;
; input:
; $98-$99 block position Y
; $9A-$9B block position X
; $1933   layer
;
; output:
; A Map16 lowbyte (or all 16bits in 16bit mode)
; Y Map16 highbyte
;
; by Akaginite
;
; It used to return FF but it also fucked with N and Z lol, that's fixed now
; Slightly modified by Tattletale
;
; Usage:
; jsl GetMap16_Main to get the map16 tile number
; jsl GetMap16_ActAs to get the map16 tile act as number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!EXLEVEL = 0
if (((read1($0FF0B4|!bank)-'0')*100)+((read1($0FF0B6|!bank)-'0')*10)+(read1($0FF0B7|!bank)-'0')) > 253
    !EXLEVEL = 1
endif

GetMap16_Main:
    PHX
    PHP
    REP #$10
    PHB
    LDY $98
    STY $0E
    LDY $9A
    STY $0C
    SEP #$30
    LDA $5B
    LDX $1933|!addr
    BEQ .layer1
    LSR A
.layer1
    STA $0A
    LSR A
    BCC .horz
    LDA $9B
    LDY $99
    STY $9B
    STA $99
.horz
if !EXLEVEL
    BCS .verticalCheck
    REP #$20
    LDA $98
    CMP $13D7|!addr
    SEP #$20
    BRA .check
endif
.verticalCheck
    LDA $99
    CMP #$02
.check
    BCC .noEnd
    REP #$20        ; \ load return value for call in 16bit mode
    LDA #$FFFF      ; /
    PLB
    PLP
    PLX
    TAY             ; load high byte of return value for 8bit mode and fix N and Z flags
    RTS

.noEnd
    LDA $9B
    STA $0B
    ASL A
    ADC $0B
    TAY
    REP #$20
    LDA $98
    AND.w #$FFF0
    STA $08
    AND.w #$00F0
    ASL #2          ; 0000 00YY YY00 0000
    XBA             ; YY00 0000 0000 00YY
    STA $06
    TXA
    SEP #$20
    ASL A
    TAX

    LDA $0D
    LSR A
    LDA $0F
    AND #$01        ; 0000 000y
    ROL A           ; 0000 00yx
    ASL #2          ; 0000 yx00
    ORA #$20        ; 0010 yx00
    CPX #$00
    BEQ .noAdd
    ORA #$10        ; 001l yx00
.noAdd
    TSB $06         ; $06 : 001l yxYY
    LDA $9A         ; X LowByte
    AND #$F0        ; XXXX 0000
    LSR #3          ; 000X XXX0
    TSB $07         ; $07 : YY0X XXX0
    LSR A
    TSB $08

    LDA $1925|!addr
    ASL A
    REP #$31
    ADC $00BEA8|!bank,x
    TAX
    TYA
if !sa1
    ADC.l $00,x
    TAX
    LDA $08
    ADC.l $00,x
else
    ADC $00,x
    TAX
    LDA $08
    ADC $00,x
endif
    TAX
    SEP #$20
if !sa1
    LDA $410000,x
    XBA
    LDA $400000,x
else
    LDA $410000,x
    XBA
    LDA $7E0000,x
endif
    SEP #$30
    XBA
    TAY
    XBA

    PLB
    PLP
    PLX
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine will return the act as value of the map16 block at the specified position.
;
; Output:
;  - Y: acts as high byte ($FF if block in invalid range)
;  - A: acts as low byte (also stored in $1693)
;
; Taken from worldpeace's line guide acts-like fix.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetMap16_ActAs:
    jsr GetMap16_Main
    sta $1693|!addr
    cpy #$FF
    beq .Return
    tya
-   xba
    lda $1693|!addr
    rep #$20
    asl
    adc.l $06F624|!bank
    sta $0D
    sep #$20
    lda.l $06F626|!bank
    sta $0F
    rep #$20
    lda [$0D]
    sep #$20
    sta $1693|!addr
    xba
    cmp #$02
    bcs -
    tay
    lda $1693|!addr
.Return
    rts
