db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

MarioBelow:
MarioAbove:
MarioSide:

TopCorner:
BodyInside:
HeadInside:

LDA $18AC
BEQ Return
STZ $18AC
LDA #$25
STA $1DFC
%create_smoke()

;WallFeet:	; when using db $37
;WallBody:

SpriteV:
SpriteH:

MarioCape:
MarioFireball:
Return:
RTL

print "<description>"
