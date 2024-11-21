
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

; Must enable other optional global UberASM code first.
; May cause very slight delay on level load, and slight delay when actually changing GFX.

; You can also use this with SwitchBetweenMarioAndLuigiWithLR.asm,
; if you want the player to actually change into Luigi (e.g. in status bar too), and not just GFX.
; Just change that other trigger to match this one.

!MarioSpriteNumber = $14
!CloneIsMario = $41A026
!Trigger = $41A026 ; Set whatever FreeRAM trigger you want, to be used with block, etc.
!CustomExGFXNumber = $0B32 ; actual GFX file itself
!Palette = C ; See options at bottom.
!ChangeToLuigi = 0 ; You can set this to 1 if you use the other Luigi Uber mentioned above

!VanillaExGFXNumber = $0A32 ; you shouldn't need to change this
!RAM_PlayerPalPtr = $41A034		; Only change these if you
!RAM_PalUpdateFlag = $41A00B    ; change them in imamelia's patch

init:
	LDA #$00
	STA !Trigger

    ;if !ChangetoLuigi = 0
	LDA.b #!Palette			; set up pointer
	STA !RAM_PlayerPalPtr
	LDA.b #!Palette>>8
	STA !RAM_PlayerPalPtr+1
	LDA.b #!Palette>>16
	STA !RAM_PlayerPalPtr+2
	;endif

	RTL

; !ChangeToLuigi = 0

main:
	JSR PutAllSpritesInWater
	JSR GetMarioSpriteIndex	; A = mario sprite index
	STA $00

	LDA !CloneIsMario
	BEQ .noSwim

.swimming
	; if you're luigi, he swims in this level.
	LDA #$01
	STA $75
	STA $85
	PHX
	LDX $00
	STZ !164A,x
	PLX
	BRA .pressurePlates

.noSwim
	STZ $75
	STZ $85
	PHX
	LDX $00
	LDA #$01
	STA !164A,x
	PLX
.pressurePlates
	JSL PressurePlates_main
    ;if !ChangeToLuigi = 1
	;LDX $0DB3 ; actually change player to Luigi
	;TXA
	;BEQ ToLuigi
	;STZ $0DB3
	;BRA PaletteMain
;ToLuigi:
	;INC $0DB3
	;endif
;PaletteMain:
    ;if !ChangetoLuigi = 0
    LDA !Trigger
	BEQ PaletteFlip     ; Don't change to new palette unless RAM set
	LDA #$01
	STA !RAM_PalUpdateFlag
	STA $15E8|!addr
	RTL
	;BRA Gfx
PaletteFlip:
	LDA #$00			; ; can't STZ long address, back to original if trigger flipped back
	STA !RAM_PalUpdateFlag
	STA $15E8|!addr
	;endif
; Gfx:
;     lda !Trigger
; 	beq BackToMario
;     rep #$30
;     lda.w #!CustomExGFXNumber
;     jsl mario_exgfx_upload_player
;     sep #$30
;     RTL
BackToMario:
	rep #$30
    lda.w #!VanillaExGFXNumber
    jsl mario_exgfx_upload_player
    sep #$30
;if !ChangeToLuigi = 1
	;stz $0DB3
;endif
    RTL


GetMarioSpriteIndex:
	PHX
	LDA #$15
	TAX
.loop
	LDA !7FAB9E,x
	CMP #!MarioSpriteNumber
	BNE .next

.found
	TXA
	BRA .done

.next
	DEX
	BPL .loop

.done
	PLX
	RTS

PutAllSpritesInWater:
	PHX
	LDA #$15
	TAX
.loop
	LDA !7FAB9E,x
	CMP #!MarioSpriteNumber
	BEQ .next

	LDA #$01
	STA !164A,x ; make all other sprites in water regardless

.next
	DEX
	BPL .loop

.done
	PLX
	RTS

; Palettes:

A:
     dw $635F,$581D,$2529,$7FFF,$0008,$0017,$001F,$577B,$0DDF,$03FF ; Fire Mario
B:
     dw $5B3D,$18DC,$09D4,$0DE5,$12A7,$7FB4,$7FFF,$1769,$2F8E,$03FF ; Yoshi
C:
     dw $4F3F,$581D,$1140,$3FE0,$3C07,$7CAE,$7DB3,$2F00,$165F,$03FF ; Luigi, starts at color 6