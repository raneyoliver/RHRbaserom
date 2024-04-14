;!FrozenFlag = $7FA022   ; from uberASM/level/FreezeSpritesOnTrigger.asm
;npc2.asm !TeleportReady
	!TeleportReady = $7FA016

if read1($00FFD5) == $23		; check if the rom is sa-1
	sa1rom
	!SA1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000
	!bankA = $400000
	;!FrozenFlag = $41A022   ; from uberASM/level/FreezeSpritesOnTrigger.asm
	!TeleportReady = $41A016
else
	lorom
	!SA1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!bankA = $7E0000
endif

;Here you define what tiles the cursor will use.
	!CursorTile = $84	;tile used for the cursor.
	!BlockedTile = $86

;clone sprite index from pixi_list
	!CloneIndex = $14

;Animation timer
	!AnimationTimer = !1534,x

;player pos
	!PlayerPosYLow = !1602,x
	!PlayerPosYHigh = !157C,x

;offset
	!Offset = $0011

AccelYSpd:
db $01,$FF

MaxYSpd:
db $0C,$F4

print "MAIN ",pc
PHB
PHK
PLB
JSR SpriteCode
PLB
print "INIT ",pc
RTL

SpriteCode:
	LDA !AnimationTimer
	CMP #$FF
	BEQ +

	LDA #$FF
	STA !AnimationTimer
	STZ !AA,x

	REP #$20
		LDA $D3
		SEC : SBC #!Offset
	SEP #$20
	STA !D8,x
	XBA
	STA !14D4,x
+
	LDA !sprite_tweaker_1686,x			; \ set "don't interact with other sprites" flag
	ORA #$08							; |
	STA !sprite_tweaker_1686,x			; /

	JSL $018022|!BankB		;no gravity position updates
	JSL $01801A|!BankB

	JSR Follow

	LDA $71      ;\ stay still if Mario is dying.
	CMP #$09     ;|
	BEQ .still  ;/

	JSR BobUpAndDown

	BRA .graphics

.still
	STZ !AA,x
.graphics
	JSR DrawGraphicsIfNotTeleporting

	RTS



Follow:
	LDA $D1
	SEC : SBC #$02
	STA !E4,x                         ; fix the sprite's position to
	LDA $D2                           ; right on the player's
	STA !14E0,x

	; if not on ground, just follow player
	LDA $77
	AND #$04
	BEQ .changeY

	LDA $D3
	CMP !PlayerPosYLow
	BNE .changeY

	LDA $D4
	CMP !PlayerPosYHigh
	BEQ .re

.changeY
	REP #$20
		LDA $D3
		SEC : SBC #!Offset
	SEP #$20
	STA !D8,x
	XBA
	STA !14D4,x

	STZ !AA,x
	STZ !151C,x

.re
	LDA $D3
	STA !PlayerPosYLow
	LDA $D4
	STA !PlayerPosYHigh
	RTS

BobUpAndDown:
	; if not on ground, don't change Y
	LDA $77
	AND #$04
	BEQ .NoYSpd

	LDA !151C,x
	AND #$01
	TAY
	LDA !AA,x
	CLC : ADC AccelYSpd,y
	STA !AA,x
	CMP MaxYSpd,y
	BNE .NoYSpd

	INC !151C,x			;change vertical direction

	.NoYSpd
	RTS



DrawGraphicsIfNotTeleporting:
	; don't show cursor if teleport not ready ($7FA016)
	LDA !TeleportReady
	BNE +

	RTS

+
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

	CMP #!CloneIndex ;compare with clone index
	BNE .LoopSprSpr 	;if not clone, keep looping.

	LDA !14C8,x
	CMP #$05
	BCS .alive

	CMP #$01
	BEQ .noGraphics

.killed
	JSL $00F606|!bank     ;kill mario

.alive
	LDA !1504,x	;!State from npc2.asm, 02 is teleporting
	AND #$03
	CMP #$02
	BNE .drawGraphics

.noGraphics
	PLX
	RTS

.drawGraphics
	PLX			;restore sprite index.
	JSR DrawGraphics
	RTS			;return.

.LoopSprSpr
	PLX			;restore sprite index
	DEY			;decrement loop count by one
	BPL .Loop		;and loop while not negative.
	RTS			;end? return.


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
;STA $0200|!Base2,y	;store to OAM.
STA $0300|!Base2,y	;store to OAM.

LDA $01			;get sprite Y-pos from scratch RAM
CLC			;clear carry
ADC #!YDisp		;add Y displacement
;STA $0201|!Base2,y	;store to OAM.
STA $0301|!Base2,y

;LDA !FrozenFlag
;BNE +

LDA #!CursorTile	;load tile value (normal cursor)
;BRA ++

;+
;LDA #!BlockedTile
;++
;STA $0202|!Base2,y	;store to OAM.
STA $0302|!Base2,y

LDA !15F6,x		;load palette/properties from CFG
ORA $64			;set priority bits from level
;STA $0203|!Base2,y	;store to OAM.
STA $0303|!Base2,y

LDY #$02
LDA #$00
JSL $01B7B3|!BankB

RTS

;PHY			;preserve Y
;TYA			;transfer Y to A
;LSR #2			;divide by 2 twice
;TAY			;transfer A to Y
;LDA #$02		;load value (tile is set to 16x16)
;ORA !15A0,x		;horizontal offscreen flag
;STA $0420|!Base2,y	;store to OAM (new Y index).
;PLY			;restore Y
;RTS			;return.

;mind these OAM values and codes - they have the highest priority, so tiles will appear in front of other sprites and Mario as well.
