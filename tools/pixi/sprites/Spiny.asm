;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spiny (Mario-Bros) by Sonikku (optimized by Blind Devil)
;;
;; Description: A sprite that walks; hit by a cape, bounce block, etc., it be stunned. Walking into it while it is
;; stunned will cause Mario to defeat it by kicking it off the screen. Be warned; by default, after it's period of 
;; being stunned, it'll hop back up in a new color and move faster. It goes from red -> green -> blue.
;; A shell will defeat it instantly.
;; 
;; This sprite uses custom interaction with most forms of damage, barring sprites.
;; I have documented which CFG editor features are enabled through additional code.
;; 
;; Supported Features:
;;;; Extra Bit:
;;;;;; - If set, the sprite will be either a green or blue Spiny based on the X position.
;;;;;; 
;;;; Extra Property Byte 1: xBCFxxSL ********************************************************* Bit value
;;;;;; - L: Stays on ledges --------------------------------------------------------------------- $01
;;;;;; - S: Won't shift color ------------------------------------------------------------------- $02
;;;;;; - x: unused ------------------------------------------------------------------------------ $04
;;;;;; - x: unused ------------------------------------------------------------------------------ $08
;;;;;; - F: Dies from fire (unless "Disable fireball killing" is checked) ----------------------- $10
;;;;;; - C: Dies from cape (unless "Disable cape killing" is checked) --------------------------- $20
;;;;;; - B: Dies from blocks -------------------------------------------------------------------- $40
;;;;;; - E: Can exit through horizontal pipes --------------------------------------------------- $80
;;;;;; 
;;;; Other Features:
;;;;;; - If "Spawns a new sprite" is checked and it can die to fire, it will spawn a coin if killed by a fireball.
;;;;;; - If "takes 5 fireballs to kill" is checked and it can die to fire, it'll have 5 fireball HP.
;;;;;; - Spawning the sprite with !163E,x set will cause it to walk (without gravity) and appear behind objects.
;;;;;; - If spawned with !C2,x set to #$02, it'll appear to be a Spiny egg until it touches the ground.
;;;;;; - The highest bit of !C2,x (1xxxxxxx/#$80) determines that when !163E,x is up, the sprite gets deleted (used for an exit animation).
;;;; Default CFG Files:
;;;; - Spiny.cfg:			No special qualities whatsoever.
;;;; - Spiny_Ledge.cfg:			Attempts to stay on ledges.
;;
;; If you want to remap tiles, modify palettes and so on, search for 'Tilemap defines'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	print "INIT ",pc
	%SubHorzPos()	; \
	TYA		;  | set direction based on where mario is
	STA !157C,x	; /

	LDA #$02
	STA !C2,x

	LDA !7FAB10,x	; \
	AND #$04	;  | branch if extra bit not set
	BEQ +		; /
	LDA !E4,x	; \
	LSR #4		;  | load color based on current x position x16
	AND #$01	;  | 
	INC		;  | 
	STA !1594,x	; /
+	RTL

	print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR SpinyMain
	PLB
	RTL

SpinyMain:
	LDA #$00
	%SubOffScreen()
	LDA $64			; \
	PHA			;  | 
	LDA !C2,x		;  | \
	AND #$80		;  |  |	 go behind objects if state set
	BNE .behindobj		;  | /
	LDA !163E,x		;  | 
	BEQ +			;  | force sprite behind foreground if needed
.behindobj
	LDA #$10		;  | 
	STA $64			;  | 
+	JSR SubGfx		;  |  load graphics
	PLA			;  | 
	STA $64			; /
	LDA $9D			; \ return if sprites locked
	BNE returniskill	; /
	LDA !14C8,x		; \
	CMP #$08		;  | return if sprite isn't "normal"
	BNE returniskill	; /
	LDA !163E,x		; \ branch if spawn timer isn't set
	BEQ normal		; /
	JSL $018022|!BankB	; \ set x/y speed without gravity
	JSL $01801A|!BankB	; /
	INC !1570,x		; increment frame counter
	LDA !1570,x		; \
	LSR #2			;  | set frame based on frame counter
	AND #$01		;  | 
	CMP #$03		;  | 
	BCC +			; /
	STZ !1570,x		; 
	LDA #$02		; \
+	LDY !C2,x		;  | 
	CPY #$02		;  | 
	BNE +			;  | 
	CLC			;  | 
	ADC #$06		;  | 
+	STA !1602,x		; /
	LDY !157C,x		; \
	LDA xspd_pipe,y 	; | set x speed
	STA !B6,x		; /
returniskill:
	RTS
xspd_pipe:
	db $08,$F8

normal:	LDA !C2,x	; \
	AND #$80	;  | kill sprite if state is set
	BEQ .stayalive	;  | 
	LDY !161A,x	;  | \
	CPY #$FF	;  |  | 
	BEQ +		;  |  | kill sprite (but allow it to respawn if it can)
	PHX		;  |  | \
	TYX		;  |  |  |
	LDA #$00	;  |  |  |
	STA !1938,x	;  |  | / needed because Y doesn't accept long range addresses (SA-1 = $418A00)
	PLX		;  | /
+	STZ !14C8,x	; /
	RTS		; 
.stayalive
	JSR BounceBlockContact
	JSR CapeContact
	JSR FireballContact
	JSR MarioContact
	JSL $01802A|!BankB	; move sprite based on x/y speeds with gravity
	JSL $018032|!BankB
	LDA !1FD6,x		; \
	AND #$80		;  | damage sprite if flag is set
	BEQ +			;  | 
	STZ !1FD6,x	; /
	JSR DamageSprite
+	LDA !C2,x	; \
	CMP #$02	;  | branch if state =/= #$02
	BNE +		; /
	INC !1570,x	; increment frame counter
	LDA !1570,x	; \
	LSR #2		;  | 
	AND #$01	;  | animate sprite
	CLC		;  | 
	ADC #$06	;  | 
	STA !1602,x	; /
	LDA !1588,x	; \
	AND #$04	;  | branch if sprite not on ground
	BEQ returniskill	; /
	STZ !C2,x	; clear state
	RTS		; 
+	LDA !1570,x	; \
	LSR #3		;  | 
	AND #$03	;  | 
	CMP #$03	;  | 
	BNE +		; /
	LDA #$02	; 
	STZ !1570,x	; 
+	LDY !C2,x	; \ 
	BEQ .setframe	; /
	PHA		; 
	LDA $14		; \
	AND #$01	;  | increment !1504,x every other frame
	BNE +		;  | 
	INC !1504,x	; /
+	PLA		; 
	CLC		; \
	ADC #$03	; /
.setframe
	STA !1602,x	; /

	LDA !1588,x	; \ turn around if it hits a wall
	AND #$03	; /
	BEQ +
	JSR .handlewalls

+	LDA !1588,x	; \
	AND #$04	;  | detect if sprite is on the ground
	BEQ .in_air	; /
	LDY #$00	; \
	LDA $15B8,x	;  | 
	BEQ +		;  | manage sprite y speed; force it downwards if it's on a slope (to properly walk down them if it stays on ledges)
	LDY #$18	;  | 
+	STY !AA,x	; /
	JSR .sprite_speed
	LDA #$01	; \ sprite is on the ground (will turn around when it starts to fall)
	STA !1510,x	; /
	LDA !C2,x
	BNE .flipped_anim
	LDA #$01
	LDY !1594,x	;  | \
	CPY #$02	;  |  | factor in "fast" color to apply animation speed to
	BCC .setrate	;  |  | 
	INC		;  | /
	BRA .setrate
.flipped_anim
	LDY #$01		; load animation rate
	LDA !1504,x		; \
	CMP #$F0		;  | branch if below #$F0
	BCC +			; /
	STZ !C2,x		; clear state
	STZ !1504,x		; clear timer
	LDA #$E0		; \ set y speed
	STA !AA,x		; /
	LDA #$10		; \ disable contact with sprites
	STA !1564,x		; /
	RTS			; 
+	CMP #$A0		; \ branch if sprite should change clor
	BEQ .increase_speed	; / 
	BCC +			; 
	LDY #$04		; load animation rate
+	TYA			; \
.setrate
	CLC			;  | 
	ADC !1570,x		;  | 
	STA !1570,x		;  | 
	RTS			; /
.in_air	LDA !1588,x		; \
	AND #$08		;  | nullify y speed if hitting a ceiling
	BEQ +			;  | 
	STZ !AA,x		; /
+	LDA !1510,x		; \ branch if "was on ground" state is not set
	BEQ +			; /
	LDA !7FAB28,x		; \
	AND #$01		;  | branch if sprite shouldn't turn around on ledges
	BEQ +			; /
	JSR .turn_around
+	STZ !1510,x		; clear "was on ground" state
	RTS			; 
.increase_speed
	LDA !7FAB28,x		; \
	AND #$02		;  | don't shift color if it isn't able to
	BNE +			; /
	LDA !1558,x		; \ don't run if timer is set
	BNE +			; /
	LDA #$80	; \ set timer
	STA !1558,x	; /
	LDA !1594,x	; \
	CMP #$02	;  | increase color value
	BCS +		;  | 
	INC !1594,x	; /
+	RTS		; 
.sprite_speed
	LDA !1594,x	; \
	ASL #2		;  | 
	CLC		;  | 
	ADC !C2,x	;  | index sprite speed by current state, color, and direction
	ADC !C2,x	;  | index sprite speed by current state, color, and direction
	TAY		;  | 
	LDA !157C,x	;  | 
	BEQ +		;  | 
	INY		; /
+	LDA .xspd,y	; \ set sprite speed
	STA !B6,x	; /
	RTS

.xspd	db $0C,$F4	; slow (red)
	db $00,$00	; stunned (red) (note: leave this alone)

	db $10,$F0	; slow (green)
	db $00,$00	; stunned (green) (note: leave this alone)

	db $14,$EC	; slow (blue)
	db $00,$00	; stunned (blue) (note: leave this alone)

.handlewalls
	LDA !7FAB28,x		; \
	AND #$80		;  | branch if sprite should enter pipes
	BEQ .turn_around	; /
	STZ $00			; clear flag
	LDY #$03		; load times to loop
-	LDA $18A7|!Base2	; \ get tile number
	CMP .tile,y		; /
	BNE +			; branch if not matching
	TYA			; \
	INC			;  | set flag
	STA $00			;  | 
	BRA ++			; /
+	DEY			; decrement y
	BPL -			; loop
++	LDA $00			; \ flip direction if it never found a match
	BEQ .turn_around	; /
	LDA !C2,x		; \ 
	ORA #$80		;  | set "leaving via pipe" flag
	STA !C2,x		; /
	LDA #$20		; \ set timer
	STA !163E,x		; /
	STZ !AA,x		; no y speed
	STZ !B6,x		; no x speed

	LDA $00			; \
	DEC			;  | index by $00
	TAY			; /
	LDA !D8,x		; \ 
	DEC			;  | load y position into scratch ram
	STA $00			; /
	LDA #$0F		; \ set all bits up to #$0F i guess
	TSB $00			; /
	LDA $00			; \
	CLC			;  | offset sprite position by $00
	ADC .offset,y		;  | (this just aligns it to the tile)
	STA !D8,x		; /
	RTS			; 
.tile	db $3C,$56,$3F,$58
.offset	db $FE,$00,$FE,$00
.turn_around
	LDA !B6,x		; \
	EOR #$FF		;  | flip sprite speed
	INC			;  | 
	STA !B6,x		; /
	LDA !157C,x		; \
	EOR #$01		;  | flip sprite direction
	STA !157C,x		; /
	RTS			; 

BounceBlockContact:
	LDA !1564,x		; \ return if sprite shouldn't interact with other sprites
	BNE .no_contact		; /
	LDY #$03		; get # of slots to check for
-	LDA $1699|!Base2,y	; \ don't check clipping with nonexistent slots
	BEQ .loop		; /
	LDA $18F8|!Base2,y	; \
	CMP #$03		;  | don't check clipping with bounce blocks that currently shouldn't interact with sprites
	BCS .loop		; /
	LDA $16CD|!Base2,y	; \ load index for bounce block sprite clipping/position (?)
	BEQ .loop		; / don't interact if it's zero
	PHX			; \ 
	TAX			;  | 
	LDA $16D1|!Base2,y	;  | 
	CLC			;  | 
	ADC $029656|!BankB,x	;  | set bounce block clipping x position
	STA $00			;  | 
	LDA $16D5|!Base2,y	;  | 
	ADC $029658|!BankB,x	;  | 
	STA $08			; /
	LDA $02965A|!BankB,x	; \ set bounce block clipping width
	STA $02			; /
	LDA $16D9|!Base2,y	; \
	CLC			;  | 
	ADC $02965C|!BankB,x	;  | 
	STA $01			;  | set bounce block clipping y position
	LDA $16DD|!Base2,y	;  | 
	ADC $02965E|!BankB,x	;  | 
	STA $09			; /
	LDA $029660|!BankB,x	; \ set bounce block clipping height
	STA $03			; /
	PLX			; 
	JSL $03B69F|!BankB	; get sprite clipping
	JSL $03B72B|!BankB	; check for contact
	BCS +			; 
.loop	DEY			; \ loop if needed
	BPL -			; /
.no_contact
	RTS			; 
+	PHY			; 
	STZ $00			; 
	LDA $16D1|!Base2,y	; \
	SEC			;  | 
	SBC !E4,x		;  | get bounce block x offset low from sprite
	STA $0C			;  | 
	LDA $16D5|!Base2,y	; /
	SBC !14E0,x		; \
	BPL +			;  | set flag for which side sprite is on
	INC $00			; /
+	LDA $00			; \ set sprite direction
	STA !157C,x		; /
	LDA $0C			; \
	EOR #$FF		;  | 
	INC			;  | 
	PLY			;  | 
	BPL +			;  | 
	LSR			;  | 
	CMP #$EC		;  | set sprite x speed based on it's distance from the bounce block
	BPL .setspd		;  | 
	LDA #$EC		;  | 
	BRA .setspd		;  | 
+	ASL			;  | 
	CMP #$14		;  | 
	BMI .setspd		;  | 
	LDA #$14		;  | 
.setspd	STA !B6,x		; /
DamageSprite:
	LDA !7FAB28,x		; \
	AND #$40		;  | damage sprite if it shouldn't actually die
	BEQ +			; /
	LDA #$C0		; \ set y speed
	STA !AA,x		; /
	LDA #$03		; \ kill sprite
	STA $1DF9|!Base2	; /
	JMP KillSprite2
+	LDA #$D8		; \ set sprite y speed
	STA !AA,x		; /
	LDA #$18		; \ set timer to disable contact
	STA !1564,x		; /
	LDA #$03		; \ play sound
	STA $1DF9|!Base2	; /
	LDA #$00		; \ give score
	JSL $02ACE5|!BankB	; /
DamageSprite2:
	LDA !C2,x	; \
	CMP #$02
	BNE +
	LDA #$00
+	EOR #$01	;  | flip state
	STA !C2,x	; /
	STZ !1504,x	; end stun timer
	STZ !1510,x	; don't mark sprite as "in the air"
	LDA !7FAB28,x	; \
	AND #$02	;  | don't shift color back if it shouldn't shift colors
	BNE +		; /
	LDA !1558,x	; \
	BEQ +		;  | 
	LDA !1594,x	;  | allow color change reversal if the timer is set
	BEQ +		;  | 
	DEC !1594,x	;  | 
+	STZ !1558,x	; /
	RTS		; 

CapeContact:
	LDA !166E,x		; \
	AND #$20		;  | 
	ORA !1FE2,x		;  | 
	BNE .no_contact		; /
	LDA !1632,x		; \
	PHY			;  | 
	LDY $74			;  | 
	BEQ +			;  | don't interact with cape if mario and the sprite
	EOR #$01		;  | are not both above/behind the foreground together
+	PLY			;  | 
	EOR $13F9|!Base2	;  | 
	BNE .no_contact		; /
	LDA $13E8		; \ don't interact with cape if cape contact is disabled
	BEQ .no_contact		; /
	LDA !15D0,x		; \
	ORA !1FE2,x		;  | don't interact with cape if sprite is being eaten or it just shouldn't
	BNE .no_contact 	; /
	LDA $13E9|!Base2	; \
	SEC			;  | 
	SBC #$02		;  | 
	STA $00			;  | set cape clipping x position
	LDA $13EA|!Base2	;  | 
	SBC #$00		;  | 
	STA $08			; /
	LDA #$14		; \ set cape clipping width
	STA $02			; /
	LDA $13EB|!Base2	; \
	STA $01			;  | set cape clipping y position
	LDA $13EC|!Base2	;  | 
	STA $09			; / 
	LDA #$10		; \ set cape clipping height
	STA $03			; /
	JSL $03B69F|!BankB	; get sprite clipping
	JSL $03B72B|!BankB	; check for contact
	BCC .no_contact		; 
	%SubHorzPos()		; get mario/sprite distance information
	TYA			; \ set sprite direction
	STA !157C,x		; /
	LDA Killed_X_Speed,y	; \ set sprite speed
	STA !B6,x		; /
	LDA #$C0		; \ set sprite vertical speed
	STA !AA,x		; /
	LDA !7FAB28,x		; \
	AND #$20		;  | damage sprite if it shouldn't actually die
	BEQ +			; /
	LDA #$03		; \ play sound
	STA $1DF9|!Base2	; /
	JMP KillSprite2		; kill sprite
+	JSR DamageSprite	; damage the sprite
	LDA #$18		; \ set timer to disable contact
	STA !1FE2,x		; /
.no_contact
	RTS

FireballContact:
	LDA !166E,x
	AND #$10
	BNE .no_contact
	LDY #$09		; times to loop
-	LDA $170B|!Base2,y	; \
	CMP #$05		;  | 
	BEQ +			;  | only detect yoshi and mario fireballs
	CMP #$11		;  |
	BNE .loop		; /
+	LDA $171F|!Base2,y	; \
	SEC			;  | 
	SBC #$02		;  | 
	STA $00			;  | fireball clipping x position
	LDA $1733|!Base2,y	;  | 
	SBC #$00		;  | 
	STA $08			; /
	LDA #$0C		; \ fireball clipping width
	STA $02			; /
	LDA $1715|!Base2,y	; \
	SEC			;  | 
	SBC #$04		;  | 
	STA $01			;  | fireball clipping y position
	LDA $1729|!Base2,y	;  | 
	SBC #$00		;  | 
	STA $09			; /
	LDA #$0C		; \ fireball clipping height
	STA $03			; /
	JSL $03B69F|!BankB	; get sprite clipping
	JSL $03B72B|!BankB	; check for contact
	BCS +			; 
.loop	DEY			; 
	BPL -			; 
	RTS			; 
+	LDA #$01		; \
	STA $170B|!Base2,y	;  | turn fireball to smoke
	LDA #$10		;  | 
	STA $176F|!Base2,y	; /
	LDA !7FAB28,x		; \
	AND #$10		;  | branch if it should die to fire
	BNE .kill_fire		; /
	PHX			; 
	LDX #$10		; \
	LDA $1747|!Base2,y	;  | 
	BPL +			;  | 
	LDX #$F0		;  | set sprite x speed based on fireball x direction
+	TXA			;  | 
	PLX			;  | 
	STA !B6,x		; /
	LDA #$E8		; \ set sprite y speed
	STA !AA,x		; /
	JMP DamageSprite	; damage sprite
.kill_fire
	LDA !190F,x		; \
	AND #$08		;  | check if sprite takes 5 fireballs to kill
	BEQ .kill		; /
	INC !1528,x		; increase "hits" counter
	LDA !1528,x		; \
	CMP #$05		;  | kill sprite if hits reaches max
	BCS .kill		; /
+	LDA #$01		; \ play sound
	STA $1DF9|!Base2	; /
	RTS			; 
.no_contact
	RTS			; 
.kill	LDA #$03		; \ play sound
	STA $1DF9|!Base2	; /
	LDY #$00		; \
	LDA $1747|!Base2,y	;  | 
	BPL +			;  | 
	INY			;  | set x speed based on fireball direction
+	LDA Killed_X_Speed,y	;  | 
	STA !B6,x		;  | 
	TYA			;  | 
	STA !157C,x		; /
	LDA !1686,x		; \
	AND #$40		;  | turn to coin if it spawns a new sprite
	BNE .turn_to_coin	; /
	LDA #$E0
	STA !AA,x
	JMP KillSprite2
.turn_to_coin
	LDA #$21		; \ new sprite number
	STA !9E,x		; /
	LDA #$08		; \ new sprite status
	STA !14C8,x		; /
	JSL $07F7D2|!BankB	; initialize sprite
	LDA #$D0		; \ set y speed
	STA !AA,x		; /
	RTS			; 

MarioContact:
	LDA !154C,x		; \ return if mario can't interact with sprite
	BNE no_contactag	; /
	JSL $01A7DC|!BankB	; \ return if no contact
	BCC no_contactag	; /
	LDA !C2,x		; \
	BEQ +			; /
	LDA #$03		; \ play sound
	STA $1DF9|!Base2	; /
	LDA #$10		; \ set mario kick frame timer
	STA $149A|!Base2	; /
	%SubHorzPos()		; \
	LDA Killed_X_Speed,y	;  |  set x speed
	STA !B6,x		; /
	LDA #$E0		; \ set y speed
	STA !AA,x		; /
	JMP KillSprite2		; kill sprite
+	LDA $1490|!Base2	; \ branch if not using a star
	BEQ nostar		; /
	%Star()
	LDA #$02		; \ kill sprite
	STA !14C8,x		; /
	LDA #$E0		; \ set y speed
	STA !AA,x		; /
	LDY !157C,x		; \
	LDA Killed_X_Speed,y	; | set x speed
	STA !B6,x		; /
no_contactag:
	RTS

nostar:	JSR SubVertPosAlt	; get mario vertical position from sprite's
	REP #$20		; \
	LDA $0E			;  |
	LDY $187A|!Base2	;  | \
	BEQ +			;  |  | account for yoshi
	SEC			;  |  | 
	SBC #$0010		;  | /
+	CMP #$0014		;  | hurt mario if below interaction point
	SEP #$20		;  | 
	BCC .spritewins		; /
	LDA $7D			; \ no contact if moving upwards
	BMI no_contactag	; /
	LDA #$08		; \ disable interaction for a bit
	STA !154C,x		; /
	LDA $140D|!Base2	; \ hurt mario when not spinjumping
	ORA $187A|!Base2	;  | or on yoshi
	BEQ .spritewins		; /
	LDA #$02		; \ play sound
	STA $1DF9|!Base2	; /
	JSL $01AA33|!BankB	; set mario speed
	JSL $01AB99|!BankB	; display contact graphic
	RTS
.spritewins
	LDA #$10		; \ time to disable contact with sprite
	STA !154C,x		; /
	LDA $187A|!Base2	; \ hurt mario if not riding yoshi
	BEQ .hurtmario		; /
	PHX			; 
	LDX $18DF|!Base2	; load index of yoshi
	DEX			; 
	PHK			; 
	PEA.w .loseyoshi-1	; \
	PEA.w $0180CA-1|!BankB	;  | JSL2RTS; lose yoshi routine
	JML $01F70E|!BankB	; /
.loseyoshi
	PHX			; \
	LDX $76			;  | set x speed based on
	LDA $01EBBE|!BankB,x	;  | flipped mario direction
	PLX			;  | 
	STA !B6,x		; /
	PLX			; 
	RTS			; 
.hurtmario
	JSL $00F5B7|!BankB	; hurt mario
+	RTS			; 
KillSprite:
	LDA #$C0		; \ set y speed
	STA !AA,x		; /
	LDY !157C,x		; \
	LDA Killed_X_Speed,y	; | set x speed
	STA !B6,x		; /
	LDA #$03
	STA $1DF9|!Base2
KillSprite2:
	LDA #$02		; \ kill sprite
	STA !14C8,x		; /
	LDA #$00		; \ give score
	JSL $02ACE5|!BankB	; /
	RTS
Killed_X_Speed:
	db $F0,$10

GiveScore:
	PHY			; 
	LDA $1697|!Base2	; 
	CLC			; 
	ADC !1626,x		; 
	INC $1697|!Base2	; 
GiveScoreParent:
	TAY			; 
	INY			; 
	CPY #$08		; \ don't play sound if above #$08
	BCS +			; /
	TYA			; \
	CLC			;  | play sound based on current value
	ADC #$12		;  | 
	STA $1DF9|!Base2	; /
+	TYA			; 
	CMP #$08		; \ 
	BCC +			;  | don't continue incrementing score if above #$08
	LDA #$08		; /
+	JSL $02ACE5|!BankB	; give score
	PLY			; 
	RTS			; 

SubGfx:
	%GetDrawInfo()

	LDA !15F6,x	;load palette/properties from CFG
	AND #$01	;mask first bit (GFX page), and clear all others
	STA $04		;store to scratch RAM.

	PHY		; 
	LDY !1602,x	; \
	LDA !14C8,x	;  | 
	CMP #$08	;  | set frame index
	BEQ +		;  | override frame index if killed
	LDY #$03	;  | 
+	STY $02		; /
	PLY		; 

	LDA !157C,x
	STA $03

	REP #$20
	LDA $00
	STA $0300|!Base2,y
	SEP #$20

	PHX
	LDX $02		; index by current frame
	LDA .tilemap,x	; load tilemap
	PLX
	STA $0302|!Base2,y

	LDA !1594,x	; load sprite color
	PHX
	TAX
	LDA .palette,x	; set to palette
	PHA
	LDX $02		; index by current frame
	PLA
	ORA .flip,x	; set x flip
	LDX $03
	BNE +
	ORA #$40
+	ORA $04			; set second gfx page if configured
	PLX			; 
	ORA $64			; factor in level settings
	STA $0303|!Base2,y	; 

	LDY #$02
	LDA #$00
	JSL $01B7B3|!BankB
	RTS

;Tilemap defines:
.tilemap
	db $E0,$E2,$E4
	db $E0,$E2,$E4
	db $E6,$E8

.flip	db $00,$00,$00
	db $80,$80,$80
	db $00,$00

.palette
	db $08,$0A,$06,$06

SubVertPosAlt:
	LDY #$00	; 
	LDA !14D4,x	; 
	XBA		;  | 
	LDA !D8,x	;  | 
	REP #$20	;  | get subtract sprite's y position by mario's
	SEC		;  | 
	SBC $96		;  | 
	BMI +		;  | 
	INY		;    increment y if positive
+	STA $0E		;  | 
	SEP #$20	; /
	RTS		; 