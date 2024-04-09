db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
JMP WallFeet : JMP WallBody ; when using db $37

SpriteV:
SpriteH:
    TXA					;/
    INC A				;| Check if the sprite touching the block is Yoshi.
    CMP $18E2|!addr		;\
    BNE Return

    LDA $1490|!addr		; Check if Mario has a star.
    BNE Return

    JSL $00F606         ; kill Mario

    BRA Return

MarioBelow:
MarioAbove:
MarioSide:

TopCorner:
BodyInside:
HeadInside:

WallFeet:	; when using db $37
WallBody:
    JSL $00F606

MarioCape:
MarioFireball:
Return:
RTL

print "Lava block that also kills Mario if Yoshi touches it"
