print "MAIN ",pc
	JSR Graphics
print "INIT ",pc
RTL

Graphics:
	%GetDrawInfo()

	LDA $00
	STA $0300,y	; X position
	LDA $01
	STA $0301,y	; Y position
	LDA #$24
	STA $0302,y	; Tile number
	LDA $15F6,x
	ORA $64
	STA $0303,y	; Properties

	LDA #$00	; Tile to draw - 1
	LDY #$02	; 16x16 sprite
	JSL $01B7B3
RTS