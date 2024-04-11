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

incsrc "../mario_exgfx/settings.asm"
incsrc "../mario_exgfx/main.asm"

;incsrc "/mario_exgfx/settings.asm"
;incsrc "/mario_exgfx/main.asm"