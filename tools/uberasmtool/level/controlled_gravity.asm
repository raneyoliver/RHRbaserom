;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Controlled Gravity
;
; Press a button from the controller to modify gravity.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  _____________________________  ;
; /								\ ;
;|		CONTROLLED GRAVITY		 |;
;|								 |;
;|    Press a button from the	 |;
;| controller to modify gravity. |;
; \_____________________________/ ;
;								  ;

!flip_gravity		= $10F5D6 ;$10D1E0
!FreeRAM			= $60

;>  RAM containing the set of buttons you want to check. (Should be $16 or $18) 

!ControlRAM	= $18

;>  Replace with a 1 for the button you want to switch gravity.
; ¬ Do note that "y" means Y and X.
;>  For $16: byetUDLR
;>  For $18: axlr----
!Button	 = #%00100000

;>  b = B only; y = X or Y; e = select; t = Start; U = up; D = down; L = left, R = right
;>  a = A; x = X; l = L; r = R, - = unused

main:	lda !ControlRAM
		and !Button
		sta !FreeRAM
		beq .return
		
		JSL !flip_gravity
		LDA $7D
		EOR #$FF
		INC
		STA $7D
		
.return	RTL