; Mario will only be able to pass if he is carrying an item.
; Act like block 25.
; Created by E-Man, requested by mapsking.

;clone sprite index from pixi_list
	!PuzzleCloneIndex =				#$17
	!CloneIndex =					#$14

print "A block where it will only let the player pass if he is carrying a clone or puzzle clone."

db $42						
JMP Mario : JMP Mario : JMP Mario
JMP Cement : JMP Cement : JMP Cement : JMP Cement
JMP Mario : JMP Mario : JMP Mario

Mario:
	LDA $1470	
	ORA $148F
	BEQ Cement	; carrying nothing -> auto cement

	JSR CheckIfClone	; loads 0 if clone carried

	LDA $00
	BNE Cement	; if 0, clone carried. keep gate open

.passThrough
	LDA #$25				; Set to act like block 130, cement block.
	STA $1693
	LDY #$00

	RTL

Cement:
	; if clone not carried, set to cement block
	LDA #$30				; Set to act like block 130, cement block.
	STA $1693
	LDY #$01
	RTL









CheckIfClone:
	LDY #$0B		;loop count (loop though all sprite number slots)

.Loop
	PHX
	LDA !14C8,y		;load sprite status
	CMP #$0B		; check if being carried
	BNE .LoopSprSpr		;if not, keep looping.

	;TXA			;transfer X to A (sprite index)
	;STA $08			;store it to scratch RAM.
	;TYA			;transfer Y to A
	;CMP $08			;compare with sprite index
	;BEQ .LoopSprSpr		;if equal, keep looping.

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
