;act like $130 or $100.
;This block will spawn a donut lift sprite
;based on mikeyk's code, adapted by Davros.

!CUSTOM_SPRITE = $00    ;>custom sprite number to generate

db $42

JMP Return : JMP MarioAbove : JMP Return : JMP SpriteV : JMP Return : JMP Return : JMP Return
JMP TopCorner : JMP Return : JMP Return

SpriteV:
    REP #$20
    LDA $7FC0FC
    ORA #$0001
    STA $7FC0FC
    SEP #$20

    JMP Return

MarioAbove:
TopCorner:
    LDA $7D               ;\if Mario speed isn't downward...
    BMI Return            ;/return
    ;LDA $72              ;\this was buggy, if you land on top of this block
    ;BNE Return           ;/and jump the frame mario lands on won't count as "on ground".


    REP #$20              ;\Detect if mario is standing on top of the block
    LDA $98               ;|(better than using $7E:0072). Note: when mario descends onto
    AND #$FFF0            ;|the top of the block, he goes slightly into the block than he
    SEC : SBC #$001C      ;|should be by a maximum of 4 pixels before being "snapped" to
    CMP $96               ;|the top of the block, thats why I choose $001C instead of $0020.
    SEP #$20              ;|
    BCC Return            ;/

    JMP SpriteV

Return:
    RTL                     ;return

print "Pressure Plate (Custom 0 Trigger)"
