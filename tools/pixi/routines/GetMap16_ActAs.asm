;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine will return the act as value of the map16 block at the specified position.
;
; Output:
;  - Y: acts as high byte ($FF if block in invalid range)
;  - A: acts as low byte (also stored in $1693)
;
; Taken from worldpeace's line guide acts-like fix.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!EXLEVEL = 0
if (((read1($0FF0B4|!bank)-'0')*100)+((read1($0FF0B6|!bank)-'0')*10)+(read1($0FF0B7|!bank)-'0')) > 253
    !EXLEVEL = 1
endif

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
    rtl

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