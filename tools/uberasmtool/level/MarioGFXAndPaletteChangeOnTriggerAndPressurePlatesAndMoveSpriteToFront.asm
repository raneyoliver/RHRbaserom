
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

; Must enable other optional global UberASM code first.
; May cause very slight delay on level load, and slight delay when actually changing GFX.

; You can also use this with SwitchBetweenMarioAndLuigiWithLR.asm,
; if you want the player to actually change into Luigi (e.g. in status bar too), and not just GFX.
; Just change that other trigger to match this one.

!Trigger = $41A026 ; Set whatever FreeRAM trigger you want, to be used with block, etc.
!CustomExGFXNumber = $0B32 ; actual GFX file itself
!Palette = C ; See options at bottom.
!ChangeToLuigi = 0 ; You can set this to 1 if you use the other Luigi Uber mentioned above

!VanillaExGFXNumber = $0A32 ; you shouldn't need to change this
!RAM_PlayerPalPtr = $41A034		; Only change these if you
!RAM_PalUpdateFlag = $41A00B    ; change them in imamelia's patch

!CloneIndex						= $41A01A
!CloneCarriedItemIndex			= $41B82E

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
	WDM #$01
	JSL PressurePlates_main
	JSL MoveSpriteToFront_main
	JSR HandleCloneCarriedItemPosition


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

; Sets position of clone carried item
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
	CLC : ADC XPosOffset,x
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

	.return
	RTS

XPosOffset:
	dw $000B, $FFF5

; Palettes:

A:
     dw $635F,$581D,$2529,$7FFF,$0008,$0017,$001F,$577B,$0DDF,$03FF ; Fire Mario
B:
     dw $5B3D,$18DC,$09D4,$0DE5,$12A7,$7FB4,$7FFF,$1769,$2F8E,$03FF ; Yoshi
C:
     dw $4F3F,$581D,$1140,$3FE0,$3C07,$7CAE,$7DB3,$2F00,$165F,$03FF ; Luigi, starts at color 6