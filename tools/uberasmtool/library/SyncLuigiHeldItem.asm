; Sprite-agnostic pre-draw sync for the item indexed by !LuigiHeldItemIndex.
; This runs on the SNES CPU, so SA-1 DP-backed values use their $30xx mirrors.

%define_sprite_table("AA", $AA, $9E)
%define_sprite_table("B6", $B6, $B6)
%define_sprite_table("D8", $D8, $3216)
%define_sprite_table("E4", $E4, $322C)
%define_sprite_table("14C8", $14C8, $3242)
%define_sprite_table("14D4", $14D4, $3258)
%define_sprite_table("14E0", $14E0, $326E)
%define_sprite_table("14EC", $14EC, $74C8)
%define_sprite_table("14F8", $14F8, $74DE)
%define_sprite_table("157C", $157C, $3334)
%define_sprite_table("167A", $167A, $7616)
%define_sprite_table("1686", $1686, $762C)

!LuigiIndex = $41A01A
!LuigiHeldItemIndex = $41B82E
!LuigiSpinning = $41A00C

if read1($00FFD5) == $23
	sa1rom
	!SA1 = 1
	!UberFreezeFlag = $309D
	!UberPlayerDirection = $3076
	!UberPlayerBlocked = $3077
	!UberPlayerXNext = $3094
	!UberPlayerX = $30D1
	!UberPlayerYSpeed = $307D
	!UberSpriteXSpeed = $30B6
	!UberSpriteYSpeed = $309E
else
	lorom
	!SA1 = 0
	!UberFreezeFlag = $9D
	!UberPlayerDirection = $76
	!UberPlayerBlocked = $77
	!UberPlayerXNext = $94
	!UberPlayerX = $D1
	!UberPlayerYSpeed = $7D
	!UberSpriteXSpeed = $B6
	!UberSpriteYSpeed = $AA
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
	PHP
	SEP #$30

	LDA !UberFreezeFlag
	BEQ +
	JMP .return
+

	LDA !LuigiHeldItemIndex
	CMP #$FF
	BNE +
	JMP .return
+
	TAY
	; Drop stale ownership if the slot was erased off-screen / killed,
	; or if it became a non-carryable ($08 naked koopa, etc.).
	LDA !14C8,y
	CMP #$07
	BEQ +
	CMP #$09
	BEQ +
	CMP #$0B
	BEQ +
	LDA #$FF
	STA !LuigiHeldItemIndex
	JMP .return
+
	; Keep held carryables alive while the camera leaves them.
	; Ignore objects ($1686 bit 7) so walls don't fling a $09 held item.
	LDA !167A,y
	ORA #$84
	STA !167A,y
	LDA !1686,y
	ORA #$80
	STA !1686,y

	LDA !LuigiIndex
	TAX
	LDA !14C8,x
	CMP #$0B
	BNE .freeLuigi
	JMP .marioCarryingLuigi

.freeLuigi
	LDA !157C,x
	AND #$01
	%store_using_y_index(!157C)
	STA $00

	; Project Luigi's X fixed-point position through this frame's speed.
	LDA !UberSpriteXSpeed,x
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
	CLC
	ADC $02
	STA $04
	SEP #$20
	LDA $04
	%store_using_y_index(!14F8)

	LDA $05
	STA $06
	STZ $07
	BPL +
	DEC $07
+
	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	CLC
	ADC $06
	STA $08
	SEP #$20
	JSR AddFacingOffset
	%store_using_y_index(!E4)
	XBA
	%store_using_y_index(!14E0)

	; Project Luigi's Y fixed-point position through this frame's speed.
	LDA !UberSpriteYSpeed,x
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
	CLC
	ADC $02
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
	CLC
	ADC $06
	SEC
	SBC #$0001
	SEP #$20
	%store_using_y_index(!D8)
	XBA
	%store_using_y_index(!14D4)
	JMP .zeroItemSpeeds

.marioCarryingLuigi
	; Preserve Luigi's spin-facing behavior; otherwise face with the player.
	LDA !LuigiSpinning
	BEQ .faceWithMario
	LDA !157C,x
	AND #$01
	BRA .storeFacing

.faceWithMario
	LDA !UberPlayerDirection
	EOR #$01
	AND #$01

.storeFacing
	%store_using_y_index(!157C)
	STA $00

	; Project X by Mario's exact whole-pixel movement this frame.
	REP #$20
	LDA !UberPlayerXNext
	SEC
	SBC !UberPlayerX
	STA $02
	SEP #$20

	LDA !14F8,x
	%store_using_y_index(!14F8)
	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	CLC
	ADC $02
	STA $08
	SEP #$20
	JSR AddFacingOffset
	%store_using_y_index(!E4)
	XBA
	%store_using_y_index(!14E0)

	; Project Y through Mario's vertical speed only while airborne.
	; SMW can leave a positive $7D (e.g. $2E) while blocked below; applying
	; it here made Luigi's held item render about 3 pixels too low whenever
	; Mario carried Luigi on the ground.
	LDA !UberPlayerBlocked
	AND #$04
	BNE .noCarriedYProjection
	LDA !UberPlayerYSpeed
	BRA .storeCarriedYSpeed
.noCarriedYProjection
	LDA #$00
.storeCarriedYSpeed
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
	CLC
	ADC $02
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
	CLC
	ADC $06
	SEC
	SBC #$0001
	SEP #$20
	%store_using_y_index(!D8)
	XBA
	%store_using_y_index(!14D4)

.zeroItemSpeeds
	LDA #$00
	%store_using_y_index(!UberSpriteXSpeed)
	%store_using_y_index(!UberSpriteYSpeed)

.return
	PLP
	RTL

; Return the projected X in A. This avoids width-sensitive LDX $00 table
; indexing while retaining the established +$000B / -$000B offsets.
AddFacingOffset:
	LDA $00
	BNE .left
	REP #$20
	LDA $08
	CLC
	ADC #$000B
	SEP #$20
	RTS

.left
	REP #$20
	LDA $08
	CLC
	ADC #$FFF5
	SEP #$20
	RTS
