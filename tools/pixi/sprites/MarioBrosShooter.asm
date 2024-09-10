;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Random Sprite Shooter
;; by Sonikku
;; Description: Spawns a single random sprite from a customizable list, with the potential for up to 255.
;; If X = 0, sprites will be sent moving left. If X = 1, they will move right instead.
;; 
;; By default, this shooter assumes that Fighter Flies are BD, Spinies at BF, and Side Steppers at BE.
;; This should be easy enough to customize as needed.

!NumOfSprites	= $01		; number of sprite possibilities to choose from, plus 1 (i.e. $06 would be 6 possibilities)
				; setting it to $00 will cause it to not spawn any sprites, so don't do that.
				; "SpriteNum" table indicates the custom sprite number to spawn
				; "Color" table indicates which color value the sprite is
				; "State" table indicates the normal/angered state
				;;;; - Spiny and Fighter Fly should only be $00.
				;;;; - Side Stepper can be $00 or $01.

SpriteNum:	db $BF
Color:		db $00
State:		db $00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	print "INIT ",pc
	LDA !E4,x
	LSR #4
	AND #$01
	BEQ +
	LDA #$C0
	LSR
	STA !154C,x
+
	print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR ShooterRoutine
	PLB
	RTL
	
ShooterRoutine:
	WDM #$01
	; LDA $17AB|!Base2,x	; \ return if timer is set
	LDA $14
	AND #$01
	BEQ +
	LDA !154C,x
	CLC : ADC #$01
	STA !154C,x
+
	LDA !154C,x
	BNE .return		; /
	; LDA $1793|!Base2,x	; \
	; XBA			;  | 
	; LDA $178B|!Base2,x	;  | 
	; REP #$20		;  | 
	; SEC			;  | return if shooter is offscreen vertically
	; SBC $1C			;  | 
	; CMP #$00A0		;  | 
	; SEP #$20		;  | 
	; BCS .return		; /
	; LDA $17A3|!Base2,x	; \
	; XBA			;  | 
	; LDA $179B|!Base2,x	;  | 
	; REP #$20		;  | 
	; SEC			;  | 
	; SBC $1A			;  | return if shooter is offscreen horizontally
	; CLC			;  | 
	; ADC #$0010		;  | 
	; CMP #$0100		;  | 
	; SEP #$20		;  | 
	; BCS .return		; /
	JSR SpawnSprite
	; LDA #$C0		; \ set timer
	; STA $17AB|!Base2,x	; /
	LDA #$C0
	STA !154C,x
.return	RTS			; 

SpawnSprite:
	LDA #!NumOfSprites	;\ return it it doesn't spawn anything
	BEQ .return		;   /
	JSL $02A9DE|!BankB	; \ don't spawn if no slots
	BMI .return		; /
	PHX			; 
	TYX			; 
	LDA #$08		; \ normal state
	STA !14C8,x		; /

	PHY			; 
; -	JSL $01ACF9|!BankB	; \
; 	EOR $13			;  | 
; 	SBC $94			;  | mess with the regular RNG a bit
; 	ORA $16			;  | 
; 	ADC !E4,x		;  | 
; 	INC			; /
; 	CMP #!NumOfSprites
; 	BCS -			; 
	LDA #$00
	STA $0F			; 
	TAY			; 
	LDA SpriteNum,y		; \ sprite number
	STA !7FAB9E,x		; /
	PLY

	JSL $07F7D2|!BankB	; \ initialize
	JSL $0187A7|!BankB	; /

	LDA #$88		; \ mark as custom sprite
	STA !7FAB10,x		; /

	PHY			; 
	LDY $0F			; \
	LDA Color,y		;  | set color
	STA !1594,x		; /

	LDA State,y		; \ set state
	STA !C2,x		; /
	PLY			; 

	LDA #$20		; \ "come out of pipe" timer
	STA !163E,x		; /

	STZ !1510,x		; don't make it think it was on the ground
	PLX			; 

	; LDA $179B|!Base2,x	; \
	LDA !E4,x
	LSR #4			;  | set sprite direction based on shooter location
	AND #$01		;  | (even = fire left, odd = fire right)
	;EOR #$01		;  | 
	STA !157C,y		; /

	; LDA $179B|!Base2,x	; \
	LDA !E4,x
	STA.w !E4,y		;  | set x position
	; LDA $17A3|!Base2,x	;  | 
	LDA !14E0,x
	STA.w !14E0,y		; /

	; LDA $178B|!Base2,x	; \
	LDA !D8,x
	SEC			;  | 
	SBC #$03		;  | 
	STA !D8,y		;  | set y position
	; LDA $1793|!Base2,x	;  | 
	LDA !14D4,x
	SBC #$00		;  | 
	STA !14D4,y		; /
.return
	RTS			; 