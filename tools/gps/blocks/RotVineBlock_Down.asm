
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
; ;sprite tool / pixi defines
; %define_sprite_table("7FAB10",$7FAB10,$6040)
; %define_sprite_table("7FAB1C",$7FAB1C,$6056)
; %define_sprite_table("7FAB28",$7FAB28,$6057)
; %define_sprite_table("7FAB34",$7FAB34,$606D)
; %define_sprite_table("7FAB9E",$7FAB9E,$6083)
; %define_sprite_table("7FAB40",$7FAB40,$6099)
; %define_sprite_table("7FAB4C",$7FAB4C,$60AF)
; %define_sprite_table("7FAB58",$7FAB58,$60C5)
; %define_sprite_table("7FAB64",$7FAB64,$60DB)

; %define_sprite_table("7FAC00",$7FAC00,$60F1)
; %define_sprite_table("7FAC08",$7FAC08,$6030)
; %define_sprite_table("7FAC10",$7FAC10,$6038)

; ;normal sprite defines

; %define_sprite_table("9E", $9E, $3200)
; %define_sprite_table("AA", $AA, $9E)
; %define_sprite_table("B6", $B6, $B6)
; %define_sprite_table("C2", $C2, $D8)
; %define_sprite_table("D8", $D8, $3216)
; %define_sprite_table("E4", $E4, $322C)
; %define_sprite_table("14C8", $14C8, $3242)
; %define_sprite_table("14D4", $14D4, $3258)
; %define_sprite_table("14E0", $14E0, $326E)
; %define_sprite_table("14EC", $14EC, $74C8)
; %define_sprite_table("14F8", $14F8, $74DE)
; %define_sprite_table("1504", $1504, $74F4)
; %define_sprite_table("1510", $1510, $750A)
; %define_sprite_table("151C", $151C, $3284)
; %define_sprite_table("1528", $1528, $329A)
; %define_sprite_table("1534", $1534, $32B0)
; %define_sprite_table("1540", $1540, $32C6)
; %define_sprite_table("154C", $154C, $32DC)
; %define_sprite_table("1558", $1558, $32F2)
; %define_sprite_table("1564", $1564, $3308)
; %define_sprite_table("1570", $1570, $331E)
; %define_sprite_table("157C", $157C, $3334)
; %define_sprite_table("1588", $1588, $334A)
; %define_sprite_table("1594", $1594, $3360)
; %define_sprite_table("15A0", $15A0, $3376)
; %define_sprite_table("15AC", $15AC, $338C)
; %define_sprite_table("15B8", $15B8, $7520)
; %define_sprite_table("15C4", $15C4, $7536)
; %define_sprite_table("15D0", $15D0, $754C)
; %define_sprite_table("15DC", $15DC, $7562)
; %define_sprite_table("15EA", $15EA, $33A2)
; %define_sprite_table("15F6", $15F6, $33B8)
; %define_sprite_table("1602", $1602, $33CE)
; %define_sprite_table("160E", $160E, $33E4)
; %define_sprite_table("161A", $161A, $7578)
; %define_sprite_table("1626", $1626, $758E)
; %define_sprite_table("1632", $1632, $75A4)
; %define_sprite_table("163E", $163E, $33FA)
; %define_sprite_table("164A", $164A, $75BA)
; %define_sprite_table("1656", $1656, $75D0)
; %define_sprite_table("1662", $1662, $75EA)
; %define_sprite_table("166E", $166E, $7600)
; %define_sprite_table("167A", $167A, $7616)
; %define_sprite_table("1686", $1686, $762C)
; %define_sprite_table("186C", $186C, $7642)
; %define_sprite_table("187B", $187B, $3410)
; %define_sprite_table("190F", $190F, $7658)

; %define_sprite_table("1938", $7FAF00, $418A00)
; %define_sprite_table("7FAF00", $7FAF00, $418A00)

; %define_sprite_table("1FD6", $1FD6, $766E)
; %define_sprite_table("1FE2", $1FE2, $7FD6)
;Sample ? block which spawns a rotating vine starting down

!Sprite = $66	; sprite number rotating vine is inserted as in Pixi

db $42

JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH
JMP Cape : JMP Fireball
JMP MarioCorner : JMP MarioInside : JMP MarioHead

!ActivatePerSpinJump = 0	; Activatable with a spin jump (doesn't work if invisible)

!ExtraBit = #$00

!IsCustom = SEC ; CLC for normal, SEC custom sprite
!State = $01	; $08 for normal, $09 for carryable sprites
!1540_val = $00	; If you use powerups, this should be $3E
				; Carryable sprites uses it as the stun timer

!ExtraByte1 = $10	; First extra byte
!ExtraByte2 = $01	; Second extra byte
!ExtraByte3 = $00	; Third extra byte
!ExtraByte4 = $00	; Fourth extra byte

!XPlacement = $00	; Remember: $01-$7F moves the sprite to the right and $80-$FF to the left.
!YPlacement = $10	; Remember: $01-$7F moves the sprite to the bottom and $80-$FF to the top.

!SoundEffect = $02
!APUPort = $1DFC|!addr

!bounce_num			= $03	; See RAM $1699 for more details. If set to 0, the block changes into the Map16 tile directly
!bounce_direction	= $00	; Should be generally $00
!bounce_block		= $0D	; See RAM $9C for more details. Can be set to $FF to change the tile manually
!bounce_properties	= $00	; YXPPCCCT properties

; If !bounce_block is $FF.
!bounce_Map16 = $0132		; Changes into the Map16 tile directly (also used if !bounce_num is 0x00)
!bounce_tile = $2A			; The tile number (low byte) if BBU is enabled

!item_memory_dependent = 0	; Makes the block stay collected
!InvisibleBlock = 0			; Not solid, doesn't detect sprites, can only be hit from below
; 0 for false, 1 for true

if !ActivatePerSpinJump
MarioCorner:
MarioAbove:
	LDA $140D|!addr
	BEQ Return
	LDA $7D
	BMI Return
	LDA #$D0
	STA $7D
	BRA Cape
else
MarioCorner:
MarioAbove:
endif

Return:
MarioSide:
Fireball:
MarioInside:
MarioHead:

if !InvisibleBlock
SpriteH:
SpriteV:
Cape:
RTL


MarioBelow:
	LDA $7D
	BPL Return
else
RTL

SpriteH:
	%check_sprite_kicked_horizontal()
	BCS SpriteShared
RTL

SpriteV:
	LDA !14C8,x
	CMP #$09
	BCC Return
	LDA !AA,x
	BPL Return
	LDA #$10
	STA !AA,x

SpriteShared:
	%sprite_block_position()

MarioBelow:
Cape:
endif

SpawnItem:
	PHX
	PHY
if !bounce_num
	if !bounce_block == $FF
		LDA #!bounce_tile
		STA $02
		LDA.b #!bounce_Map16
		STA $03
		LDA.b #!bounce_Map16>>8
		STA $04
	endif
	LDA #!bounce_num
	LDX #!bounce_block
	LDY #!bounce_direction
	%spawn_bounce_sprite()
	LDA #!bounce_properties
	STA $1901|!addr,y
else
	REP #$10
	LDX #!bounce_Map16
	%change_map16()
	SEP #$10
endif

if !item_memory_dependent == 1
	PHK
	PEA .jsl_2_rts_return-1
	PEA $84CE
	JML $00C00D|!bank
.jsl_2_rts_return
	SEP #$10
endif

	LDA #!SoundEffect
	STA !APUPort

	LDA #!Sprite
	!IsCustom

	%spawn_sprite_block()
	TAX
	if !XPlacement
		LDA #!XPlacement
		STA $00
	else
		STZ $00
	endif
	if !YPlacement
		LDA #!YPlacement
		STA $01
	else
		STZ $01
	endif
	TXA
	%move_spawn_relative()

	LDA #!State
	STA !14C8,x
	LDA #!1540_val
	STA !1540,x
	LDA #$D0
	STA !AA,x
	LDA #$2C
	STA !154C,x

	LDA #!ExtraByte1
	STA !extra_byte_1,x
	LDA #!ExtraByte2
	STA !extra_byte_2,x
	LDA #!ExtraByte3
	STA !extra_byte_3,x
	LDA #!ExtraByte4
	STA !extra_byte_4,x

	LDA !ExtraBit
	ASL
	ASL
	ORA !sprite_extra_bits,x
	STA !sprite_extra_bits,x

	LDA !190F,x
	BPL Return2
	LDA #$10
	STA !15AC,x

Return2:
	PLY
	PLX
RTL

print "Growing vine block, vine moves downward when hit. Customizable speed."