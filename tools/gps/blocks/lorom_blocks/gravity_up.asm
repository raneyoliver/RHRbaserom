;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Gravity Up
;
; Forces upward gravity when the player is inside.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

db $42

JMP Main : JMP Main : JMP Main : JMP Return : JMP Return : JMP Return : JMP Return : JMP Main : JMP Main : JMP Main

!flip_gravity		= $90D181
!reversed		= $60

Main:		LDA !reversed
		BNE Return
		JSL !flip_gravity
		LDA $7D
		EOR #$FF
		INC
		STA $7D
Return:		RTL