
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

!CustomNumber = $14 ;$2E


;A block that is bouncy to throw blocks.
;behaves $130
db $42
JMP ret : JMP ret : JMP ret : JMP SpriteV : JMP SpriteH : JMP ret
JMP ret : JMP ret : JMP ret : JMP ret


SpriteH:
    LDA !7FAB9E,x	;\not custom throwblk = return
	CMP #!CustomNumber	;|
	BEQ boing		;/

	LDA !9E,x	;\not throwblk = return
	CMP #$53	;|
	BNE ret		;/
	LDA !B6,x	;\not moving = return
	BEQ ret		;/
	LDA !14C8,x	;\not kicked = check if dropped
	CMP #$0A	;|
	BEQ boing	;/
	CMP #$09	;\not dropped either =
	BEQ boing	;/return
	RTL
boing:
	LDA !B6,x	;\set x speed (the speed
	BMI goingleft	;|of the shell the blue
	LDA #$D0	;|koopa kicks)
	STA !B6,x	;|
	BRA skipleft	;|
goingleft:		;|
	LDA #$30	;|
	STA !B6,x	;/
skipleft:
	LDA #$0A	;\make it kicked
	STA !14C8,x	;/
reuse_code:
	LDY #$00	;\don't shatter the sprite
	LDA #$25	;|
	STA $1693|!addr	;/
	LDA #$08	;\sfx
	STA $1DFC|!addr	;/
ret:
RTL
SpriteV:
	LDA !9E,x	;\not throwblk = return
	CMP #$53	;|
	BNE ret		;/
	LDA !AA,x	;\not moving = return
	BEQ ret		;/
	LDA !14C8,x	;\not kicked = check if dropped
	CMP #$0A	;|
	BEQ boing1	;/
	CMP #$09	;\not dropped either =
	BEQ boing1	;/return
	RTL
boing1:
	LDA !AA,x	;\set Y speed
	BMI goingup	;|
	LDA #$A0	;|
	STA !AA,x	;|
	BRA skipup	;|
goingup:		;|
	LDA #$60	;|
	STA !AA,x	;/
skipup:
	BRA reuse_code	;>recycle code


print "Bounces a moving throwblock."