
if read1($00FFD5) == $23		; check if the rom is sa-1
	sa1rom
	!SA1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000
	!bankA = $400000
else
	lorom
	!SA1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!bankA = $7E0000
endif

!CloneIndex = $14
!DeadTopLeftTile        		= $0A

; By SJandCharlieTheCat

db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
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
	LDA $14AF|!addr	;\ If On/Off Switch is Off, Return
	BEQ Return	;/
	JSL $00F606|!bank	; Change $00F606 with $00F5B7 if you want it to hurt the player instead of killing.
    RTL
SpriteV:
SpriteH:
    LDA $14AF|!addr
    BEQ Return
	LDY #$10	;act like tile 130
	LDA #$30
	STA $1693|!addr

	LDA !7FAB9E,x
	CMP #!CloneIndex
	BNE Return

	LDA !14C8,x
	CMP #$0B
	BEQ Return

	JSR SetFrameDead
	LDA #$03
	STA !14C8,x
	JSL $00F606|!bank	; Change $00F606 with $00F5B7 if you want it to hurt the player instead of killing.

MarioCape:
MarioFireball:
Return:
	RTL

SetFrameDead:
	LDA #!DeadTopLeftTile
	STA !1570,x
	RTS

print "An on-off death block, solid when the switch is on."