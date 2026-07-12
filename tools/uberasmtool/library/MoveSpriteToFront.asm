; macro define_sprite_table(name, addr, addr_sa1)
; 	if !SA1 == 0
; 		!<name> = <addr>
; 	else
; 		!<name> = <addr_sa1>
; 	endif
; endmacro

; macro define_base2_address(name, addr)
; 	if !SA1 == 0
; 		!<name> = <addr>
; 	else
; 		!<name> = <addr>|!addr
; 	endif
; endmacro
;sprite tool / pixi defines
%define_sprite_table("7FAB10",$7FAB10,$6040)
%define_sprite_table("7FAB1C",$7FAB1C,$6056)
%define_sprite_table("7FAB28",$7FAB28,$6057)
%define_sprite_table("7FAB34",$7FAB34,$606D)
%define_sprite_table("7FAB9E",$7FAB9E,$6083)
%define_sprite_table("7FAB40",$7FAB40,$6099)
%define_sprite_table("7FAB4C",$7FAB4C,$60AF)
%define_sprite_table("7FAB58",$7FAB58,$60C5)
%define_sprite_table("7FAB64",$7FAB64,$60DB)

%define_sprite_table("7FAC00",$7FAC00,$60F1)
%define_sprite_table("7FAC08",$7FAC08,$6030)
%define_sprite_table("7FAC10",$7FAC10,$6038)

;normal sprite defines

%define_sprite_table("9E", $9E, $3200)
%define_sprite_table("AA", $AA, $9E)
%define_sprite_table("B6", $B6, $B6)
%define_sprite_table("C2", $C2, $D8)
%define_sprite_table("D8", $D8, $3216)
%define_sprite_table("E4", $E4, $322C)
%define_sprite_table("14C8", $14C8, $3242)
%define_sprite_table("14D4", $14D4, $3258)
%define_sprite_table("14E0", $14E0, $326E)
%define_sprite_table("14EC", $14EC, $74C8)
%define_sprite_table("14F8", $14F8, $74DE)
%define_sprite_table("1504", $1504, $74F4)
%define_sprite_table("1510", $1510, $750A)
%define_sprite_table("151C", $151C, $3284)
%define_sprite_table("1528", $1528, $329A)
%define_sprite_table("1534", $1534, $32B0)
%define_sprite_table("1540", $1540, $32C6)
%define_sprite_table("154C", $154C, $32DC)
%define_sprite_table("1558", $1558, $32F2)
%define_sprite_table("1564", $1564, $3308)
%define_sprite_table("1570", $1570, $331E)
%define_sprite_table("157C", $157C, $3334)
%define_sprite_table("1588", $1588, $334A)
%define_sprite_table("1594", $1594, $3360)
%define_sprite_table("15A0", $15A0, $3376)
%define_sprite_table("15AC", $15AC, $338C)
%define_sprite_table("15B8", $15B8, $7520)
%define_sprite_table("15C4", $15C4, $7536)
%define_sprite_table("15D0", $15D0, $754C)
%define_sprite_table("15DC", $15DC, $7562)
%define_sprite_table("15EA", $15EA, $33A2)
%define_sprite_table("15F6", $15F6, $33B8)
%define_sprite_table("1602", $1602, $33CE)
%define_sprite_table("160E", $160E, $33E4)
%define_sprite_table("161A", $161A, $7578)
%define_sprite_table("1626", $1626, $758E)
%define_sprite_table("1632", $1632, $75A4)
%define_sprite_table("163E", $163E, $33FA)
%define_sprite_table("164A", $164A, $75BA)
%define_sprite_table("1656", $1656, $75D0)
%define_sprite_table("1662", $1662, $75EA)
%define_sprite_table("166E", $166E, $7600)
%define_sprite_table("167A", $167A, $7616)
%define_sprite_table("1686", $1686, $762C)
%define_sprite_table("186C", $186C, $7642)
%define_sprite_table("187B", $187B, $3410)
%define_sprite_table("190F", $190F, $7658)

%define_sprite_table("1938", $7FAF00, $418A00)
%define_sprite_table("7FAF00", $7FAF00, $418A00)

%define_sprite_table("1FD6", $1FD6, $766E)
%define_sprite_table("1FE2", $1FE2, $7FD6)

; This UberASM moves the clone sprite to the NEW sprite slot available.
; This is to prevent any sprite from appearing in front of the clone.
; Also syncs any clone-held sprite's position before sprites draw (no trail).

; The list of sprite tables are:
; !E4, !14E0, !D8, !14D4, !AA, !B6, !C2, !1504, !1510, !151C,
; !1528, !1534, !1540, !154C, !1558, !1564, !1570, !157C, !1594,
; !15AC, !15D0, !15F6, !1602, !160E, !1626, !163E, !187B

!SprSize = $16
!SpriteTablesRAM = $41BB00 ; arbitrary address to store the sprite tables
!CloneSpriteSlot = $00
!NewSpriteSlot = $01
!CloneSpriteNumber = $14 ; from pixi_list.txt
!CloneIndex = $41A01A
!CloneCarriedItemIndex = $41B82E

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

macro store_using_y_index(addr)
	PHX
	TYX
	STA <addr>,x
	PLX
endmacro

init:
	RTL

main:
	JSR GetSpriteSlots
	LDA !CloneSpriteSlot
	CMP #$FF
	BEQ .return		; if no sprite slot was saved, return

	CMP !NewSpriteSlot
	BEQ .updateCloneIndex	; if the clone sprite slot is the NEW sprite slot, no swap needed

	; Put the NEW sprite tables into RAM:
	PHX
	LDX !NewSpriteSlot
	JSR MoveAllSpriteTablesToRAM
	PLX

	; Put the clone sprite into the NEW sprite slot:
	PHX
	JSR MoveSpriteTablesToAnotherSpriteSlot
	PLX

	; Put the NEW sprite tables from RAM into the original clone sprite slot:
	PHX
	LDX !CloneSpriteSlot
	JSR GetAllSpriteTablesFromRAM
	PLX

	; If the front-slot sprite was held by the clone, it moved into the
	; clone's old slot during the swap.
	LDA !CloneCarriedItemIndex
	CMP !NewSpriteSlot
	BNE +
	LDA !CloneSpriteSlot
	STA !CloneCarriedItemIndex
+
	LDA !NewSpriteSlot
	STA !CloneSpriteSlot

.updateCloneIndex
	LDA !CloneSpriteSlot
	STA !CloneIndex
	JSR HandleCloneCarriedItemPosition
.return
	RTL

; Sets position of clone carried item before sprites draw.
; Free-moving clone: project with !B6/!AA.
; Mario-carried clone ($0B): attach to clone pos; X uses Mario $94-$D1 delta (no jitter).
HandleCloneCarriedItemPosition:
	LDA $9D
	BEQ +
	JMP .return
+
	LDA !CloneCarriedItemIndex
	CMP #$FF
	BNE +
	JMP .return
+
	TAY
	LDA !CloneIndex
	TAX
	LDA !14C8,x
	CMP #$0B
	BNE .projectFreeClone
	JMP .marioCarryingClone

.projectFreeClone
	LDA !157C,x 		; set item's direction to clone's direction
	%store_using_y_index(!157C)

	; Save direction-table offset.
	ASL ; multiply x by 2 because of 16-bit addressing
	STA $00 ; save offset for later

	; Project the clone's X fixed-point position through this frame's speed.
	; Sprite speed is in 1/16-pixel units; fractions are in 1/256 pixels.
	LDA !B6,x
	STA $02
	STZ $03
	REP #$20
	LDA $02
	AND #$00FF
	CMP #$0080
	BCC +
	ORA #$FF00
+	ASL #4
	STA $02
	SEP #$20
	LDA !14F8,x
	STA $04
	STZ $05
	REP #$20
	LDA $04
	CLC : ADC $02
	STA $04
	SEP #$20

	; Store projected X fraction.
	LDA $04
	%store_using_y_index(!14F8)

	; Sign-extend the whole-pixel part of the projected X movement.
	LDA $05
	STA $06
	STZ $07
	BPL +
	DEC $07
+

	; Set item's X to projected clone X plus facing offset.
	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	CLC : ADC $06
	PHX ; save clone index
	LDX $00 ; load offset
	CLC : ADC CarriedItemXPosOffset,x
	SEP #$20
	%store_using_y_index(!E4)
	XBA
	%store_using_y_index(!14E0)
	PLX ; restore clone index

	; Project the clone's Y fixed-point position through this frame's speed.
	LDA !AA,x
	STA $02
	STZ $03
	REP #$20
	LDA $02
	AND #$00FF
	CMP #$0080
	BCC +
	ORA #$FF00
+	ASL #4
	STA $02
	SEP #$20
	LDA !14EC,x
	STA $04
	STZ $05
	REP #$20
	LDA $04
	CLC : ADC $02
	STA $04
	SEP #$20

	; Store projected Y fraction.
	LDA $04
	%store_using_y_index(!14EC)

	; Sign-extend the whole-pixel part of the projected Y movement.
	LDA $05
	STA $06
	STZ $07
	BPL +
	DEC $07
+

	; Set item's Y to projected clone Y minus one pixel.
	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	CLC : ADC $06
	SEC : SBC #$0001 ; subtract 1 in 16-bit mode
	SEP #$20
	%store_using_y_index(!D8)
	XBA
	%store_using_y_index(!14D4)

	LDA #$00
	%store_using_y_index(!B6)
	%store_using_y_index(!AA)
	JMP .return

; Luigi is status $0B: moved by Mario's carry code, not !B6/!AA.
.marioCarryingClone
	; Face with Mario: $76 0=left/1=right, !157C 0=right/1=left.
	LDA $76
	EOR #$01
	%store_using_y_index(!157C)
	ASL
	STA $00				; XPosOffset table index

	; Predict Luigi's next whole-pixel X with Mario's exact position delta.
	REP #$20
	LDA $94
	SEC : SBC $D1
	STA $02
	SEP #$20

	; Carried Luigi does not accumulate a sprite fraction; keep both equal.
	LDA !14F8,x
	%store_using_y_index(!14F8)

	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	CLC : ADC $02
	PHX
	LDX $00
	CLC : ADC CarriedItemXPosOffset,x
	SEP #$20
	%store_using_y_index(!E4)
	XBA
	%store_using_y_index(!14E0)
	PLX

	; Project clone Y with Mario's Y speed.
	LDA $7D
	STA $02
	STZ $03
	REP #$20
	LDA $02
	AND #$00FF
	CMP #$0080
	BCC +
	ORA #$FF00
+	ASL #4
	STA $02
	SEP #$20
	LDA !14EC,x
	STA $04
	STZ $05
	REP #$20
	LDA $04
	CLC : ADC $02
	STA $04
	SEP #$20
	LDA $04
	%store_using_y_index(!14EC)
	LDA $05
	STA $06
	STZ $07
	BPL +
	DEC $07
+
	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	CLC : ADC $06
	SEC : SBC #$0001
	SEP #$20
	%store_using_y_index(!D8)
	XBA
	%store_using_y_index(!14D4)

	LDA #$00
	%store_using_y_index(!B6)
	%store_using_y_index(!AA)

	.return
	RTS

CarriedItemXPosOffset:
	dw $000B, $FFF5

GetSpriteSlots:
	LDA #$FF
	STA !CloneSpriteSlot
	STA !NewSpriteSlot
	PHX
	LDX #$00		; loop count (loop though all sprite number slots)
.loop
	LDA !14C8,x			; load sprite number
	BEQ .next			; if sprite status is not in use, skip

.slotInUse
	LDA !NewSpriteSlot
	CMP #$FF
	BNE .newSpriteSlotIsSet	; if NEW sprite slot is already set, skip

	STX !NewSpriteSlot	; set NEW sprite slot to current sprite slot

.newSpriteSlotIsSet
	LDA !7FAB9E,x		; load sprite number
	CMP #!CloneSpriteNumber	; if sprite number is not the clone sprite number,
	BNE .next				; then skip

.cloneSpriteSlotFound
	STX !CloneSpriteSlot
	BRA .done

.next
	INX					; increment loop count
	CPX #!SprSize		; if loop count is equal to the sprite size, loop
	BNE .loop			; if loop count is not equal to the sprite size, loop

.done
	PLX
	RTS

SpriteTables:	; contains 62 sprite tables
	dw !E4, !14E0, !D8, !14D4, !AA, !B6, !C2, !1504, !1510, !151C, !1528, !1534, !1540, !154C, !1558, !1564, !1570, !157C, !1594, !15AC, !15D0, !15F6, !1602, !160E, !1626, !163E, !187B, !7FAB9E, !14C8, !9E, !14EC, !14F8, !1588, !15A0, !15B8, !15C4, !15DC, !15EA, !161A, !1632, !164A, !1656, !1662, !166E, !167A, !1686, !186C, !190F, !1938, !1FD6, !1FE2, !7FAB10, !7FAB1C, !7FAB28, !7FAB34, !7FAB40, !7FAB4C, !7FAB58, !7FAB64, !7FAC00, !7FAC08, !7FAC10

macro SprToRAM(addr, offset)
LDA <addr>,x
STA !SpriteTablesRAM+(<offset>)
endmacro

macro RAMToSpr(addr, offset)
LDA !SpriteTablesRAM+(<offset>)
STA <addr>,x
endmacro

macro SprToSpr(addr)
LDX !CloneSpriteSlot
LDA <addr>,x
LDX !NewSpriteSlot
STA <addr>,x
endmacro

MoveAllSpriteTablesToRAM:
	; Move all sprite tables to RAM:
	%SprToRAM(!E4, 0)
	%SprToRAM(!14E0, 1)
	%SprToRAM(!D8, 2)
	%SprToRAM(!14D4, 3)
	%SprToRAM(!AA, 4)
	%SprToRAM(!B6, 5)
	%SprToRAM(!C2, 6)
	%SprToRAM(!1504, 7)
	%SprToRAM(!1510, 8)
	%SprToRAM(!151C, 9)
	%SprToRAM(!1528, 10)
	%SprToRAM(!1534, 11)
	%SprToRAM(!1540, 12)
	%SprToRAM(!154C, 13)
	%SprToRAM(!1558, 14)
	%SprToRAM(!1564, 15)
	%SprToRAM(!1570, 16)
	%SprToRAM(!157C, 17)
	%SprToRAM(!1594, 18)
	%SprToRAM(!15AC, 19)
	%SprToRAM(!15D0, 20)
	%SprToRAM(!15F6, 21)
	%SprToRAM(!1602, 22)
	%SprToRAM(!160E, 23)
	%SprToRAM(!1626, 24)
	%SprToRAM(!163E, 25)
	%SprToRAM(!187B, 26)
	%SprToRAM(!7FAB9E, 27)
	%SprToRAM(!14C8, 28)
	%SprToRAM(!9E, 29)
	%SprToRAM(!14EC, 30)
	%SprToRAM(!14F8, 31)
	%SprToRAM(!1588, 32)
	%SprToRAM(!15A0, 33)
	%SprToRAM(!15B8, 34)
	%SprToRAM(!15C4, 35)
	%SprToRAM(!15DC, 36)
	%SprToRAM(!15EA, 37)
	%SprToRAM(!161A, 38)
	%SprToRAM(!1632, 39)
	%SprToRAM(!164A, 40)
	%SprToRAM(!1656, 41)
	%SprToRAM(!1662, 42)
	%SprToRAM(!166E, 43)
	%SprToRAM(!167A, 44)
	%SprToRAM(!1686, 45)
	%SprToRAM(!186C, 46)
	%SprToRAM(!190F, 47)
	%SprToRAM(!1938, 48)
	%SprToRAM(!1FD6, 49)
	%SprToRAM(!1FE2, 50)
	%SprToRAM(!7FAB10, 51)
	%SprToRAM(!7FAB1C, 52)
	%SprToRAM(!7FAB28, 53)
	%SprToRAM(!7FAB34, 54)
	%SprToRAM(!7FAB40, 55)
	%SprToRAM(!7FAB4C, 56)
	%SprToRAM(!7FAB58, 57)
	%SprToRAM(!7FAB64, 58)
	; %SprToRAM(!7FAC00, 59)
	%SprToRAM(!7FAC08, 60)
	%SprToRAM(!7FAC10, 61)
	RTS

GetAllSpriteTablesFromRAM:
	; Get all sprite tables from RAM:
	%RAMToSpr(!E4, 0)
	%RAMToSpr(!14E0, 1)
	%RAMToSpr(!D8, 2)
	%RAMToSpr(!14D4, 3)
	%RAMToSpr(!AA, 4)
	%RAMToSpr(!B6, 5)
	%RAMToSpr(!C2, 6)
	%RAMToSpr(!1504, 7)
	%RAMToSpr(!1510, 8)
	%RAMToSpr(!151C, 9)
	%RAMToSpr(!1528, 10)
	%RAMToSpr(!1534, 11)
	%RAMToSpr(!1540, 12)
	%RAMToSpr(!154C, 13)
	%RAMToSpr(!1558, 14)
	%RAMToSpr(!1564, 15)
	%RAMToSpr(!1570, 16)
	%RAMToSpr(!157C, 17)
	%RAMToSpr(!1594, 18)
	%RAMToSpr(!15AC, 19)
	%RAMToSpr(!15D0, 20)
	%RAMToSpr(!15F6, 21)
	%RAMToSpr(!1602, 22)
	%RAMToSpr(!160E, 23)
	%RAMToSpr(!1626, 24)
	%RAMToSpr(!163E, 25)
	%RAMToSpr(!187B, 26)
	%RAMToSpr(!7FAB9E, 27)
	%RAMToSpr(!14C8, 28)
	%RAMToSpr(!9E, 29)
	%RAMToSpr(!14EC, 30)
	%RAMToSpr(!14F8, 31)
	%RAMToSpr(!1588, 32)
	%RAMToSpr(!15A0, 33)
	%RAMToSpr(!15B8, 34)
	%RAMToSpr(!15C4, 35)
	%RAMToSpr(!15DC, 36)
	%RAMToSpr(!15EA, 37)
	%RAMToSpr(!161A, 38)
	%RAMToSpr(!1632, 39)
	%RAMToSpr(!164A, 40)
	%RAMToSpr(!1656, 41)
	%RAMToSpr(!1662, 42)
	%RAMToSpr(!166E, 43)
	%RAMToSpr(!167A, 44)
	%RAMToSpr(!1686, 45)
	%RAMToSpr(!186C, 46)
	%RAMToSpr(!190F, 47)
	%RAMToSpr(!1938, 48)
	%RAMToSpr(!1FD6, 49)
	%RAMToSpr(!1FE2, 50)
	%RAMToSpr(!7FAB10, 51)
	%RAMToSpr(!7FAB1C, 52)
	%RAMToSpr(!7FAB28, 53)
	%RAMToSpr(!7FAB34, 54)
	%RAMToSpr(!7FAB40, 55)
	%RAMToSpr(!7FAB4C, 56)
	%RAMToSpr(!7FAB58, 57)
	%RAMToSpr(!7FAB64, 58)
	; %RAMToSpr(!7FAC00, 59)
	%RAMToSpr(!7FAC08, 60)
	%RAMToSpr(!7FAC10, 61)
	RTS

MoveSpriteTablesToAnotherSpriteSlot:
	; Move the sprite tables to another sprite slot:
	%SprToSpr(!E4)
	%SprToSpr(!14E0)
	%SprToSpr(!D8)
	%SprToSpr(!14D4)
	%SprToSpr(!AA)
	%SprToSpr(!B6)
	%SprToSpr(!C2)
	%SprToSpr(!1504)
	%SprToSpr(!1510)
	%SprToSpr(!151C)
	%SprToSpr(!1528)
	%SprToSpr(!1534)
	%SprToSpr(!1540)
	%SprToSpr(!154C)
	%SprToSpr(!1558)
	%SprToSpr(!1564)
	%SprToSpr(!1570)
	%SprToSpr(!157C)
	%SprToSpr(!1594)
	%SprToSpr(!15AC)
	%SprToSpr(!15D0)
	%SprToSpr(!15F6)
	%SprToSpr(!1602)
	%SprToSpr(!160E)
	%SprToSpr(!1626)
	%SprToSpr(!163E)
	%SprToSpr(!187B)
	%SprToSpr(!7FAB9E)
	%SprToSpr(!14C8)
	%SprToSpr(!9E)
	%SprToSpr(!14EC)
	%SprToSpr(!14F8)
	%SprToSpr(!1588)
	%SprToSpr(!15A0)
	%SprToSpr(!15B8)
	%SprToSpr(!15C4)
	%SprToSpr(!15DC)
	%SprToSpr(!15EA)
	%SprToSpr(!161A)
	%SprToSpr(!1632)
	%SprToSpr(!164A)
	%SprToSpr(!1656)
	%SprToSpr(!1662)
	%SprToSpr(!166E)
	%SprToSpr(!167A)
	%SprToSpr(!1686)
	%SprToSpr(!186C)
	%SprToSpr(!190F)
	%SprToSpr(!1938)
	%SprToSpr(!1FD6)
	%SprToSpr(!1FE2)
	%SprToSpr(!7FAB10)
	%SprToSpr(!7FAB1C)
	%SprToSpr(!7FAB28)
	%SprToSpr(!7FAB34)
	%SprToSpr(!7FAB40)
	%SprToSpr(!7FAB4C)
	%SprToSpr(!7FAB58)
	%SprToSpr(!7FAB64)
	; %SprToSpr(!7FAC00)
	%SprToSpr(!7FAC08)
	%SprToSpr(!7FAC10)
	RTS
	