;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reverse Gravity
;
; This patch allows the player to have reversed gravity.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!dp   = $0000
!addr = $0000
!bank = $800000
!D8 = $D8

if read1($00FFD6) == $15
sfxrom
!dp   = $6000
!addr = !dp
!bank  = $000000
elseif read1($00FFD5) == $23
sa1rom
!dp   = $3000
!addr = $6000
!bank  = $000000
!D8 = $3216
endif

!reversed		= $60		; The reversed gravity flag.

org $00D058
		autoclean JSL fix_cape

org $00DC45
		JML y_speed
		NOP

org $00E346
		JML fix_ram_80
		NOP
		NOP

org $00E46D
		JML flip_mario_gfx

org $00ED14
		JML fix_ceiling

org $00EE17
		JML fix_ground_chk

org $00EED4
		JML fix_ground
		NOP

org $00F18D
		JSL fix_00F18D
		NOP #2

org $00F44D
		JML interaction

org $00F5A3
		JSL fix_fall_death
		NOP
		BCC $0C

org $00FD4A
		JSL fix_bubble
		NOP

org $00FDC3
		JSL fix_splash
		BRA $00

org $00FE7E
		JML fix_dust

org $01A11A
		JSL fix_carry
		NOP

org $028830
		JSL fix_028830
		NOP

org $0290E5
		JML fix_0290E5

org $0290F9
		LDA $01
		BEQ +
		STZ $7D
		BRA +
		NOP
	+

org $02912B
		JML fix_02912B
		NOP

org $029163
		JML fix_029163
		NOP

org $03B690
		JSL fix_clipping
		NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

freecode
reset bytes

flip_offsets:
		dw $000F,$0007

print "flip_gravity is located at: $", pc
		
flip_gravity:	LDA !reversed
		EOR #$01
		STA !reversed

		PHX
		PHY
		LDX #$00
		LDA $19
		BEQ +
		LDA $73
		BNE +
		LDX #$02
	+	REP #$20
		LDA $96
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		SEC
		SBC.l flip_offsets,x
		BRA +
	.ud	CLC
		ADC.l flip_offsets,x
	+	STA $96
		SEP #$20
		PLY
		PLX
		RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This section flips Mario's graphics.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flip_mario_gfx:	LDA !reversed
		BNE .ud

		REP #$20
		LDA $80
		JML $00E471|!bank

	.ud	LDA $0303|!addr,y
		ORA #$80
		STA $0303|!addr,y

		REP #$20
		LDA $80
		SEC
		SBC $DE32,x
		BIT $03
		BMI +
		CLC
		ADC #$0008
	+	CLC
		ADC #$0010
		JML $00E475|!bank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This section flips the Y speed and changes the interaction table while fixing
; any bugs that arise because of these changes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fix_ceiling:	CMP #$F9
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BEQ .not_ud
		BCS +

		LDY $72
		BEQ ++

		EOR #$F0
		STA $00

		LDA $96
		SEC
		SBC $00
		STA $96
		BCS ++
		DEC $97	
	++	JML $00ED37|!bank

	.not_ud	BCC +
		JML $00ED28|!bank
	+	JML $00ED18|!bank

fix_ground_chk:	STA $91
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP		
		BEQ .not_ud
		EOR #$0F
	.not_ud	CMP #$08
		BCC +
		JML $00EE1D|!bank
	+	JML $00EE3A|!bank

fix_ground:	LDA !reversed
		BNE .ud

		LDA $96
		SEC
		SBC $91
		JML $00EED9|!bank

	.ud	LDA $91
		EOR #$0F
		CLC
		ADC $96
		STA $96
		BCC +
		INC $97
	+	JML $00EEE1|!bank

y_interaction:
		dw $0008
		dw $0008,$0006,$000A,$0010,$0000,$0000
		dw $0008,$0006,$000A,$0010,$0000,$0000
		dw $000E,$0006,$0011,$0018,$0000,$0000
		dw $000E,$0006,$0011,$0018,$0000,$0000
		dw $0013,$0008,$0017,$001D,$0000,$0000
		dw $0013,$0008,$0017,$001D,$0000,$0000
		dw $0016,$0008,$001A,$0020,$0000,$0000
		dw $0016,$0008,$001A,$0020,$0000,$0000
		dw $0018,$0018,$0018,$0018,$0018,$0018

interaction:	INX
		INX
		LDA !reversed
		REP #$20
		BNE .ud
		JML $00F451|!bank

	.ud	LDA $94
		CLC
		ADC $E830,x
		STA $9A
		LDA $96
		CLC
		ADC.l y_interaction,x
		JML $00F45F|!bank

y_speed:
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BEQ .not_ud
		LDA $7D
		EOR #$FF
		INC
		STA $7D
	.not_ud	PEA $DC49
		LDX #$02
		JML $00DC4F|!bank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This section fixes bounce sprites.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fix_00F18D:	STZ $00
		REP #$20
		LDA $05,s
		CMP #$EC89
		BEQ .mario
		CMP #$ED05
		BEQ .mario
		CMP #$EE82
		BEQ .mario
		SEP #$20
		BRA .not_ud

	-	LDA !reversed
		BEQ .not_ud
		DEY
		CPY #$02
		BCC .not_ud
		INY
		TYA
		EOR #$03
		TAY
	.not_ud	STY $06
		LDA $00F0C8|!bank,x
		RTL

	.mario	SEP #$20
		LDA $00F05C|!bank,x
		CMP #$01
		BNE -
		INC $00
		BRA -

fix_028830:	LDA $00
		CLC
		ROR
		ROR
		STA $169D|!addr,y
		RTL

fix_0290E5:	STZ $01
		LDA $1699|!addr,x
		CMP #$02
		BNE +
		LDA $169D|!addr,x
		BPL +

		LDA $16C9|!addr,x
		AND #$03
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		CMP #$03
		BNE +
		BRA .nb

	.ud	CMP #$00
		BNE +
	.nb	INC $01
	+	LDA $169D|!addr,x
		LSR
		BCS .return
		JML $0290EA|!bank
	.return	JML $02910B|!bank

fix_02912B:	LDA $01
		BEQ .return
		LDA $71
		BNE .return
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		JML $02913A|!bank
	.return	JML $02915E|!bank

	.ud	LDA $16A1|!addr,x
		CLC
		ADC #$10
		STA $96
		LDA $16A9|!addr,x
		ADC #$00
		JML $029152|!bank

fix_029163:	LDA $01
		BEQ .return

		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		JML $02916C|!bank
	.return	JML $029182|!bank

	.ud	LDA #$A0
		STA $7D
		REP #$20
		INC $96
		INC $96
		SEP #$20
		JML $02917D|!bank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This section fixes various bugs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fix_bubble:
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		ADC $96
		BRA +
		
	.ud	LDA $96
		LDY $19
		BEQ +
		LDY $73
		BNE +
		CLC
		ADC #$08
	+	STA $1715|!addr,x
		RTL

fix_cape:	CLC
		PHX
		; LDX !reversed
			PHA
			LDA !reversed
			PHP
			TAX
			PLA
			PLP
		BNE .ud
		PLX
		ADC $D03C,y
		RTL
		
	.ud	PLX
		ADC #$0010
		SEC
		SBC $D03C,y
		RTL	
	
fix_carry:
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		CLC
		BNE .ud
		
		ADC $02
		BRA +
		
	.ud	LDA $02
		ADC #$01
	+	STA !D8,x
		RTL

fix_clipping:
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		CLC
		ADC $03B65C,x
	.ud	RTL
		
fix_dust:	LDA !reversed
		BNE .ud
		LDA $96
		ADC #$1A
		JML $00FE82|!bank
		
	.ud	LDA $96
		SEC
		SBC #$04
		PHX
		JML $00FE8A|!bank

fix_fall_death:	CLC
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		
		SEP #$20
		LDA $81
		DEC
		BMI .return
		SEC
	.return	RTL
	
	.ud	LDA $80
		ADC #$0020
		SEP #$20
		CLC
		BPL .return
		SEC
		RTL

fix_ram_80:	LDA $188B|!addr
		AND #$00FF
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		JML $00E34C|!bank

	.ud	EOR #$FFFF
		CLC
		ADC $96
		LDY $19
		CPY #$01
		LDY #$01
		BCS +
		INC
		DEY
+		CPX #$0A
		BCS +
		CPY $13DB|!addr
		BCS +
		INC
		SEC
+		JML $00E360|!bank

splash_offset:
		db $08,$10,$16,$16

fix_splash:	LDA $96
		CLC
		PHY
		LDY !reversed
;			PHA
;			LDA !reversed
;			PHP
;			TAY
;			PLA
;			PLP
		BNE .ud
		ADC $FD9D,x
		BRA +

	.ud	ADC.l splash_offset,x
	+	PLY
		RTL
	
print "Bytes inserted: ", bytes