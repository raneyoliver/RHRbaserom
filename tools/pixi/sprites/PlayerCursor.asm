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
	!TileIndex = $41A02D
	!CursorTile = $84	;tile used for the cursor.
	!BlockedTile = $86

;clone sprite index from pixi_list
	!CloneIndex = $14
	!CloneIsMario = $41A026


;Animation timer
	!AnimationTimer = !1534,x

;player pos
	!PlayerPosYLow = !1602,x
	!PlayerPosYHigh = $41A02C

;offset
	!Offset = $0011

print "MAIN ",pc
PHB
PHK
PLB
JSR SpriteCode
PLB
print "INIT ",pc
RTL

Tilemap:
	db 	$84, $A0, $A2, $A4, $C0, $C2
	;		 U    D    UD   H    DD

SpriteCode:
	JSR OffscreenRoutine
	BCS .graphics

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

OffscreenRoutine:
	JSR GetCloneIndex

	LDA !15A0,y	;horiz
	BNE .horizontal

	LDA !186C,y	;vert
	BEQ .onScreenReturnBridge

.vertical
	; If vert: set Y to min/max depending on side, set X to clone X (should always be in bounds already)
	PHX
	PHY
	TYX
	%SubVertPos()	; Y = 1 if mario below sprite??
	TYA
	PLY
	PLX
	CMP #$00
	BEQ ..maxY

..minY
	LDA #$01
	STA !TileIndex
	REP #$20
	LDA $1464|!addr ;layer 1 y pos low-byte (highest point of screen)
	SEP #$20
	BRA ..storeValue

..maxY
	LDA #$02
	STA !TileIndex
	REP #$20
	;layer 1 y pos low-byte + screen height (lowest point of screen)
	LDA $1464|!addr
	CLC : ADC #$00E0
	SEC : SBC #$0020 ; arbitrary offset so I can see the sprite at the bottom
	SEP #$20
..storeValue
	STA !D8,x
	XBA
	STA !14D4,x
..cloneX
	LDA !E4,y
	STA !E4,x
	LDA !14E0,y
	STA !14E0,x
	;BRA .offScreenReturn too far
;".offScreenReturn"
	SEC
	RTS

.onScreenReturnBridge
	;BRA .onScreenReturn too far
	LDA #$00
	STA !TileIndex
	CLC
	RTS

.horizontal
	; If horiz: set X to min/max depending on side, set Y to clone Y (within bounds)
	PHX
	TYX
	PHY
	%SubHorzPos()	;Output: Y   = 0 => Mario to the right of the sprite,
;              						1 => Mario being on the left.
	TYA
	PLY
	PLX
	STA $0E
..minX
	LDA #$01
	STA !157C,x

	REP #$20
	LDA $1462|!addr	; Layer 1 X position low-byte
	SEP #$20
	STA !E4,x
	XBA
	STA !14E0,x
	
	LDA $0E
	BEQ ..cloneY

..maxX
	LDA #$00
	STA !157C,x

	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	CLC : ADC #$00E8
	SEP #$20
	STA !E4,x
	XBA
	STA !14E0,x

..cloneY
	LDA !14D4,y
	XBA
	LDA !D8,y
	SEC : SBC #$10
	REP #$20
	STA $01	; contains y pos of clone
	CMP $1464|!addr
	SEP #$20
	BCC ..minY

	REP #$20
	LDA $1464|!addr
	CLC : ADC #$00E0
	STA $03
	CMP $01
	SEP #$20
	BCC ..maxY		; clone still lower than lowest screen pixel

..notDiagonal
	LDA #$04
	STA !TileIndex

	REP #$20
	LDA $01			;clone y
	SEP #$20
	BRA ..storeValue

..minY
	LDA #$03
	STA !TileIndex

	REP #$20
	LDA $1464|!addr ;layer 1 y pos low-byte (highest point of screen)
	SEP #$20
	BRA ..storeValue

..maxY
	LDA #$05
	STA !TileIndex

	REP #$20
	LDA $03			;layer 1 y pos low-byte + screen height (lowest point of screen)
	SEC : SBC #$0020 ; arbitrary offset so I can see the sprite at the bottom
	SEP #$20
..storeValue
	STA !D8,x
	XBA
	STA !14D4,x
	BRA .offScreenReturn

.onScreenReturn
	LDA #$00
	STA !TileIndex
	CLC
	RTS

.offScreenReturn
	SEC
	RTS

GetCloneIndex:
	PHX
	LDY #!SprSize-1
.loop
	TYX
	LDA !7FAB9E,x
	CMP #!CloneIndex
	BEQ .return

.next
	DEY
	BPL .loop

.return
	PLX
	RTS

Follow:
	LDA $D1
	SEC : SBC #$02
	STA !E4,x                         ; fix the sprite's position to
	LDA $D2                           ; right on the player's
	STA !14E0,x

	; check if cursor is too low w.r.t mario
	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	SEC : SBC $D3
	SEP #$20
	BMI .notTooLow

	CMP #$02	; should only go as low as 2 pixels above mario
	BCC .changeY

.notTooLow
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

AccelYSpd:
db $01,$FF

MaxYSpd:
db $0C,$F4


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

PHX
LDA !TileIndex
TAX
LDA Tilemap,x	;load tile value
PLX
;BRA ++

;+
;LDA #!BlockedTile
;++
;STA $0202|!Base2,y	;store to OAM.
STA $0302|!Base2,y

LDA !157C,x             ; Load sprite direction.
STA $03

LDA !15F6,x		;load palette/properties from CFG
ORA $64			;set priority bits from level
PHX
LDX $03
BNE NoFlip              ; If facing left, don't flip the tile.
EOR #$40                ; If facing right, flip the tile horizontally.

NoFlip:
AND #$F1
STA $03
LDA !CloneIsMario       ; Load the CloneIsMario flag
AND #$01                ; Isolate bit 0
BEQ SetPaletteF         ; If bit 0 is 0, set palette F

; If bit 0 is 1, set palette E
LDA $03
ORA #$0C                ; Set the CCC bits to 110 (Palette E)
BRA StoreProperties     ; Skip to storing the properties

SetPaletteF:
LDA $03
ORA #$0E                ; Set the CCC bits to 111 (Palette F)

StoreProperties:
PLX
STA $0303|!Base2,y      ; Store properties to OAM.

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
