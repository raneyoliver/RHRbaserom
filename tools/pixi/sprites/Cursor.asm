
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

; "Level Previewer" by Oliver (based on Cursor by Blind Devil)
; A sprite that can be controlled with the D-pad to view the level. Pauses sprites and animations and hides the player.

;CURSOR SPEED
;Speed which the cursor should move when a button in the D-pad is pressed.
;Applies to all directions.
	!CursorSpd = $40
	!CameraSpdU = #$BF
	!CameraSpdD = #$40
	!CameraSpdL = #$C0
	!CameraSpdR = #$40

;;;;;;;;;;;;;;;;;;;;;;;;;
;Sprite code starts here.
;;;;;;;;;;;;;;;;;;;;;;;;;
print "INIT ",pc
	RTL

print "MAIN ",pc
	PHB : PHK : PLB : JSR SpriteCode : PLB : RTL : SpriteCode:

	;LDA #$01
	;STA $9D

	LDA $D1
	ADC #$04
	STA !E4,x                         ; fix the sprite's position to
	LDA $D2                           ; right on the player's
	STA !14E0,x
	LDA $D3
	STA !D8,x
	LDA $D4
	STA !14D4,x

	JSR HidePlayer

; set mario's movement to nothing
	LDA #$00
	STA $7B
	STA $7D

	JSR ScreenDetect	;subroutine that handles screen range detection.

	JSR Up			;more subroutines.
	JSR Down		;these handle cursor movement
	JSR Left		;depending on the
	JSR Right		;pressed D-pad button.

	LDA $15			;load controller data 1
	AND #$0C		;check if up or down buttons are pressed
	BNE +			;if any of them are pressed, branch ahead.

	STZ !AA,x		;reset sprite Y speed.

+
	LDA $15			;load controller data 1 again
	AND #$03		;check if left or right buttons are pressed
	BNE +			;if any of them are pressed, branch ahead.

	STZ !B6,x		;reset sprite X speed.

+
	JSL $01801A|!BankB	;update ypos no gravity
	JSL $018022|!BankB	;update xpos no gravity

MotherReturn:
	; PHX
	; JSR FreezeSprites
	; PLX

	RTS

Up:
	LDA $15			;load controller data 1
	AND #$08		;check if up button is pressed
	BEQ .ret		;if not pressed, return.

	; Fix camera up?
	LDA #$01
	STA $1404|!Base2
	STA $1406|!Base2

	LDA !151C,x		;load sprite address used for flags
	AND #$08		;check if bit is set (block upwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$0C		;mask up and down buttons - clear all other bits
	CMP #$0C		;check if both buttons are pressed at the same time
	BEQ .zero		;if they are, then zero speed. Done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	EOR #$FF		;flip all bits
	INC A			;increment A value by one
	STA !AA,x		;store to sprite's Y speed.

	; Move player Up
	LDA !CameraSpdU
	STA $7D

.ret
	RTS			;return.

.zero
	STZ !AA,x		;reset sprite Y speed.
	RTS			;return.

Down:

	LDA $15			;load controller data 1
	AND #$04		;check if down button is pressed
	BEQ .ret		;if not pressed, return.

	; Fix camera up?
	LDA #$01
	STA $1404|!Base2
	STA $1406|!Base2

	LDA !151C,x		;load sprite address used for flags
	AND #$04		;check if bit is set (block downwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$0C		;mask up and down buttons - clear all other bits
	CMP #$0C		;check if both buttons are pressed at the same time
	BEQ .zero		;if they are, then zero speed. Done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	STA !AA,x		;store to sprite's Y speed.

	; Move player Down
	LDA !CameraSpdD
	STA $7D

.ret
	RTS			;return.

.zero
	STZ !AA,x		;reset sprite Y speed.
	RTS			;return.

Left:
	LDA !151C,x		;load sprite address used for flags
	AND #$02		;check if bit is set (block leftwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1
	AND #$02		;check if left button is pressed
	BEQ .ret		;if not pressed, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$01		;check if right is pressed
	BNE .zero		;if it is pressed, then zero speed. done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	EOR #$FF		;flip all bits
	INC A			;increment A value by one
	STA !B6,x		;store to sprite's X speed.

	; Move player Left
	LDA !CameraSpdL
	STA $7B

.ret
	RTS			;return.

.zero
	STZ !B6,x		;reset sprite X speed.
	RTS			;return.

Right:
	LDA !151C,x		;load sprite address used for flags
	AND #$01		;check if bit is set (block rightwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1
	AND #$01		;check if right button is pressed
	BEQ .ret		;if not pressed, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$02		;check if left is pressed
	BNE .zero		;if it is pressed, then zero speed. done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	STA !B6,x		;store to sprite's X speed.

	; Move player Right
	LDA !CameraSpdR
	STA $7B

.ret
	RTS			;return.

.zero
	STZ !B6,x		;reset sprite X speed.
	RTS			;return.


;Sprite XY coordinates relative to screen calc subroutine + border detection
;This one you might find interesting! Feel free to rip lol

ScreenDetect:
JSR HorzDetect		;oh yeah
JSR VertDetect		;moar subroutines
RTS			;return.

HorzDetect:
LDA !14E0,x		;load sprite x-pos within level, high byte
XBA			;flip high/low bytes of A
LDA !E4,x		;load sprite x-pos within level, low byte (hooray we got the 16-bit coordinate in A now)
REP #$20		;16-bit A
SEC			;set carry
SBC $1A			;subtract layer 1 x-pos (A now holds sprite x-pos within the screen)

CMP #$0010		;compare A to value
BCC .blockleft		;if lower or equal, set flag to disable going left any further.
CMP #$00EF		;else compare again
BCC .resetbits		;if lower or equal, reset both bits. else it's higher, so we'll set flag to disable going right.

SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$01		;set bit to block going right
BRA .storebits		;branch ahead.

.blockleft
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$02		;set bit to block going left
BRA .storebits		;branch ahead.

.resetbits
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
AND #$FC		;mask bits - clear block left and block right bits
.storebits
STA !151C,x		;store result back.

LDA !B6,x		;load sprite X speed
BEQ .ret		;if equal zero, return.

STZ !B6,x		;reset sprite X speed.
.ret
RTS			;return.

VertDetect:
LDA !14D4,x		;load sprite y-pos within level, high byte
XBA			;flip high/low bytes of A
LDA !D8,x		;load sprite y-pos within level, low byte (hooray we got the 16-bit coordinate in A now)
REP #$20		;16-bit A
SEC			;set carry
SBC $1C			;subtract layer 1 y-pos (A now holds sprite y-pos within the screen)

CMP #$0010		;compare A to value
BCC .blockleft		;if lower or equal, set flag to disable going left any further.
CMP #$00CF		;else compare again
BCC .resetbits		;if lower or equal, reset both bits. else it's higher, so we'll set flag to disable going right.

SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$04		;set bit to block going down
BRA .storebits		;branch ahead.

.blockleft
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$08		;set bit to block going up
BRA .storebits		;branch ahead.

.resetbits
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
AND #$F3		;mask bits - clear block up and block down bits
.storebits
STA !151C,x		;store result back.

LDA !AA,x		;load sprite Y speed
BEQ .ret		;if equal zero, return.

STZ !AA,x		;reset sprite Y speed.
.ret
RTS			;return.

HidePlayer:
; hide mario
	LDA #$FF
	STA $78

; disable interaction w objects
	LDA #$01
	STA $185C|!Base2

; move mario behind sprites, objects
	LDA #$02
	STA $13F9|!Base2

	RTS

FreezeSprites:
	LDX #!SprSize-1		;loop count (loop though all sprite number slots)

.Loop
	LDA !7FAB9E,x		;load this sprite's number
	CMP #$09
	BEQ .next

.action
	LDA #$00
	STA !AA,x
	STA !B6,x

.next
	DEX					;decrement loop count by one
	BPL .Loop			;and loop while not negative.
	RTS					;end? return.