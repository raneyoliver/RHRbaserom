	!CursorTile = $C0	;tile used for the cursor.
	!CursorPress = $E0	;tile used for the cursor when clicking.


	!PlayerPosXLow =	$D1
	!PlayerPosXHigh =	$D2
	!PlayerPosYLow =	$D3
	!PlayerPosYHigh =	$D4


;;;;;;;;;;;;;;;;;;;;;;;;;
;Sprite code starts here.
;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR SpriteCode
PLB
print "INIT ",pc
RTL

SpriteCode:
	JSR GetContact
	;JSR DrawGraphics
	RTS

GetContact:
	LDY #!SprSize-1		;loop count (loop though all sprite number slots)

.Loop
	PHX
	LDA !14C8,y		;load sprite status
	BEQ .LoopSprSpr		;if non-existant, keep looping.

	LDA !7FAB9E,x		;load this sprite's number
	STA $07			;store to scratch RAM.
	TXA			;transfer X to A (sprite index)
	STA $08			;store it to scratch RAM.
	TYA			;transfer Y to A
	CMP $08			;compare with sprite index
	BEQ .LoopSprSpr		;if equal, keep looping.

	TYX			;transfer Y to X
	LDA !7FAB9E,x		;load sprite number according to index
	CMP $07			;compare with cursor's number from scratch RAM
	BEQ .LoopSprSpr		;if equal, keep looping.

	PLX			;restore sprite index.	X is this sprite, Y is other sprite

	JSR PlayerXDistance
	LDA $01
	BNE .spriteCheck

	JSR PlayerYDistance
	LDA $01
	BEQ .playerContact

.spriteCheck

	JSL $03B6E5|!BankB	;get sprite A clipping (this sprite)
	PHX					;preserve sprite index
	TYX					;transfer Y to X
	JSL $03B69F|!BankB	;get sprite B clipping (interacted sprite)
	JSL $03B72B|!BankB	;check for contact
	BCC .LoopSprSpr		;if carry is not set, there's contact

.contact
	PLX			;restore sprite index
.playerContact
	REP #$20
	LDA $7FC0FC
	ORA #$0001		;trigger 0 = 1st bit = 2^0 = #$1
	STA $7FC0FC
	SEP #$20

	;JSR ChangeGraphic
	
	RTS			;return.

.LoopSprSpr
	PLX			;restore sprite index
	DEY			;decrement loop count by one
	BPL .Loop		;and loop while not negative.

	REP #$20
	LDA $7FC0FC
	AND	#$0001^$FFFF	; invert the value to set it to 0.
	STA $7FC0FC
	SEP #$20

	RTS			;end? return.


ChangeGraphic:
	; input:
	; $98-$99 block position Y
	; $9A-$9B block position X
	; $1933   layer
	;
	; Usage:
	; REP #$20
	; LDA #!block_number
	; %change_map16()

	LDA !D8,x
	STA $98
	LDA !14D4,x
	STA $99
	LDA !E4,x
	STA $9A
	LDA !14E0,x
	STA $9B

	LDA #$00
	STA $1933

	REP #$20
	LDA #$2DC6
	%ChangeMap16()
	RTS


PlayerXDistance:

	LDA !14E0,x                             ; \
	XBA                                     ;  | calculate the distance
	LDA.w !E4,x                             ;  | between the player and the sprite
	REP #$20                                ;  |
	SEC : SBC $D1                           ;  |
	STA $00                                 ; /

	BPL + : EOR #$FFFF : INC : +
	CMP #$0010
	SEP #$20
	BCS .notCloseEnough
.closeEnough
	STZ $01
	RTS
.notCloseEnough
	LDA #$FF
	STA $01
.return
	RTS


PlayerYDistance:

	LDA !14D4,x
	XBA
	LDA.w !D8,x
	REP #$20
	SEC : SBC $D3
	STA $00

	BPL + : EOR #$FFFF : INC : +
	
	CMP #$0021
	SEP #$20
	BCS .notCloseEnough
.closeEnough
	STZ $01
	RTS
.notCloseEnough
	LDA #$FF
	STA $01
.return
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;
;Graphics routine below.
;;;;;;;;;;;;;;;;;;;;;;;;

DrawGraphics:
!XDisp = $02		;tile X displacement.
!YDisp = $02		;tile Y displacement.

%GetDrawInfo()

LDA $00			;get sprite X-pos from scratch RAM
CLC			;clear carry
ADC #!XDisp		;add X displacement
STA $0200|!Base2,y	;store to OAM.

LDA $01			;get sprite Y-pos from scratch RAM
CLC			;clear carry
ADC #!YDisp		;add Y displacement
STA $0201|!Base2,y	;store to OAM.

LDA !15AC,x		;load click timer
BNE +			;if not zero, branch.

LDA #!CursorTile	;load tile value (normal cursor)
BRA ++			;and branch ahead.
+

LDA #!CursorPress	;load tile value (pressed cursor)
++
STA $0202|!Base2,y	;store to OAM.

LDA !15F6,x		;load palette/properties from CFG
ORA $64			;set priority bits from level
STA $0203|!Base2,y	;store to OAM.

PHY			;preserve Y
TYA			;transfer Y to A
LSR #2			;divide by 2 twice
TAY			;transfer A to Y
LDA #$02		;load value (tile is set to 16x16)
ORA !15A0,x		;horizontal offscreen flag
STA $0420|!Base2,y	;store to OAM (new Y index).
PLY			;restore Y
RTS			;return.

;mind these OAM values and codes - they have the highest priority, so tiles will appear in front of other sprites and Mario as well.
