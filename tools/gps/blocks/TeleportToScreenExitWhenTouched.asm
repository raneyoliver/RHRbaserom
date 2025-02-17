
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
db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

MarioBelow:
MarioAbove:
MarioSide:

TopCorner:
BodyInside:
HeadInside:

LDA #$06
STA $71
STZ $88
STZ $89

;WallFeet:	; when using db $37
;WallBody:

SpriteV:
SpriteH:

MarioCape:
MarioFireball:
RTL

print "Teleports you to whatever level the screen exit for the current screen is set to."