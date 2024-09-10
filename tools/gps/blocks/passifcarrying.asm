
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

; Mario will only be able to pass if he is carrying an item.
; Act like block 25.
; Created by E-Man, requested by mapsking.

;clone sprite index from pixi_list
	!CloneIndex =		$14

print "A block where it will only let the player pass if he is carrying a clone or puzzle clone."

db $37
JMP Mario : JMP Mario : JMP Mario
JMP Sprite : JMP Sprite : JMP Cement : JMP Cement
JMP Mario : JMP Mario : JMP Mario
JMP Mario : JMP Mario ; when using db $37


Mario:
	LDA $1470|!addr
	ORA $148F|!addr
	BEQ Cement	; carrying nothing -> auto cement

	JSR CheckIfClone	; loads 0 if clone carried

	LDA $00
	BNE Cement	; if 0, clone carried. keep gate open

.passThrough
	LDA #$25				; Set to act like block 130, cement block.
	STA $1693|!addr
	LDY #$00

	RTL

Sprite:
	LDA !7FAB10,x
	AND #$08
	BNE .isCustom

.vanilla
	BRA Mario_passThrough

.isCustom
	LDA !7FAB9E,x
	CMP #!CloneIndex
	BNE Mario_passThrough

Cement:
	; if clone not carried, set to cement block
	LDA #$30				; Set to act like block 130, cement block.
	STA $1693|!addr
	LDY #$01
	RTL









CheckIfClone:
	LDY #!sprite_slots-1		;loop count (loop though all sprite number slots)

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
	CMP #!CloneIndex 	;compare with clone index
	BNE .LoopSprSpr 	;if clone, next

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
