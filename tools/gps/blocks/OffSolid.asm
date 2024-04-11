
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

db $37

JMP OnSolid : JMP OnSolid : JMP OnSolid
JMP OnSolid : JMP OnSolid
JMP OnSolid : JMP OnSolid
JMP OnSolid : JMP OnSolid : JMP OnSolid
JMP OnSolid : JMP OnSolid

OnSolid:
	LDA $14AF|!addr
	BEQ OffAir
	LDY #$01
	LDA #$30
	STA $1693|!addr
	RTL
OffAir:
	LDY #$00
	LDA #$25
	STA $1693|!addr
	RTL

print "A regular on-off block, which only becomes solid when the switch is turned off."