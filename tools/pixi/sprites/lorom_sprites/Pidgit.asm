;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SMB2 Pidgit
;; by Sonikku
;; 

!ShootTime =	$30


!CustomCarpetControls = 1

!CanBeCapeKilled = 1	; Can be killed by the player's cape?
!CanBeFireKilled = 1	; Can be killed (and turn to a coin) by a player's fireball?
!TurnToSilverCoin = 1	; Turns into a silver coin when the Silver POW is active?

Settings_Pointer:
	dl Settings_Pidgit_Blue		; x00	- Normal; osccilates back and forth before swooping down at a fixed Y speed
	dl Settings_Pidgit_Green	; x01   - Green; oscillates back and forth before swooping down at player's Y position
	dl Settings_Pidgit_Yellow	; x02   - Yellow; follows player occasionally swooping
	dl Settings_Pidgit_Red		; x03	- Red; follows player quickly swooping frequently, throwing 4 fireballs at the bottom of its swoop
.end	;; <End of pointer>

Settings_Carpet_Pointer:
	dl Settings_Carpet_Normal	; x00   - Blue Pidgit's carpet speeds
	dl Settings_Carpet_Fast		; x01   - Green Pidgit's carpet speeds
	dl Settings_Carpet_Normal	; x02   - Yellow Pidgit's carpet speeds
	dl Settings_Carpet_Fast		; x03   - Red Pidgit's carpet speeds

!i = 0				;;;; \ 
macro def_pattern(name,id)	;;;;  | 
	dw Pattern_<name>	;;;;  | 
!Pattern_<name> = <id>		;;;;  | 
endmacro			;;;;  | 
				;;;;  | 
macro def_turn(id)		;;;;  | Don't touch this. It just sets up some defines.
!<id>Turns = ((<id>)*$10)	;;;;  | 
endmacro			;;;;  | 
				;;;;  | 
!in = 0				;;;;  | 
while !in != 16			;;;;  | 
%def_turn(!in)			;;;;  | 
!in #= !in+1			;;;;  | 
endif				;;;; / 

Patterns_List:
	%def_pattern(Oscillating,0)
	%def_pattern(Chasing,1)
.end

!Carpet_Tile1 = $CC
!Carpet_Tile2 = $DC
!Carpet_Tile3 = $EC
!Carpet_Tile4 = $FC

Settings:
.Pidgit_Blue	db %10001000 : db $05 : db $20		; Settings, Turns, Time between turns
		db $01 : db $01				; Y Accel, X Accel
		db $08 : db $20				; Max Y Velocity, Max X Velocity
		db $30 : db $14				; Dive Y Velocity, Dive X Velocity
		db !Pattern_Oscillating
		db $FF : db $AE,$AE : db $00,$40	; Palette, Tilemap, Properties
		db $04					; Palette (Carpet)

.Pidgit_Green	db %10001000 : db $07 : db $10		; Settings, Turns, Time between turns
		db $01 : db $02				; Y Accel, X Accel
		db $08 : db $40				; Max Y Velocity, Max X Velocity
		db $FF : db $14				; Dive Y Velocity, Dive X Velocity
		db !Pattern_Oscillating
		db $0A : db $AE,$AE : db $00,$40	; Palette, Tilemap, Properties
		db $08					; Palette (Carpet)

.Pidgit_Yellow	db %10001001 : db $FF : db $E0		; Settings, Turns, Time between turns
		db $01 : db $01				; Y Accel, X Accel
		db $08 : db $20				; Max Y Velocity, Max X Velocity
		db $30 : db $14				; Dive Y Velocity, Dive X Velocity
		db !Pattern_Chasing
		db $04 : db $AE,$AE : db $00,$40	; Palette, Tilemap, Properties
		db $0A					; Palette (Carpet)

.Pidgit_Red	db %10001111 : db $FF : db $80		; Settings, Turns, Time between turns
		db $01 : db $03				; Y Accel, X Accel
		db $08 : db $28				; Max Y Velocity, Max X Velocity
		db $FF : db $14				; Dive Y Velocity, Dive X Velocity
		db !Pattern_Chasing
		db $08 : db $AE,$AE : db $00,$40	; Palette, Tilemap, Properties
		db $06					; Palette (Carpet)

.Carpet
..Normal	db $10,$18 : db $01,$02 : db $01	; Max X, Max X (Fast), X Accel, X Accel (Fast), X Decel
		db $10,$14 : db $01,$02 : db $01	; Max Y, Max Y (Fast), Y Accel, Y Accel (Fast), Y Decel
		db $00					; Y Sink Speed

..Fast		db $20,$30 : db $02,$03 : db $01	; Max X, Max X (Fast), X Accel, X Accel (Fast), X Decel
		db $18,$28 : db $02,$03 : db $01	; Max Y, Max Y (Fast), Y Accel, Y Accel (Fast), Y Decel
		db $00					; Y Sink Speed

DiveSpeed:
	db $12,$14,$16,$18,$1A,$1C,$1E,$20,$22,$24,$26,$28,$2A,$2C,$2D
	db $2F,$30,$31,$32,$33,$34,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E

;; New variants may be added as needed.
;; First: add the settings themselves under the "Settings:" label and give them a label beginning in a period (i.e. ".Label").
;; Second: under the "Settings_Pointer:" or "Settings_Pointer_ExBit:" labels (but before the ".end" labels),
;; add them there, replacing the period with "Settings_" (i.e. "Settings_Label").
;; 
;; New variants are setup in the following way:
;;		db %<Settings> : db $<AA> : db $<BB>		; Settings, Turns, Time between turns
;;		db $<CC> : db $<DD>				; Y Accel, X Accel
;;		db $<EE> : db $<FF>				; Max Y Velocity, Max X Velocity
;;		db $<GG> : db $<HH>				; Dive Y Velocity, Dive X Velocity
;;		db !Pattern_<Type>
;;		db $<X1> : db $<Y1>,$<Y2> : db $<Z1>,$<Z2>	; Palette, Tilemap, Properties
;;		db $<X2>					; Palette (Carpet)
;; 
;; <AA> defines the number of turns, and <BB> defines how long each turn will last.
;; <CC> and <DD> handle the Y and X acceleration of the sprite, respectively.
;; <EE> and <FF> handle the Y and X velocity of the sprite, respectively.
;; <GG> and <HH> handle the Y and X velocity of the sprite when it dives, respectively.
;;               Additionally, setting <GG> to a negative value (i.e. $FF) will cause the sprite to dive in a dynamic arc that will aim at the player.
;; <X1> and <X2> are the palettes of the Pidgit and its carpet, respectively;
;;;; - $00 - Palette 8
;;;; - $02 - Palette 9
;;;; - $04 - Palette A
;;;; - $06 - Palette B
;;;; - $08 - Palette C
;;;; - $0A - Palette D
;;;; - $0C - Palette E
;;;; - $0E - Palette F
;;;; - $FF - Inherit from CFG file
;; <Y1> and <Y2> are the tiles used by the Pidgit.
;; <Z1> and <Z2> are the tile properties used by the Pidgit. Essentially, set it to $40 for an X flip and $80 for a Y flip.
;; 
;; <Type> in Pattern_<Type> will be either "Oscillating" or "Chasing". Dictates how the sprite moves.
;; If set to "Oscillating", it'll oscillate in place like normal.
;; If set to "Chasing", it'll follow the player. <HH> becomes the max horizontal dive speed.
;; 
;; <Settings>:
;;;; Bit 1 (%00000001) - Pause before swooping
;;;; Bit 2 (%00000010) - Doubled dive speed
;;;; Bit 3 (%00000100) - Shoot out fireballs at peak of swoop.
;;;; Bit 4 (%00001000) - Can be ridden (Uses custom interaction)
;;;; Bit 5 (%00010000) - Cannot be spin-killed
;;;; Bit 6 (%00100000) - Cannot be carried
;;;; Bit 7 (%01000000) - SMB2-styled stun (un-stuns when no longer bouncing)
;;;; Bit 8 (%10000000) - Always respawn*
;; 
;; * When the Pidgit is killed, its "sprite load status" value within the level is transferred to the carpet.
;;   When the carpet despawns via going offscreen or its timer expiring, the Pidgit will respawn.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

macro PlaySFX(num,bank)
	if <num> != $00
		LDA.b #<num>
		STA <bank>|!addr
	endif
endmacro

print "INIT ",pc
Init:	PHB
	PHK
	PLB
	LDA !extra_byte_1,x
	CMP.b #(Settings_Pointer_end-Settings_Pointer)/3
	BCC +
	LDA #$00
+	STA !1510,x
	JSR GetSettingsPointer

	LDA !7FAB10,x
	AND #$04
	BEQ .ExtraBit_Clear
	LDA #$02
	STA !1534,x
	LDA !extra_byte_2,x
	STA !1504,x
	PLB
	RTL
.ExtraBit_Clear
	LDY #$02
	LDA [$8A],y
	STA !1540,x

	LDA !D8,x
	STA !1504,x
	LDA !14D4,x
	STA !1528,x

	LDY #$01
	LDA [$8A],y
	STA !1594,x

;; randomize animation
	JSL $01ACF9|!bank
	STA !1570,x
;; set initial direction
+	%SubHorzPos()
	TYA
	STA !157C,x
;; calculate the max value of !1510,x (to prevent pulling potential erroneous values if placed incorrectly)
	STZ !151C,x
	PLB
	RTL

print "MAIN ",pc
Main:	PHB
	PHK
	PLB
	JSR GetSettingsPointer
	JSR SubGFX
	LDA $9D
	BNE .Finish

;; clear top two most-significant bits of extra property 2
	LDA !7FAB34,x
	AND #$3F
	STA !7FAB34,x

;;;; To give clarity on why I am doing this -- it lets me override the default code of !14C8,x when I deem fit.
;;;; I can, situationally, either use the original code for any given state *or* use custom code.
;; sprite status *2...
	LDA !14C8,x
	ASL #2
	TAX
	PHX
;; check if we should use the alternate state pointers
	JSR (.ptr,x)
	PLX
	BCC .Finish
;; store pointer position to $00
	REP #$20
	LDA .ptr+$2,x
	STA $00
	CMP #$FFFF
	SEP #$20
	BEQ .Finish
	PHX
	LDA #$80
	LDX $15E9|!addr
	ORA !7FAB34,x
	STA !7FAB34,x
	PLX
;; jump to the defined address
	LDX #$00
	JSR ($0000,x)
.Finish
	LDX $15E9|!addr
	PLB
	RTL

.ptr	dw AltStatus_Never :	dw $FFFF		; x00 Null
	dw AltStatus_Never :	dw $FFFF		; x01 Init (Handled above)
	dw AltStatus_Detach :	dw $FFFF		; x02 Killed
	dw AltStatus_Detach :	dw $FFFF		; x03 Smushed
	dw AltStatus_Detach :	dw $FFFF		; x04 Spin Kill
	dw AltStatus_Detach :	dw $FFFF		; x05 Sinking in lava
	dw AltStatus_Detach :	dw $FFFF		; x06 Goal Tape Coin
	dw AltStatus_Detach :	dw $FFFF		; x07 In Yoshi's mouth
	dw AltStatus_Always :	dw SpriteStatus_Main	; x08 Normal
	dw AltStatus_UnStun :	dw SpriteStatus_Stunned	; x09 Stunned
	dw AltStatus_UnStun :	dw SpriteStatus_Stunned	; x0A Kicked
	dw AltStatus_Carried :	dw $FFFF		; x0B Carried
	dw AltStatus_Detach :	dw $FFFF		; x0C Goal Tape powerup

;; I do this to determine in what circumstances I will use custom code
AltStatus:
.Detach
	LDX $15E9|!addr
;; detach sprite from carpet
	;LDA !1534,x
	;BNE .Never
	BRA .Never
	LDA #$01
	STA !1534,x
.DoDetach
	STZ $00
	LDA #$0C
	STA $01
	STZ $02
	STZ $03
	LDA !7FAB9E,x
	SEC
	%SpawnSprite()
	BCS .DontSpawn
	PHY
	LDY #$00
	LDA [$8A],y
	PLY
	AND #$80
	BEQ +

	LDA !161A,x
	STA !161A,y

+	LDA !1510,x
	PHX
	TYX
	STA !1510,x
	LDA #$08
	STA !14C8,x
	LDA #$02
	STA !1534,x
	LDA #$FF
	STA !1504,x
	PHX
	LDX $15E9|!addr
	LDA !1570,x
	PLX
	STA !1570,x
	PLX
.DontSpawn
.Never	CLC
	RTS
.Always	SEC
	RTS
.UnStun	JSR .HandleCarpet
	BCS .Never
	CLC
	LDY #$00
	LDA [$8A],y
	AND #$40
	BEQ +
	SEC
+	JMP .Detach
.Carried
	JSR .HandleCarpet
	BCS .Never
;; here, I still want to use default code as well, so I'm just modifying some values here
	LDY #$00
	LDA [$8A],y
	AND #$40
	BEQ +
	INC !1570,x
	LDA !1570,x
	LSR #2
	AND #$01
	STA !1602,x
	STZ !1540,x
+	CLC
	JMP .Detach

.HandleCarpet
	LDX $15E9|!addr
	LDA !1534,x
	CMP #$02
	BNE +
	LDA !14C8,x
	CMP #$08
	BEQ +
	STZ !B6,x
	STZ !AA,x
	LDA #$08
	STA !14C8,x
	SEC
	RTS
+	CLC
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Normal Sprite Status
;;;;;;;; Handles all unique behaviors

SpriteStatus_Main:
	LDX $15E9|!addr
	LDA #$00
	%SubOffScreen()

	LDA !1534,x
	INC !1570,x
	AND #$03
	CMP #$02
	BCC +
	LDA #$02
+	ASL
	TAX
	JMP (.ptr,x)
.ptr	dw Main_PidgitWCarpet
	dw Main_PidgitSolo
	dw Main_Carpet

Main_PidgitSolo:
	LDX $15E9|!addr
;; just animate
	LDA !1570,x
	INC !1570,x
	LSR #4
	AND #$01
	STA !1602,x
;; basic object collision
	LDA !1588,x
	AND #$0C
	BEQ +
	STZ !AA,x
	AND #$04
	BEQ +
	STZ !B6,x
+	LDA !1588,x
	AND #$03
	BEQ +
	LDA !157C,x
	EOR #$01
	STA !157C,x
	LDA !B6,x
	EOR #$FF
	INC
	STA !B6,x
+	JSL $01802A|!bank
	JMP Main_PidgitWCarpet_DoInteract

Main_Carpet:
	LDX $15E9|!addr
;; reset time if on yoshi's tongue (prevents a null sprite from being potentially created)
	LDA !15D0,x
	BEQ .NotOnTongue
	LDA !1504,x
	BEQ +
	LDA #$FF
	STA !1504,x
+	RTS
.NotOnTongue
;; allow yoshi to eat sprite but remain in his mouth
	LDA #$02
	ORA !1686,x
	STA !1686,x
;; decrease timer and despawn when zero
	LDA $14
	AND #$03
	BNE .NoDec
	LDA !1504,x
	BEQ .NoDec
	DEC
	BNE +
	STZ !14C8,x
;; allow respawning if set to
	LDY #$00
	LDA [$8A],y
	AND #$80
	BEQ .DontRespawn
	LDA !161A,x
	PHX
	TAX
	LDA #$00
if !Disable255SpritesPerLevel
	STA !1938,x
else
	STA.L !7FAF00,x
endif
	PLX
.DontRespawn
.Return	RTS
+	DEC !1504,x
.NoDec	JSL $01801A|!bank
	JSL $018022|!bank
	JSL $019138|!BankB	; interact w/ blocks
	LDA !1528,x
	BNE .RideCloud
;; don't interact if no-contact time is set or riding yoshi
	LDA !154C,x
	ORA $187A|!addr
	BNE .Return
;; get clipping and check contact
	LDA !1662,x
	PHA
	JSL $03B664|!bank
	JSL $03B69F|!bank
	PLA
	STA !1662,x
	JSL $03B72B|!bank
	BCC .Return
;; check if mario is above sprite
	LDA $7D
	BMI .Return
	%SpriteEdgeTop()
	BCC .Return
	INC !1528,x
	REP #$20
	LDA #$0020
	BRA .RideCloud_2
.RideCloud
if !CustomCarpetControls == 0
	PHB
	LDA #$02
	PHA
	PLB
	JSL $02D214|!bank
	PLB
	LDA !AA,x
	CLC
	ADC #$03
	STA $7D
else
;; setup parameters
	LDY $59
	REP #$20
	LDA Settings_Carpet_Pointer,y
	STA $0C
	SEP #$20
	LDA Settings_Carpet_Pointer+$2,y
	STA $0E

	LDY #$00
	LDA $15
	AND #$40
	BEQ +
	INY
+	LDA [$0C],y
	STA $00
	INY #2
	LDA [$0C],y
	STA $01
	INY #3
	LDA [$0C],y
	STA $03
	INY #2
	LDA [$0C],y
	STA $04

	LDY #$04
	LDA [$0C],y
	STA $02
	LDY #$09
	LDA [$0C],y
	STA $05
	INY
	LDA [$0C],y
	STA $06

	SEC
	%LakituCloudControls()
endif
;; lock sprite to mario's position
	REP #$20
	LDA #$001C
..2	CLC
	ADC $96
	SEP #$20
	STA !D8,x
	XBA
	STA !14D4,x

	REP #$20
	LDA $94
	SEP #$20
	STA !E4,x
	XBA
	STA !14E0,x
;; drop yoshi if he's somehow being ridden
	LDA $187A|!addr
	BEQ .DontDropYoshi
	PHX
	LDX $18E2|!addr
	DEX
	LDA #$10
	STA !163E,x
	LDA #$03
	STA $1DFA|!addr
	STZ !C2,x
	STZ $187A|!addr
	STZ $0DC1|!addr
	LDA #$C0
	STA $7D
	STZ $7B
	LDY !157C,x
	STZ !1594,x
	STZ !151C,x
	PLX
.DontDropYoshi
;; set ride state
	LDA #$02
	STA $1471|!addr
	INC $18C2|!addr
;; allow jumping out of carpet
	LDA $16
	ORA $18
	AND #$80
	BEQ .Return2
	LDA #$C0
	STA $7D
	LDA #$10
	STA !154C,x
	STZ !1528,x
	LDA #$0B
	STA $72
.Return2
	RTS
.Byte_Picker
	db $00,$02,$05,$07
	db $00,$01,$03,$04

Main_PidgitWCarpet:
	LDX $15E9|!addr
;; detach if being eaten
	LDA !15D0,x
	BEQ .DontDetach
	LDA !1534,x
	BNE +
	INC
	STA !1534,x
+	JMP AltStatus_DoDetach
.DontDetach
;; shoot fire if set to
	LDA !15AC,x
	BEQ .NoFire
	CMP #$2F
	BNE .NoFire
	LDY #$03
-	LDA #$04
	STA $00
	STA $01

	LDA .FireXSpeed,y
	STA $02
	LDA .FireYSpeed,y
	STA $03

	PHY
	LDA.b #$0B
	%SpawnExtended()
	PLY
	BCS .NoFire
	PHX
	TYX
	LDA #$00
	STA !extended_table,x
	STA !extended_timer,x
	PLX

	LDA #$06
	STA $1DFC|!addr

	DEY
	BPL -

.NoFire	LDA !163E,x
	BNE .DoCollision
;; animate and set velocity
	JSL $01801A|!bank
	JSL $018022|!bank
	LDA !1570,x
	LSR #3
	AND #$01
	STA !1602,x

; added by Oliver
	PHX
	JSL $019138|!BankB	; interact w/ blocks
	PLX

	LDA !157C,x
	AND #$84
	BEQ .NormalMovement
	JSR .SwoopPhysics
.CheckPosition
;; if coming up from a swoop, check position relative to origin
	LDA !1540,x
	BNE .DoCollision
	LDA !1504,x
	STA $00
	LDA !1528,x
	STA $01

	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	SEC
	SBC $00
	BPL .DoCollision
	LDA $00
	SEP #$20
	STA !D8,x
	XBA
	STA !14D4,x

;; reset timer and null speeds
	LDA !157C,x
	AND #$FB
	STA !157C,x
	STZ !B6,x
	STZ !AA,x
	LDY #$02
	LDA [$8A],y
	STA !1540,x

.DoCollision
	SEP #$20
	JMP .DoInteract

.FireXSpeed	db $10,$F0,$08,$F8
.FireYSpeed	db $EC,$EC,$E0,$E0

.NormalMovement
	PHX
	LDX #$00
	LDY #$03
-	LDA [$8A],y
	STA $00,x
	EOR #$FF
	INC
	STA $01,x
	INY : INX #2
	CPY #$0D
	BCC -
	PLX

	LDY #$09
	LDA [$8A],y
	ASL
	CMP.b #(Patterns_List_end-Patterns_List)
	BCC +
	LDA #$00
+	TAX
	JSR (Patterns_List,x)
.DoInteract
	JSR SpriteInteraction
	JSL $018032|!bank
if !CanBeCapeKilled
	%CapeContact()
	BCC .NoCapeContact
	LDA #$02
	STA !14C8,x
	LDA #$00
	JSL $02ACE5|!bank
	LDA #$03
	STA $1DF9|!addr
	LDA #$C0
	STA !AA,x
	%SubHorzPos()
	LDA .Killed_XSpeed,y
	STA !B6,x
	RTS
.Killed_XSpeed
	db $F8,$08
.NoCapeContact
endif
if !TurnToSilverCoin
	LDA $14AE|!addr
	BEQ .NoSilverPOW
	PHA
	JSR .BecomeCoin
	PLA
	CMP #$B0
	BCC +
	LDA #$D0
	STA !AA,x
+	LDA !15F6,x
	AND #$F1
	ORA #$02
	STA !15F6,x
	SEC
	JMP AltStatus_DoDetach
.NoSilverPOW
endif
if !CanBeFireKilled
	%FireballContact()
	BCC .NoFireContact
	LDA #$01
	STA !extended_num,y
	LDA #$0F
	STA !extended_timer,y

	LDA #$03
	STA $1DF9|!addr
	JSR .BecomeCoin
	LDA #$D0
	STA !AA,x
	%SubHorzPos()
	TYA
	EOR #$01
	STA !157C,x
	SEC
	JMP AltStatus_DoDetach

.NoFireContact
endif
	RTS

.BecomeCoin
	LDA #$21
	STA !9E,x
	LDA #$08
	STA !14C8,x
	JSL $07F7D2|!bank
	STZ !1528,x
	STZ !1534,x

	RTS

.SwoopPhysics
	LDY #$07
	LDA [$8A],y
	STA $01
	LDY #$00
	LDA [$8A],y
	LDY #$00
	AND #$02
	STA $00
	BEQ +
	LDA $1491|!addr
	PHA
	JSL $01801A|!bank
	PLA
	STA $1491|!addr
	INY
+ : -	PHY
	LDY #$00
	LDA [$8A],y
	PLY
	AND #$04
	BEQ .CantFire
	LDA !15AC,x
	BNE .CantFire
	LDA !AA,x
	CLC
	ADC #$02
	CMP #$04
	BCS .CantFire
	LDA #$30
	STA !15AC,x
.CantFire
	LDA $01
	BPL +
	LDA $14
	LSR
	BCC .Loop
+	LDA !AA,x
	BEQ .Normal
	BMI .Normal
	DEC !AA,x
	BRA .Loop
.Normal	LDA !157C,x
	AND #$7F
	STA !157C,x
	PHY
	LDY $00
	BEQ +
	DEC !AA,x
+	PLY
	DEC !AA,x
	BPL .Loop
	CMP #$88
	BPL .Loop
	LDA #$88
	STA !AA,x
.Loop	DEY
	BPL -
	RTS

Pattern_Chasing:
	LDX $15E9|!addr
	JSR Pattern_Oscillating_YSpeed

	LDA !1540,x
	BNE .DoChase
	JSR .GetMarioAbove
	BMI +
	LDA #$20
	STA !1540,x
	BRA .DoChase
+	LDY #$02
	LDA [$8A],y
	STA !1540,x
	LDY #$00
	LDA [$8A],y
	AND #$02
	STA $00

	LDY #$08
	LDA [$8A],y
	STA $01

	LDY #$00
	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	SEC
	SBC $94
	BPL +
	INY
	EOR #$FFFF
	INC
+	PHY
	LSR
	LDY $00
	BNE +
	LSR
+	PLY
	SEP #$20
	CMP $01
	BCC +
	LDA $01
+	CPY #$00
	BNE +
	EOR #$FF
	INC
+	STA !B6,x
	JMP DoSwoop
.DoChase
	%SubHorzPos()

	PHY
	LDY #$00
	JSR .GetMarioAbove
	BPL +
	INY #2
+	REP #$20
	LDA .Range,y
	PLY
	STA $0A
	ASL
	STA $0C

	LDA $0E
	CLC
	ADC $0A
	CMP $0C
	SEP #$20
	BCC +
.AlwaysChase
	TYA
	ASL
	STA $0C
	LDA !157C,x
	AND #$FD
	ORA $0C
	STA !157C,x
+	LDA !157C,x
	AND #$02
	LSR
	TAY
	JSR Pattern_Oscillating_Accelerate
	RTS
.Range	dw $0004,$0020
.GetMarioAbove
	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	SEC
	SBC $96
	CLC
	ADC #$0010
	SEP #$20
	RTS
.Offset	dw $0020,$FFE0

Pattern_Oscillating:
	LDX $15E9|!addr
	LDA !B6,x
	PHA
	LDA $02
	ASL
	STA $0F
	PLA
	CLC
	ADC $02
	CMP $0F
	BCS .NotSwooping

	LDA !1594,x
	BNE .NotSwooping

	%SubHorzPos()
	LDA $0A,y
	STA !B6,x
	JMP DoSwoop

.NotSwooping
	JSR .YSpeed

.XSpeed	LDA !157C,x
	AND #$02
	LSR
	TAY

	LDA !1540,x
	BEQ .Decelerate
.Accelerate
	TYA
	BNE ..Neg
..Pos	LDA !B6,x
	BEQ ..Accel
	BMI ..Accel
	CMP $06,y
	BCC ..Accel
	BRA ..SetSpeed
..Neg	LDA !B6,x
	BPL ..Accel
	CMP $06,y
	BCS ..Accel
..SetSpeed
	LDA $06,y
	BRA .DoSetSpeed
..Accel	CLC
	ADC $02,y
	BRA .DoSetSpeed

.Decelerate
	LDA !B6,x
	BEQ ..SetNewTime
	TYA
	BEQ ..Neg
..Pos	LDA !B6,x
	BPL ..SetNewTime
	CMP $02,y
	BCC ..Decel
	BRA ..SetNewTime
..Neg	LDA !B6,x
	BMI ..SetNewTime
	CMP $02,y
	BCC ..SetNewTime
..Decel	LDA !B6,x
	SEC
	SBC $02,y
	BRA .DoSetSpeed
..SetNewTime
	PHA
	LDA !157C,x
	EOR #$02
	STA !157C,x
	LDY #$02
	LDA [$8A],y
	STA !1540,x
	DEC !1594,x
	PLA
.DoSetSpeed
	STA !B6,x
	RTS

.YSpeed	LDA !157C,x
	AND #$01
	PHA
	TAY
	PLA
	BNE ..Neg
..Pos	LDA !AA,x
	BMI ..Accel
	CMP $04,y
	BPL ..SetSpeed
	BRA ..Accel
..Neg	LDA !AA,x
	BPL ..Accel
	CMP $04,y
	BPL ..Accel
..SetSpeed
	LDA !157C,x
	EOR #$01
	STA !157C,x
	LDA $04,y
	BRA +
..Accel	CLC
	ADC $00,y
+	STA !AA,x
	RTS

DoSwoop:
	LDY #$07
	LDA [$8A],y
	BPL .NormalSwoop

	LDA !157C,x
	ORA #$80
	STA !157C,x

	JSR .GetDiveSpeed
.NormalSwoop
	STA !AA,x

	LDY #$00
	LDA [$8A],y
	AND #$01
	BEQ +
	LDA #$10
	STA !163E,x
+	LDA #$18
	STA !1540,x
	LDA !157C,x
	ORA #$04
	STA !157C,x
	LDY #$01
	LDA [$8A],y
	STA !1594,x
	RTS

.GetDiveSpeed
	REP #$20
	LDA $96
	CLC
	ADC #$0004
;; (if the sprite returns to its normal Y position we slightly adjust it, otherwise it swoops too low)
	SEP #$20
	SEC
	SBC !D8,x
	STA $0E
	XBA
	SBC !14D4,x
	STA $0F
;; if mario is below sprite, actually load the speeds
	REP #$20
	LDA $0E
	BPL +
	SEP #$20
;; otherwise if mario is above the sprite, it'll always do the lowest swoop
	LDY #$00
	BRA .SetSpeed
+	LSR #3
	TAY
	SEP #$20
;; also, if mario is far too low, it'll use the furthest swoop possible
	CPY #$1F
	BCC .SetSpeed
	LDY #$1F
.SetSpeed
	LDA DiveSpeed,y
	RTS


SpriteInteraction:
	LDA !1662,x
	PHA
	LDA !151C,x
	AND #$40
	BEQ .NotIntro
	PHX
	LDX #$00
	PHY
	LDY #$00
	LDA [$8A],y
	PLY
	AND #$80
	BEQ +
	LDX #$14
+	TXA
	PLX
	STA !1662,x
.NotIntro
	LDA $140D|!addr
	PHA
	LDY #$00
	LDA [$8A],y
	PHA
	AND #$10
	BEQ +
	STZ $140D|!addr
+	PLA
	AND #$08
	BEQ .DefaultInteract
	%SprCollision_RideSprite()
	BCC .FinishSprCollision
	PLA
	STA $140D|!addr
	BIT $16
	BVC .FinishSprCollision_2
	LDA $1470|!addr
	ORA $148F|!addr
	ORA $187A|!addr
	ORA $1498|!addr
	BNE .FinishSprCollision_2
	LDY #$00
	LDA [$8A],y
	AND #$20
	BNE .FinishSprCollision_2
	LDA !151C,x
	AND #$40
	BNE .FinishSprCollision_2
	TXA
	INC
	STA $1470|!addr
	LDA #$0B
	STA !14C8,x
	LDA #$10
	STA $1498|!addr
	LDA #$FF
	STA !1540,x
	LDA #$08
	STA !1564,x
	STA !154C,x
	STZ !163E,x
	LDA !151C,x
	AND #$80
	STA !151C,x
	BRA .FinishSprCollision_2
.DefaultInteract
	LDA !1662,x
	PHA
	LDY #$00
	LDA [$8A],y
	AND #$20
	BNE +
	LDA !1662,x
	ORA #$80
	STA !1662,x
+	JSL $01A7DC|!bank
	PLA
	STA !1662,x
.FinishSprCollision
	PLA
	STA $140D|!addr
..2	PLA
	STA !1662,x
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Stunned Sprite Status
;;;;;;;; Utilizes generic gravity/collision, but will bounce on the ground a few times before returning to state x08.
;;;;;;;; This is intended to mimic the SMB2 "thrown" state.

SpriteStatus_Stunned:
	LDX $15E9|!addr
	LDA #$00
	%SubOffScreen()

	JSL $01802A|!bank

	LDA !1686,x
	PHA
	ORA #$80
	STA !1686,x
	JSL $01A7DC|!bank
	PLA
	STA !1686,x

	JSL $018032|!bank
	RTS

GetSettingsPointer:
;; setup a 24-bit pointer to the sprite's settings
	LDA !1510,x
	REP #$20
	AND #$00FF
	STA $8A
	ASL
	ADC $8A
	STA $59
	TAY
	LDA Settings_Pointer,y
	STA $8A
	SEP #$20
	LDA Settings_Pointer+$2,y
	STA $8C
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GFX Routine
!0300	= $0300|!addr
!0301	= $0301|!addr
!0302	= $0302|!addr
!0303	= $0303|!addr
!0460	= $0460|!addr

SubGFX:	LDX $15E9|!addr
	%GetDrawInfo()
	LDA #$FF
	STA $0F

	LDA !14C8,x
	CMP #$02
	BEQ .Flip
	CMP #$09
	BCC +
.Flip	LDA !15F6,x
	ORA #$80
	STA !15F6,x

+	LDA !1602,x
	STA $03

	LDA !15F6,x
	PHA
	AND #$80
	STA $05
	PLA
	AND #$0E
	STA $04

	PHY
	LDY #$0A
	LDA [$8A],y
	PLY
	CMP #$FF
	BEQ +
	AND #$0E
	STA $04

+	LDA !166E,x
	AND #$01
	ORA $04
	STA $04

	LDX $15E9|!addr
	LDA !1534,x
	CMP #$02
	BCC +
	LDA #$02
+	ASL
	TAX
	JSR (.ptr,x)

	LDY #$FF
	LDA $0F
	JSL $01B7B3|!bank
	RTS

.ptr	dw .DrawPidgitAndCarpet
	dw .DrawPidgit
	dw .DrawCarpet

.DrawPidgitAndCarpet
	LDA $14
	AND #$01
	BNE +
	JSR ++
	JSR .DrawPidgit
	RTS

+	JSR .DrawPidgit
++	LDA $01
	PHA
	CLC
	ADC #$0C
	STA $01
	JSR .DrawCarpet_Child
	PLA
	STA $01
	RTS

.DrawPidgit
	LDX $15E9|!addr
	LDA $00
	STA !0300,y

	LDA $01
	STA !0301,y

	PHY
	LDA $03
	CLC
	ADC #$0B
	TAY
	LDA [$8A],y
	PLY
	STA !0302,y

	PHY
	LDA $03
	CLC
	ADC #$0D
	TAY
	LDA [$8A],y
	PLY
	ORA $04
	ORA $05
	ORA $64
	STA !0303,y

	PHY
	TYA
	LSR #2
	TAY
	LDA #$02
	STA !0460,y
	PLY

	INY #4

	INC $0F
	RTS

.DrawCarpet
	LDX $15E9|!addr
	LDA !1504,x
	BEQ .DrawCarpet_Child
	CMP #$40
	BCS .DrawCarpet_Child
	AND #$01
	BNE .DrawCarpet_Child_NoDraw
.DrawCarpet_Child
	LDX $15E9|!addr
	LDA !1570,x
	LSR #2
	AND #$07
	STA $08
	ASL #2
	STA $09
	PHX
	LDX #$03
-	TXA
	ASL #3
	CLC
	ADC #$F8
	CLC
	ADC $00
	STA !0300,y

	LDA $01
	STA !0301,y

	PHX
	TXA
	CLC
	ADC $09
	TAX
	LDA .Carpet_Tilemap,x
	STA !0302,y
	PLX

	PHY
	LDY #$0F
	LDA [$8A],y
	LDY $08
	ORA .Carpet_Props,y
	PLY
	ORA #$01
	ORA $64
	STA !0303,y

	PHY
	TYA
	LSR #2
	TAY
	LDA #$00
	STA !0460,y
	PLY

	INY #4
	INC $0F
	DEX
	BPL -
	PLX
..NoDraw
	RTS
.Carpet_Tilemap
	db !Carpet_Tile1,!Carpet_Tile1+1,!Carpet_Tile1+2,!Carpet_Tile1+3
	db !Carpet_Tile2,!Carpet_Tile2+1,!Carpet_Tile2+2,!Carpet_Tile2+3
	db !Carpet_Tile3,!Carpet_Tile3+1,!Carpet_Tile3+2,!Carpet_Tile3+3
	db !Carpet_Tile4,!Carpet_Tile4+1,!Carpet_Tile4+2,!Carpet_Tile4+3
	db !Carpet_Tile4+3,!Carpet_Tile4+2,!Carpet_Tile4+1,!Carpet_Tile4
	db !Carpet_Tile3+3,!Carpet_Tile3+2,!Carpet_Tile3+1,!Carpet_Tile3
	db !Carpet_Tile2+3,!Carpet_Tile2+2,!Carpet_Tile2+1,!Carpet_Tile2
	db !Carpet_Tile1+3,!Carpet_Tile1+2,!Carpet_Tile1+1,!Carpet_Tile1

.Carpet_Props
	db $00,$00,$00,$00,$40,$40,$40,$40

.X_Disp	db $00,$10,$00,$10
.Y_Disp	db $F0,$F0,$00,$00
	db $F2,$F2,$02,$02
	db $F0,$F0,$00,$00

.Y_Offs	db $00,$02,$00