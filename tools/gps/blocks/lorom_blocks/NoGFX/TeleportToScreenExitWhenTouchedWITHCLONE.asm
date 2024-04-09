!CloneIndex = #$1D
!PuzzleCloneIndex =				#$17

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

MarioBelow:
    LDA #$25				; Set to act like block 25, air.
	STA $1693
	LDY #$00
    RTL
MarioAbove:
    LDA #$25				; Set to act like block 25, air.
	STA $1693
	LDY #$00
    RTL
MarioSide:
    LDA #$25				; Set to act like block 25, air.
	STA $1693
	LDY #$00
    RTL

TopCorner:
    LDA #$25				; Set to act like block 25, air.
	STA $1693
	LDY #$00
    RTL
BodyInside:
    LDA #$25				; Set to act like block 25, air.
	STA $1693
	LDY #$00
    RTL
HeadInside:
    JSR CheckIfClone

    LDA $00
    CMP #$FF
    BEQ +

    LDA #$06
    STA $71
    STZ $88
    STZ $89

    ;WallFeet:	; when using db $37
    ;WallBody:

+
    LDA #$25				; Set to act like block 25, air.
	STA $1693
	LDY #$00
    RTL

SpriteV:
SpriteH:

MarioCape:
MarioFireball:
RTL

CheckIfClone:
	LDY #$0B		;loop count (loop though all sprite number slots)

.Loop
	PHX
	LDA !14C8,y		;load sprite status
	CMP #$0B		; check if being carried
	BNE .LoopSprSpr		;if not, keep looping.

	TYX					;transfer Y to X
	LDA !7FAB9E,x		;load sprite number according to index
	CMP !CloneIndex 	;compare with clone index
	BEQ .okay 	;if clone, continue.

	CMP !PuzzleCloneIndex	;if not clone, check puzzle clone
	BNE .LoopSprSpr			;if neither, keep looping

.okay
	
	STZ $00	; 0 if okay to let through
	
	PLX			;restore sprite index
	RTS			;return.

.LoopSprSpr
	PLX			;restore sprite index
	DEY			;decrement loop count by one
	BPL .Loop		;and loop while not negative.

	LDA #$FF
	STA $00

	RTS			;end? return.

print "If carrying a clone (17 or 1D), teleports you to whatever level the screen exit for the current screen is set to."