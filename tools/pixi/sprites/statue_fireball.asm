
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Bowser Statue Fireball Disassembly, by imamelia
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SND_fire = $17
!BNK_fire = $1DFC|!Base2	; "fire" sound effect

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
	LDA #!SND_fire
	STA !BNK_fire
	%SubHorzPos()
	TYA
	STA !157C,x	; face the player
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR StatueFireballMain
	PLB
RTL

StatueFireSpeed:	db $10,$F0

StatueFireDispX:                  db $08,$00,$00,$08

;StatueFireTiles:                  db $32,$50,$33,$34,$32,$50,$33,$34
StatueFireTiles:                  db $65,$64,$66,$67,$65,$64,$66,$67
StatueFireGfxProp:                db $09,$09,$09,$09,$89,$89,$89,$89

StatueFireballMain:
	JSR SubFireballGFX		; draw the sprite
	LDA $9D			; if the sprite lock timer is set...
	BNE Return		; return
	%SubOffScreen()
	JSL $01A7DC|!bank		; interact with the player
	LDY !157C,x		; load the sprite direction into Y...
	LDA StatueFireSpeed,y	; set the fireball's speed
	STA !B6,x			; based on its direction
	JSL $018022|!bank		; update sprite X position without gravity
Return:
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubFireballGFX:
	%GetDrawInfo()	; set up scratch RAM and the Y register
	LDA !157C,x		; load the sprite direction..
	ASL			; multiply that by 2...
	STA $02			; and store to scratch RAM
	LDA $14			; load sprite frame counter
	LSR			; divide by 2
	AND #$03		; clear out upper 6 bits
	ASL			; multiply by 2
	STA $03			; store to more scratch RAM

	PHX			; preserve sprite index
	LDX #$01			; load 01 into X *because the fireball has 2 tiles*
GFX_Loop:
	LDA $01			; load sprite Y position relative to screen border
	STA $0301|!addr,y		; store to second slot of OAM tables
	PHX			; preserve X again...for unknown reasons
	TXA			; transfer X to A (X=01/00)
	ORA $02			; add in the sprite's direction
	TAX			; and transfer A back to X
	LDA $00			; load sprite X position relative to screen border
	CLC
	ADC StatueFireDispX,x	; add the tile's X displacement
	STA $0300|!addr,y		; store to first slot of OAM tables
	PLA			; pull A, A=01/00
	PHA			; push this value
	ORA $03			; add in the value from the frame counter
	TAX			; and put it into X
	LDA StatueFireTiles,x	; load the tilemap, tile depends on this value
	STA $0302|!addr,y		; store to second slot of OAM tables
	LDA StatueFireGfxProp,x	; load the tile properties from the table
	LDX $02			; load the sprite's direction...
	BNE NoFlip		; if the sprite is facing left, then there is no need to flip the tile
	EOR #$40			; if the sprite is facing right, then flip this tile
NoFlip:			;
	ORA $64			; add in the level's priority bits
	STA $0303|!addr,y		; store to the fourth slot of the OAM tables
	PLX			; pull X, X=01/00
	INY
	INY
	INY
	INY			; increment Y 4 times in order to get to the next slot of the OAM
	DEX			; decrement X (now we know why that LDX #$01 was there!)
	BPL GFX_Loop		; if X is still positive (X=00), loop the code and draw another tile

	PLX			; get sprite index back
	LDY #$00			; the tiles are 8x8...
	LDA #$01			; we drew 2 tiles...
	JSL $01B7B3|!bank		; finish off the OAM-writing routine
RTS			; and return from the graphics routine