; Luigi-identity solid (use on Layer 2 for level 10B).
; Solid for Luigi-colored player (!IsMario clear) and Luigi-colored companion
; (!IsMario set). Everyone else treats it as air.
; Insert with act-as 130. Map16 $522.

if read1($00FFD5) == $23
	sa1rom
	!SA1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000
else
	lorom
	!SA1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
endif

!IsMario = $41A026
!LuigiIndex = $41A01A

db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP Return : JMP Return
JMP TopCorner : JMP BodyInside : JMP HeadInside
JMP WallFeet : JMP WallBody

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
BodyInside:
HeadInside:
WallFeet:
WallBody:
	; !IsMario clear = player Mario-colored; set = player Luigi-colored.
	LDA !IsMario
	BNE Solid
	BRA Air

SpriteV:
SpriteH:
	; Only the Luigi companion uses identity footing; other sprites → air.
	LDA !LuigiIndex
	STA $00
	CPX $00
	BNE Air
	LDA !IsMario
	BEQ Solid			; not swapped → companion is Luigi-colored
	BRA Air

Solid:
	LDY #$01
	LDA #$30
	STA $1693|!addr
Return:
	RTL

Air:
	LDY #$00
	LDA #$25
	STA $1693|!addr
	RTL

print "Solid only for Luigi identity (player or companion). Place on Layer 2."
