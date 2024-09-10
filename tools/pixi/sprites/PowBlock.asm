;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; POW Block (Mario-Bros) by Sonikku (optimized by Blind Devil)
;;
;; Description: A sprite that walks hangs suspended in the air. If hit from below, it will stun, damage, or defeat
;; all enemies on the ground.
;; 
;; This sprite uses custom interaction with most forms of damage, barring sprites.
;; I have documented which CFG editor features are enabled through additional code.
;; 
;; Supported Features:
;;;; Extra Bit:
;;;;;; - If set, the sprite will align itself a half tile (8 pixels) to the right.
;;;;;; 
;;;; Extra Property Byte 1: CSFJxxxx ********************************************************* Bit value
;;;;;; - x: unused ------------------------------------------------------------------------------ $01
;;;;;; - x: unused ------------------------------------------------------------------------------ $02
;;;;;; - x: unused ------------------------------------------------------------------------------ $04
;;;;;; - x: unused ------------------------------------------------------------------------------ $08
;;;;;; - J: Can be damaged/triggered by spin jumps. --------------------------------------------- $10
;;;;;; - F: Can be damaged/triggered by fireballs. ---------------------------------------------- $20
;;;;;; - S: Can be damaged/triggered by the cape. ----------------------------------------------- $40
;;;;;; - C: Carriable. Can be picked up by standing on it and pressing the button. -------------- $80
;;;; Default CFG Files:
;;;; - PowBlock.cfg:			Can be triggered by fire, cape, spin jumping, or hitting from below and can be carried.
;;;; - PowBlock_Uncarriable.cfg:	Same as above but cannot be carried.

!SpinyNum =		$BF		; sprite number of the Mario Bros Spiny.		; \
!SideStepperNum =	$BE		; sprite number of the Mario Bros Side Stepper.		;  | leave at $FF if not using.
!FighterFlyNum =	$BD		; sprite number of the Mario Bros Fighter Fly.		; /

!NumToWhitelist =	$02		; number of sprites to whitelist

SpriteTable:
	db !SpinyNum,$01,$01		; Custom Sprite: Spiny; Damage Type: "Mario Bros"
	db !FighterFlyNum,$01,$01	; Custom Sprite: Fighter Fly; Damage Type: "Mario Bros"
	db !SideStepperNum,$01,$01	; Custom Sprite: Side Stepper; Damage Type: "Mario Bros"

;; Most sprites should behave properly with the default "cape smash"/"bounce block" damage. In the event that they do
;; not, you can add entries to the whitelist and program in what you feel should happen to the sprite(s) when this
;; sprite is triggered.
;; To find where to add more pointers to point to custom code to execute as a damage type, search this file for BOOKMARK1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	print "INIT ",pc
	LDA !7FAB10,x	; \
	AND #$04	;  | branch if extra bit not set
	BEQ +		; /
	REP #$20	; \
	LDA #$0008	;  | 
	SEP #$20	;  | 
	CLC		;  | 
	ADC !E4,x	;  | move sprite over a bit
	STA !E4,x	;  | 
	XBA		;  | 
	ADC !14E0,x	;  | 
	STA !14E0,x	; /
	STZ !1510,x	; 
+	RTL		; 

	print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR PowBlockMain
	PLB
	RTL

PowBlockMain:
	LDA #$00
	%SubOffScreen()
+	JSR SubGfx		; load graphics
	LDA $9D			; \ return if sprites locked
	BNE returneh		; /
	LDA !14C8,x		; \
	CMP #$08		;  | return if sprite isn't "normal"
	BCC returneh		; /
	BEQ normal		; 
	CMP #$0B		; \ branch if carried
	BEQ returneh		; /
	JSL $01A7DC|!BankB	; default interaction
	LDA !1588,x		; \
	AND #$04		;  | branch if in the air
	BEQ returneh		; /
	LDA #$01		; \ play sound
	STA $1DF9|!Base2	; /
	JSR SubSmoke		; 
	LDA !1570,x		; \
	ASL #2			;  | set timer based on current POW state
	EOR #$0C		;  | 
	STA !1558,x	; /
	INC !1510,x	; mark sprite as dying
	LDA #$08	; \ set regular state
	STA !14C8,x	; /
	JSR DamageSprites
	RTS

normal:	LDA !1510,x	; \ branch if not marked as dying
	BEQ .notdying	; /
	LDA !1558,x	; \ animate if timer is nonzero
	BNE +		; /
	STZ !14C8,x	; kill sprite
+	LSR #2		; \
	TAY		;  | animate
	LDA .frame,y	;  | 
	STA !151C,x	; /
	RTS		; 
.frame	db $02,$01,$00
.notdying
	JSR CapeContact
	JSR MarioContact
	JSR FireballContact
	LDA !1570,x		; \ current state = current frame
	STA !151C,x		; /
	LDA !163E,x		; \
	CMP #$06		;  | branch if not time to increase
	BNE returneh		; /
	INC !1570,x		; increase times used
	LDA !1570,x		; \
	CMP #$03		;  | branch if not used 3 times
	BCC returneh		; /
	STZ !14C8,x		; kill sprite
	JSL $07FC3B|!BankB	; show stars
returneh:
	RTS

CapeContact:
	LDA !7FAB28,x		; \ 
	AND #$40		;  | 
	BEQ .no_contact		; /
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
	LDA $13E8|!Base2	; \ don't interact with cape if cape contact is disabled
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
	JSR DamageSprite
	STZ !157C,x		; vertical direction = up
	LDA #$20		; \ disable contact
	STA !1FE2,x		; /
.no_contact
	RTS

FireballContact:
	LDA !7FAB28,x		; \ 
	AND #$20		;  | 
	BEQ .no_contact		; /
	LDA !166E,x		; \
	AND #$10		;  | 
	BNE .no_contact		; /
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
	AND #$10		;  | branch if it shouldn't be damaged to fire
	BEQ .no_contact		; /
	STZ !157C,x		; vertical direction = up
	LDA #$0C		; \ timer to stop interaction
	STA !166E,x		; /
	JSR DamageSprite
.no_contact
	RTS

MarioContact:
	JSL $03B69F|!BankB	; get sprite clipping
	LDA !1570,x		; 
	TAY			; 
	LDA !D8,x		; \
	CLC			;  | 
	ADC interact_offset1,y	;  | 
	STA $05			;  | 
	LDA !14D4,x		;  | "tweak" sprite clipping
	ADC interact_offset2,y	;  | 
	STA $0B			;  | 
	LDA interact_height,y	;  | 
	STA $07			; /

	JSL $03B664|!BankB	; get mario clipping
	JSL $03B72B|!BankB	; check for contact
	BCC nocontact		; 

	LDA $03		; \
	STA $00		;  | set a pseudo 16-bit value for mario's height clipping
	STZ $01		; /

	LDY !1570,x		; \
	LDA interact_offset,y	;  | set a pseudo 16-bit offset for interaction
	STA $02			;  | 
	STZ $03			; /

	LDA !14D4,x		; \
	XBA			;  | 
	LDA !D8,x		;  | 
	REP #$20		;  | 
	LDY $187A|!Base2	;  | 
	BEQ noyoshi		;  | 
	SEC			;  | 
	SBC #$0010		;  | 
noyoshi:
	SEC			;  | 
	SBC $96			;  | branch if hitting sprite from below
	STA $04			;  | 
	CLC			;  | 
	ADC $00			;  | 
	CMP #$0018		; \
	BPL +			; /
hitbottom2:
	JMP hitbottom		; 
+	LDA $04			; \
	CLC			;  | 
	ADC $02			;  | branch of above sprite
	CMP #$001E		;  | 
	SEP #$20		;  | 
	BPL ontop		; /
wall:	STZ $7B			; no x speed
	%SubHorzPos()		; \
	TYA			;  | index by side of sprite
	ASL			;  | 
	TAY			; /
	REP #$20		; \
	LDA $94			;  | 
	CLC			;  | push mario away from sprite
	ADC mario_xoffset,y
	STA $94			;  | 
	SEP #$20		; /
nocontact:
	RTS
mario_xoffset:
	dw $0001,$FFFF
interact_offset:
	db $00,$02,$04
interact_offset1:
	db $FA,$FC,$FE
interact_offset2:
	db $FF,$FF,$FF
interact_height:
	db $14,$12,$10
ontop:
	LDA $7D			; \ branch if going up
	BMI nocontact		; / 
	LDA !7FAB28,x		; \
	AND #$80		;  | branch if can't be carried
	BEQ +			; /
	BIT $16			; \ don't carry if not pressing button
	BVC +			; /
	LDA $1470|!Base2	; \
	ORA $187A|!Base2	;  | don't carry if carrying already or riding yoshi
	BNE +			; /
	LDA #$0B		; \ set carried state
	STA !14C8,x		; /
+	LDA $72			; \ use normal solidity if on ground
	BEQ notspinning		; /
	LDA $19			; \ use normal solidity if small
	BEQ notspinning		; /
	LDA !1540,x		; \
	BNE notspinning		; / use normal solidity if ability to spinjump disabled
	LDA !7FAB28,x		; \
	AND #$10		;  | branch if bit not set to allow spinjumping on sprite
	BEQ notspinning		; /
	LDA $140D|!Base2	; \
	BEQ notspinning		; /
	STA !157C,x		; vertical direction = up
	LDA #$1C		; \
	STA !1540,x		; / set timer
	JSR DamageSprite
	LDA #$E0		; \ set y speed
	STA $7D			; /
no_contact2:
	RTS
notspinning:
	LDA #$01		; \ set "standing on surface" flag
	STA $1471|!Base2	; /
	LDA #$10		; \ set y speed
	STA $7D			; /
	LDA !14D4,x		; \
	XBA			;  | 
	LDA !D8,x		;  | 
	REP #$20		;  | 
	CLC			;  | force mario above sprite
	ADC #$FFE0		;  | 
	LDY $187A|!Base2	;  | \
	BEQ +			;  |  | factor in yoshi
	ADC #$FFEE		;  | /
+	ADC $02			;  | 
	STA $96			;  | 
	SEP #$20		; /
	RTS			; 
hitbottom:
	SEP #$20		; 
	LDA $7D			; \ branch if going down
	BPL no_contact2		;/
	STZ $7D			; nullify speed
	STZ !157C,x		; vertical direction = up
DamageSprite:
	LDA #$01		; \ play sound
	STA $1DF9|!Base2	; /
	LDA !163E,x		; \ branch if timer set
	BEQ +			;  | 
	RTS			; /
+	LDA #$09		; \ set timer
	STA !163E,x		; /
DamageSprites:
	LDA #$18		; \ quake timer
	STA $1887|!Base2	; /
	LDA $77			; \
	AND #$04		;  | branch if mario is in the air
	BEQ +			; /
	LDA #$B0		; \ set mario speed
	STA $7D			; /
; +	LDY #$0B		; load times to loop
 +	LDY #$15		; load times to loop
-	STX $00			; store current sprite index
	PHX			; 
	TYX			; 
	CPX $00			; \ if sprite being processed is this one, skip it
	BEQ .loop		; /
	LDA !1588,x		; \
	AND #$04		;  | skip all sprites in the air
	BEQ .loop		; /
	LDA !14C8,x		; \
	CMP #$08		;  | skip all killed sprites
	BCC .loop		; /
	PHY			; 
	JSR .damagesprite
	PLY			; 
.loop	PLX			; 
	DEY			; \ loop
	BPL -			; / 
	LDA #$09		; \ play sound
	STA $1DFC|!Base2	; / 
	RTS			; 
.damagesprite
	LDY #$02		; load types of sprites to loop from whitelist
-	PHY			; 
	JSR +			; 
	PLY			; 
	DEY			; \ loop
	BPL -			; /
	RTS			; 
+	TYA			; \
	STA $00			;  | 
	ASL			;  | create index for Y
	CLC			;  | 
	ADC $00			;  | 
	TAY			; /
	LDA SpriteTable+$01,y	; \ branch if sprite is stated to be normal
	BEQ .normalsprite	; /
	LDA !7FAB10,x		; \
	AND #$08		;  | deal default damage if sprite checked doesn't match this criteria
	BEQ .defaultdamage	; /
	LDA !7FAB9E,x		; \
	CMP SpriteTable,y	;  | deal default damage if sprite checked does not match
	BNE .defaultdamage	; /
	BRA +			; branch to pointer
.normalsprite
	LDA !9E,x		; \
	CMP SpriteTable,y	;  | branch if current sprite matches whitelisted sprite
	BEQ +			; /
.defaultdamage
	LDA #$00		; \ set default damage type
	BRA ++			; /
+	LDA SpriteTable+$02,y	; \ load sprite damage type table
++	JSL $0086DF|!BankB	; /
	dw DefaultDamage	; $00	= references the original "cape smash"/"hit sprite with block" routine.
	dw DamageType1		; $01	= standard Mario Bros enemy; Spiny, Side Stepper, and Fighter Fly.
;; BOOKMARK1; add more damage type pointer entries here; actual code each entry points to should be placed below.

;; default damage; reference original code
DefaultDamage:
	LDA !166E,x		; \ don't stun if it is immune.
	AND #$20		; /
	ORA !15D0,x		; don't stun if being eaten
	ORA !154C,x		; don't stun if not interacting with mario
	BNE .return		; 
	PHK			; \
	PEA.w .sprsmash-1	;  | JSL2RTS; uses the original code.
	PEA.w $02B889-1|!BankB	;  | 
	JML $029404|!BankB	; /
.sprsmash
	LDY #$08		; \
	LDA !157C,x		;  | 
	BEQ +			;  | set x speed based on direction
	LDY #$F8		;  | 
+	STY !B6,x		; /
.return	RTS			; 

;; Mario Bros-type enemy damage; mark sprite as being damaged
DamageType1:
	LDA !1FD6,x		; \
	ORA #$80		;  | set "damaged" flag.
	STA !1FD6,x		; / the "Mario Bros" sprites will know what to make of this, and take damage.
	LDA #$E0		; \ set y speed
	STA !AA,x		; /
	RTS			; 

SubGfx:
	%GetDrawInfo()

	LDA !15F6,x		;get palette/properties from CFG
	AND #$01		;mask GFX page bit, and clear all others
	STA $06			;store to scratch RAM.

	LDA #$F0		; \ hide oam tile behind sprite when carriable
	STA $0309|!Base2,y	; /

	LDA !163E,x		; \
	PHX			;  | 
	TAX			;  | set offset based on timer
	LDA .yoffset2,x		;  | 
	STA $03			; /
	PLX			; 

	LDA !157C,x		; \
	STA $04			; /

	STZ $05
	LDA !1510,x
	BEQ +
	LDA !151C,x
	STA $05
+
	LDA !151C,x		; \
	CMP #$03		;  | 
	BCC +			;  | manage frame information
	LDA #$02		;  | 
+	STA $02			; /
	LSR			; \
	PHX			;  | use above stuff to load tiles to draw
	TAX			; /
-	LDA $00			; \
	CLC			;  | x offset
	ADC .xoffset,x		;  | 
	STA $0300|!Base2,y	; /

	PHX			; 
	LDA $02			; \  \ index base y offset by state
	TAX			;  | / 
	LDA $03			;  | \ load "animated" y offset
	PHX			;  |  | 
	LDX $04			;  |  | \
	BEQ +			;  |  |  | flip it around if it should push downwards
	EOR #$FF		;  |  |  | 
	INC			;  |  | /
+	PLX			;  | /
	CLC			;  | setup y offset
	ADC .yoffset,x		;  | 
	ADC $01			;  | 
	LDX $05			;  | 
	ADC .yoffset3,x		;  | 
	DEC			;  | 
	STA $0301|!Base2,y	; /
	PLX			; 

	LDA #$06		; \
	ORA $06			;  | 
	ORA $64			;  | 
	STA $0303|!Base2,y	; /

	PHX			; \
	TXA			;  | 
	CLC			;  | create index for tilemap
	ADC $02			;  | 
	TAX			; /

	LDA .tilemap,x		; \
	STA $0302|!Base2,y	; /

	PHY			; 
	TYA			; 
	LSR #2			; 
	TAY			; 
	LDA $02			; \
	EOR #$02		;  | 
	LSR			;  | set up tilesize
	ASL			;  | 
	STA $0460|!Base2,y	; /
	PLY			; 
	PLX			; 

	INY : INY : INY : INY
	DEX
	BPL -
	PLX

	LDY #$FF		; 
	LDA !151C,x		; \
	CMP #$03		;  | 
	BCC +			;  | TODO: find out why i did this
	LDA #$00		;  | 
+	LSR			; /
	JSL $01B7B3|!BankB	; 
	RTS
.tilemap
	db $C4,$C6	; 1 16x16
	db $C8,$C9	; 2 8x8
	; db $88,$8A	; 1 16x16
	; db $8C,$8D	; 2 8x8

.tilesize
	db $02,$02,$00

.xoffset
	db $00,$08

.yoffset
	db $00,$00,$04

.yoffset2
	db $00,$FE,$FC,$FA,$F9,$F8,$F9,$FA,$FC,$FE

.yoffset3
	db $00,$02,$04

SubSmoke:
	LDA #$01		; \ load times to run code
	STA $00			; /
--	LDY #$07		; load times to loop
-	LDA $170B|!Base2,y	; \ branch if not free slot
	BNE +			; /
	JSR .spawnsmoke		; spawn smoke
	BRA ++			; done searching
+	DEY			; \ loop if not a free slot
	BPL -			; /
++	DEC $00			; \
	LDA $00			;  | loop once more
	BPL --			; /
	RTS			; 
.spawnsmoke
	LDA #$0F		; \ extended sprite number
	STA $170B|!Base2,y	; /

	LDA !14D4,x		; \
	XBA			;  | 
	LDA !D8,x		;  | 
	REP #$20		;  | 
	CLC			;  | y position from sprite
	ADC #$0008		;  | 
	SEP #$20		;  | 
	STA $1715|!Base2,y	;  | 
	XBA			;  | 
	STA $1729|!Base2,y	; /

	LDA !E4,x		; \
	STA $171F|!Base2,y	;  | x position from sprite
	LDA !14E0,x		;  | 
	STA $1733|!Base2,y	; /

	PHX			; \
	LDX $00			;  | 
	LDA .xspd,x		;  | set x speed
	PLX			;  | 
	STA $1747|!Base2,y	; /
	LDA #$10		; \ set timer to live
	STA $176F|!Base2,y	; /
	RTS			; 
.xspd	db $18,$E8