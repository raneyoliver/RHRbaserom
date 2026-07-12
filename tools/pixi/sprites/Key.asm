!LuigiHeldItemIndex = $41B82E
!LuigiSpriteNumber = $14
!LuigiIndex = $41A01A

if read1($00FFD5) == $23
	!sprite_slots					= $16
else		
	!sprite_slots					= $0C
endif

;Key
;This is a disassembly of sprite 80 in SMW - Key.
;By RussianMan.
;Requested by Hamtaro126.

!CarriedState_UpThrowSpeed = $90

!GFX_KeyTile = $EC				;tile to display

!Sound_BlockHitSnd = $01			;if you ever wanted to change block hit sound
!Sound_BlockHitAddr = $1DF9|!addr		

;Tables

;used to push the player out when they run into the key
PushXValues:
dw $0001,$FFFF

Carriable_GroundBounceYSpeeds:
db $00,$00,$00,$F8,$F8,$F8,$F8,$F8
db $F8,$F7,$F6,$F5,$F4,$F3,$F2,$E8
db $E8,$E8,$E8

;x-offset when the player drops the sprite (left, right)
CarriedState_DropXDisp:
db $F3,$0D

;high byte for above (left, right)
CarriedState_DropXDispHi:
db $FF,$00

;small x-speed for dropped sprite depending on the player's facing (left, right)
CarriedState_DropXSpeed:
db -$04,$04

CarriedState_KickXSpeed:
db -$2E,$2E
;db -$34,$34					;these values are for when the sprite is kicked while the player is mounted on yoshi, which is normally impossible

CarriedState_XDisp:
db $0B,$F5,$04,$FC,$04,$00

CarriedState_XDispHi:
db $00,$FF,$00,$FF,$00,$00

!CarriedState_YDispForSmallOrDucking = $0F
!CarriedState_YDispForBig = $0D
!CarriedState_YDispForStartedCarrying = $0F	;this is for when the player displays picking up animation

!CarriedState_YDispHi = $00			;note that this is shared for all three above, you'll need additional code for different high byte values

;some common defines
!SpriteRAM_VerticalSpeed = !AA,x
!SpriteRAM_HorizontalSpeed = !B6,x

!SpriteRAM_SpriteXPositionLow = !E4,x
!SpriteRAM_SpriteXPositionHigh = !14E0,X

!SpriteRAM_SpriteYPositionLow = !D8,x
!SpriteRAM_SpriteYPositionHigh = !14D4,X

!SpriteRAM_SpriteState = !14C8,x
!SpriteRAM_PlayerIntDisableTimer = !154C,x	;int = interaction
!SpriteRAM_FaceDirection = !157C,x
!SpriteRAM_BlockedStatus = !1588,x
!SpriteRAM_HorzOffscreenFlag = !15A0,x
!SpriteRAM_SlopeStatus = !15B8,x
!SpriteRAM_OAMIndex = !15EA,x
!SpriteRAM_GraphicalProps = !15F6,x
!SpriteRAM_ConsecutiveKills = !1626,x

!SpriteRAM_VertOffscreenFlag = !186C,x

;this sprite's specific tables
!SpriteRAM_Misc_TimerCopy = !C2,x		;a copy of misc_timer.
!SpriteRAM_Misc_CaughtByBlueKoopaFlag = !1528,x	;pretty self-explanatory, when caught by blue kooper, this is set
!SpriteRAM_Misc_Timer = !1540,x			;used as existence (stun) timer, when it hits 1, it'll disappear in a puff of smoke.

!SpriteRAM_Misc_Timer1FE2 = !1FE2,x		;can be used for various purposes, but commonly used to disable water splashes, interaction with quake sprites, cape spins, cape smashing and net punches
						;couldnt come up with a good name, srry

Print "INIT ",pc
LDA #$09					;sprite status = carryable
STA !SpriteRAM_SpriteState			;
RTL						;

;I decided to not include normal state code (08), which acts as flying red coin/1-up or p-baloon. the key can't have normal state without glitches in vanilla SMW. I already released a standalone flying key, and I think it works better that way.

Print "CARRIABLE",pc
PHB
PHK
PLB
JSR Key
PLB
RTL

;kicked key
Print "KICKED",pc
PHB
PHK
PLB
JSR Key_Kicked
PLB
RTL

;carried by the player key
Print "CARRIED",pc
PHB
PHK
PLB
JSR Key_Carried
PLB
RTL

;----------------------------------------------------------------
;!CARRIABLE STATE

Key:
LDA $9D						;freeze flag
BEQ .RunMain					;
JMP .GFXStuff					;do graphics only (technically)

.RunMain
;JSR HandleStun					;useless, handles stun that causes glitches


LDA !LuigiHeldItemIndex
CMP #$FF
BEQ .updateSpritePosition
TXA
CMP !LuigiHeldItemIndex
BEQ .dontUpdateSpritePosition   ; this sprite is held by Luigi — Luigi sets pos

.updateSpritePosition
JSL $01802A|!bank				;update sprite's position (X+Y with gravity)

.dontUpdateSpritePosition
LDA !SpriteRAM_BlockedStatus			;check if grounded
AND #$04					;
BEQ .NotGrounded				;

JSR HandleGroundBounce				;

.NotGrounded

LDA !SpriteRAM_BlockedStatus			;check ceiling collision
AND #$08					;
BEQ .NoCeiling					;

LDA #$10					;
STA !SpriteRAM_VerticalSpeed			;

LDA !SpriteRAM_BlockedStatus			;if interacted with a wall, don't process block activation
AND #$03					;
BNE .NoCeiling					;

LDA !SpriteRAM_SpriteXPositionLow		;center interaction point
CLC : ADC #$08					;
STA $9A						;

LDA !SpriteRAM_SpriteXPositionHigh		;
ADC #$00					;
STA $9B						;

LDA !SpriteRAM_SpriteYPositionLow		;
AND #$F0					;
STA $98						;

LDA !SpriteRAM_SpriteYPositionHigh		;
STA $99						;

LDA !SpriteRAM_BlockedStatus			;see if hit layer 2 block from below
AND #$20					;
ASL #3						;
ROL						;
AND #$01					;
STA $1933|!addr					;layer 1 or layer 2 the sprite interacted with

LDY #$00					;
LDA $1868|!addr					;
JSL $00F160|!bank				;

LDA #$08					;
STA !SpriteRAM_Misc_Timer1FE2			;diable water splash when hitting a block (when underwater)?

.NoCeiling
LDA !SpriteRAM_BlockedStatus			;if didn't interact with a wall, don't activate any blocks
AND #$03					;
BEQ .NoWall					;

JSR SideBlockInteraction			;interact with blocks to the side

LDA !SpriteRAM_HorizontalSpeed			;slow down bounce away speed
ASL						;
PHP						;
ROR !SpriteRAM_HorizontalSpeed			;
PLP						;
ROR !SpriteRAM_HorizontalSpeed			;

.NoWall
JSR PlayerInteraction				;interact with player (also sprites but it's default interaction)

.GFXStuff
LDA #$00					;
%SubOffScreen()					;disappear offscreen

HandleKeyFacingAndGFX:
LDA !SpriteRAM_SpriteState			;check if in carried state
CMP #$0B					;
BNE .NoFaceWithPlayer				;

LDA $76						;face with the player
EOR #$01					;
STA !SpriteRAM_FaceDirection			;(since the graphics are flipped by default, we need to correct that)

.NoFaceWithPlayer
JSR KeyGFX

;originally called a generic GFX routine and changed sprite tile after. we don't do that obviously.
;LDA #!GFX_KeyTile
;LDY !SpriteRAM_OAMIndex
;STA $0302|!addr,y
RTS						;

;----------------------------------------------------------------
;!KICKED STATE

Key_Kicked:
;LDA !187B,x					;
;BEQ .NotDisco					;this is only used for shells to indicate they're disco as far as I'm aware

;...

.NotDisco
;LDA !167A,x					;can be kicked like a shell
;AND #$10					;key can't be kicked like shell
;BEQ .KickedLikeShell

.KickedLikeShell

;Is not kicked like a shell, just turn into a carriable state
;JSR TurnCarriable

;since I don't think timer stuff matters as well as sprite checks, it amounts to just two lines.
LDA #$09					;become carriable
STA !SpriteRAM_SpriteState			;

JSR HandleKeyFacingAndGFX			;still display GFX
RTS						;

;----------------------------------------------------------------
;!CARRIED STATE

Key_Carried:
JSR HandleCarriedState				;be carried (or not, I don't care)

LDA $13DD|!addr					;if turning around
ORA $1419|!addr					;or entering a pipe
BNE .Center					;sprite appear at the player's position and in front of them

LDA $1499|!addr					;another turning check in case previous test fails (turning timer)
BEQ .NoCenter					;

.Center
STZ !SpriteRAM_OAMIndex				;this resets OAM slot, which makes the sprite go above player

.NoCenter
LDA $64						;
PHA						;
LDA $1419|!addr					;if not entering a pipe
BEQ .NotLowPriority				;normal priority

LDA #$10					;
STA $64						;go below foreground

.NotLowPriority
JSR HandleKeyFacingAndGFX			;show GFX

PLA						;
STA $64						;restore priority
RTS						;

HandleCarriedState:
JSL $019138|!bank				;block interaction.

;LDA $71					;
;CMP #$01					;
;BCC .Carrying					;

LDA $71						;if animating in any way, nor carrying
BEQ .Carrying					;

LDA $1419|!addr					;"How Yoshi should go inside a pipe." uhh, yeah, that also counts for something.
BNE .Carrying					;

LDA #$09					;become carriable
STA !SpriteRAM_SpriteState			;
RTS						;

.Carrying
;LDA !SpriteRAM_SpriteState			;checks if in normal state (unstunning while being carried e.g. galoomba)
;CMP #$08					;key ain't galoomba
;BEQ .Re					;

LDA $9D						;
BEQ .Continue					;
JMP PositionCarriedAtPlayer			;

.Continue
;JSR HandleStun					;don't ever unstun key or anything like that

JSL $018032|!bank				;interact with sprites

LDA $1419|!addr					;"How Yoshi should go inside a pipe." again. did they want the player to be able to carry an item while mounted? or am I missing something
BNE .PlaceAtPlayer				;

BIT $15						;if let go of X/Y
BVC .Drop					;drop carried sprite

.PlaceAtPlayer
JSR PositionCarriedAtPlayer			;

.Re
RTS						;

.Drop
STZ !SpriteRAM_ConsecutiveKills			;reset kill count by this sprite

;check galoomba. yawn

STZ !SpriteRAM_VerticalSpeed			;zero speed for not galoombas

LDA #$09					;become carriable
STA !SpriteRAM_SpriteState			;

LDA $15						;if holding up, throw up
AND #$08					;
BNE .ThrowUp					;

LDA $15						;if holding left or right, player is throwing the sprite left/right
AND #$03					;
BNE .Throw					;

;drop carriable
LDY $76						;player's direction
LDA $D1						;player x-pos, current frame
CLC : ADC CarriedState_DropXDisp,y		;
STA !SpriteRAM_SpriteXPositionLow		;

LDA $D2
ADC CarriedState_DropXDispHi,y
STA !SpriteRAM_SpriteXPositionHigh

%SubHorzPos()

LDA CarriedState_DropXSpeed,y			;base drop speed
CLC : ADC $7B					;+ player's x-speed
STA !SpriteRAM_HorizontalSpeed

STZ !SpriteRAM_VerticalSpeed			;nullify y-speed
BRA .EndKickOrDrop

.ThrowUp
JSL $01AB6F|!bank				;kick visual and audio effect

LDA #!CarriedState_UpThrowSpeed			;
STA !SpriteRAM_VerticalSpeed			;

LDA $7B						;give vertically kicked sprite player's x speed
STA !SpriteRAM_HorizontalSpeed			;
ASL						;
ROR !SpriteRAM_HorizontalSpeed			;then half it
BRA .EndKickOrDrop				;

.Throw
JSL $01AB6F|!bank				;kick visual and audio effect

LDA !SpriteRAM_Misc_Timer			;copy timer value, but why?
STA !SpriteRAM_Misc_TimerCopy			;

LDA #$0A					;turn into kicked
STA !SpriteRAM_SpriteState			;

LDY $76
;LDA $187A|!addr				;this checks if the player is riding a yoshi, so kicking when mounted, which isn't possible without glitches
;BEQ .NotRiding					;I mean... ok? if you want to restore that, uncomment these lines, but I feel this is kinda worthless
;INY #2

.NotRiding
LDA CarriedState_KickXSpeed,y			;base speed
STA !SpriteRAM_HorizontalSpeed			;
EOR $7B						;player's speed would influence kicked speed, unless horizontal speed doesnt match facing direction (like moving right, while facing left)
BMI .EndKickOrDrop				;

LDA $7B						;half of player's speed
STA $00						;
ASL $00						;
ROR						;
CLC						;
ADC CarriedState_KickXSpeed,y			;+base kick speed
STA !SpriteRAM_HorizontalSpeed			;resulting speed

.EndKickOrDrop
LDA #$10					;
STA !SpriteRAM_PlayerIntDisableTimer		;don't interact with the player for a little bit (would be odd if the sprite immediately damaged the player after kicking)

LDA #$0C					;
STA $149A|!addr					;player's kicking pose
RTS						;

PositionCarriedAtPlayer:
LDY #$00					;
LDA $76						;
BNE .FacingLeft					;if the player is facing left, the sprite will be positioned to the left

INY						;

.FacingLeft
LDA $1499|!addr					;player facing screen timer (turning/vertical pipe entrance)
BEQ .NotTurning					;
INY #2						;
CMP #$05					;at the end of turning, the sprite is placed to the side only slightly
BCC .NotTurning					;

INY						;

.NotTurning
LDA $1419|!addr					;how yoshi should go inside a pipe. wait, what???
BEQ .YoshiNotEnteringPipe
CMP #$02					;check if entering vertical pipe
BEQ .Center					;center at the player

.YoshiNotEnteringPipe
LDA $13DD|!addr					;turning player check
ORA $74						;climbing
BEQ .NotCenter

.Center
LDY #$05					;

.NotCenter
PHY						;
LDY #$00					;
LDA $1471|!addr					;check if the player is standing on a brown rotating platform
CMP #$03					;
BEQ .NextFramePos				;

LDY #$3D					;this will use player's current frame position for carried sprite offset

.NextFramePos
LDA $94,y					;y-pos
STA $00						;

LDA $95,y					;y-pos high
STA $01						;

LDA $96,y					;x-pos
STA $02						;

LDA $97,y					;x-pos high
STA $03						;
PLY						;

LDA $00						;
CLC : ADC CarriedState_XDisp,y			;
STA !SpriteRAM_SpriteXPositionLow		;X-position for carried sprite

LDA $01						;
ADC CarriedState_XDispHi,y			;
STA !SpriteRAM_SpriteXPositionHigh		;and high byte

LDA #!CarriedState_YDispForBig			;y-disposition for when big and not ducking
LDY $73						;
BNE .Ducking					;duck flag

LDY $19						;player power-up check (small or big)
BNE .Big					;

.Ducking
LDA #!CarriedState_YDispForSmallOrDucking	;

.Big
LDY $1498|!addr					;if the player just picked up this sprite
BEQ .YOffset					;

LDA #!CarriedState_YDispForStartedCarrying	;

.YOffset
CLC : ADC $02					;
STA !SpriteRAM_SpriteYPositionLow		;

LDA $03						;
ADC #!CarriedState_YDispHi			;
STA !SpriteRAM_SpriteYPositionHigh		;

LDA #$01					;set player to carrying an item state
STA $148F|!addr					;
STA $1470|!addr					;
RTS						;

;----------------------------------------------------------------
;Subroutines:

SideBlockInteraction:
LDA #!Sound_BlockHitSnd				;hit block sound
STA !Sound_BlockHitAddr				;

;JSR ChangeMoveDirection			;split from JSR into below

LDA !SpriteRAM_HorizontalSpeed			;invert speed
EOR #$FF					;
INC						;
STA !SpriteRAM_HorizontalSpeed			;

LDA !SpriteRAM_FaceDirection			;change face direction
EOR #$01					;
STA !SpriteRAM_FaceDirection			;

LDA !SpriteRAM_HorzOffscreenFlag		;if offscreen horizontally, don't activate any blocks
BNE .DontActivateBlock				;

LDA !SpriteRAM_SpriteXPositionLow		;
SEC : SBC $1A					;
CLC : ADC #$14					;
CMP #$1C					;
BCC .DontActivateBlock				;if the block is offscreen, don't activate a block

LDA !SpriteRAM_BlockedStatus			;see if hit layer 2 block from the side
AND #$40					;
ASL #2						;
ROL						;
AND #$01					;
STA $1933|!addr					;layer 1 or 2 flag

LDY #$00					;
LDA $18A7|!addr					;map 16 to check and probably activate
JSL $00F160|!bank				;

LDA #$05					;disable splashes?
STA !SpriteRAM_Misc_Timer1FE2			;

.DontActivateBlock
;checks for throw block, which this sprite isn't, so it doesn't gets destroyed
RTS

;NOT USED
;TurnCarriable:
;LDA !SpriteRAM_Misc_TimerCopy			;timer copy that would reset it's timer...??? not needed
;BNE .StunBackAndTurnCarriable

;STZ !SpriteRAM_Misc_Timer			;

.StunBackAndTurnCarriable
;LDA #!Thrown_SlowDownTimer			;probably not really slowdown timer but it doesnt matter

;LDY !9E,x
;checks for sprite number, bob-omb, galoomba, buzzy beetle and mechakoopa.
;BNE .ShortTime

;LDA #$FF					;longer stun timer

.ShortTime
;STA !SpriteRAM_Misc_Timer			;I don't think this matters for the key...

;LDA #$09					;become carriable
;STA !SpriteRAM_SpriteState			;
;RTS						;

HandleGroundBounce:
LDA !SpriteRAM_HorizontalSpeed			;
PHP						;
BPL .SkipInvertion				;

EOR #$FF					;
INC						;

.SkipInvertion
LSR						;
PLP						;
BPL .SkipInvertionx2				;

EOR #$FF					;
INC						;

.SkipInvertionx2
STA !SpriteRAM_HorizontalSpeed			;

LDA !SpriteRAM_VerticalSpeed			;
PHA						;

LDA !SpriteRAM_BlockedStatus			;check for layer 2
BMI .Speed2					;

LDA #$00					;
LDY !SpriteRAM_SlopeStatus			;
BEQ .Store					;

.Speed2
LDA #$18					;layer 2 or sloped y-speed

.Store
STA !SpriteRAM_VerticalSpeed			;

PLA						;
LSR #2						;
TAY						;

;LDA !9E,x					;check for goomba
;CMP #$0F					;we're certainly 100% not goomba, so we don't care
;BNE .NotGoomba

;...

.NotGoomba
LDA Carriable_GroundBounceYSpeeds,y		;
LDY !SpriteRAM_BlockedStatus			;if landed on layer 2 FG, don't bounce
BMI .Re						;
STA !SpriteRAM_VerticalSpeed			;

.Re
RTS						;

PlayerInteraction:
LDA !SpriteRAM_PlayerIntDisableTimer		;interaction disable
BNE .Re						;

JSL $01803A|!bank				;interact with sprites and player
BCC .Re						;

LDA !LuigiHeldItemIndex	; if key carried by Luigi, cannot carry
CMP #$FF
BNE .NoCarry

;code from $01AA58
LDA $15						;
AND #$40					;hold X/Y button to carry the sprite
BEQ .NoCarry					;

LDA $1470|!addr					;already holding something?
ORA $187A|!addr					;can't hold deez
BNE .NoCarry					;

LDA #$0B					;the key is being held
STA !SpriteRAM_SpriteState			;

INC $1470|!addr					;mario now carries somthing

LDA #$08					;
STA $1498|!addr					;picking up animation timer

.Re
RTS						;

.NoCarry
;STZ !SpriteRAM_PlayerIntDisableTimer		;always contacts the player (it's already 0...)

LDA !SpriteRAM_SpriteYPositionLow		;
SEC : SBC $D3					;
CLC : ADC #$08					;check player's y-position relative to the sprite
CMP #$20					;
BCC .SolidSides					;body on the same level, check for sides
BPL .OnTop					;body above - on top of it

LDA #$10					;below sprite - downward speed
STA $7D						;(doesn't work when the player is small because the y-pos check isn't adjusted to account for a different hitbox - will act as if they're touching a side)
RTS						;

.OnTop
LDA $7D						;if jumped up
BMI .Re						;don't stick to it

STZ $7D						;mario has no y-speed
STZ $72						;grounded

INC $1471|!addr					;the player is on a solid sprite

LDA #$1F					;y-disp when on top of the key (not on yoshi)
LDY $187A|!addr					;
BEQ .YDisp					;

LDA #$2F					;y-disp when on yoshi

.YDisp
STA $00						;

LDA !SpriteRAM_SpriteYPositionLow		;
SEC : SBC $00					;place mario above the sprite
STA $96						;

LDA !SpriteRAM_SpriteYPositionHigh		;
SBC #$00					;high byte
STA $97						;
RTS						;

.SolidSides
PHX
LDA !LuigiHeldItemIndex ; if key not carried by Luigi, normal key interaction
CMP #$FF
BEQ .normal

JSR GetLuigiSpriteIndex
LDA $00
CMP #$FF
BEQ .normal   ; if no Luigi, normal key interaction

; Luigi found
TAX
LDA !14C8,x
CMP #$0B
BNE .normal   ; if Luigi not carried, normal key interaction

; Luigi carried,
PLX
BRA .return ; key should not affect player in this case

.normal
PLX
STZ $7B						;stop player from moving

%SubHorzPos()					;get which side the player's at
TYA						;
ASL						;
TAY						;
REP #$20					;
LDA $94						;
CLC : ADC PushXValues,y				;push the player to be outside the key
STA $94						;
SEP #$20					;

.return
RTS						;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;Graphics routine
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!OAM_XPos = $0300|!addr
!OAM_YPos = $0301|!addr
!OAM_Tile = $0302|!addr
!OAM_Prop = $0303|!addr

KeyGFX:
PHX
LDA !LuigiIndex
TAX
LDA !1504,x ; get Luigi's state to see if teleporting
STA $00
PLX
LDA $00
BNE .return ; if so, don't draw

%GetDrawInfo()					;about to draw...
LDA #!GFX_KeyTile				;
STA $0302|!Base2,y				;

LDA $00						;x pos
STA !OAM_XPos,y					;

LDA $01						;y pos
STA !OAM_YPos,y					;

LDA !SpriteRAM_FaceDirection			;flip depending on face dir
LSR						;
LDA #$00					;
ORA !SpriteRAM_GraphicalProps			;
BCS .FacingRight				;

ORA #$40					;x-flip

.FacingRight
ORA $64						;
STA !OAM_Prop,y					;

LDA #$00					;1 tile
LDY #$02					;16x16
; %FinishOAMWrite()				;
JSL $01B7B3|!BankB
.return
RTS						;

GetLuigiSpriteIndex:
	PHX
    PHY
	LDY #!sprite_slots-1		;loop count (loop though all sprite number slots)

.Loop
	TYX					;transfer Y to X
	LDA !7FAB9E,x		;load sprite number according to index
	CMP #!LuigiSpriteNumber 			;compare with Luigi index
	BNE .LoopSprSpr 	;if Luigi, next

.okay
	STX $00	; if found Luigi
    BRA .return

.LoopSprSpr
	DEY			;decrement loop count by one
	BPL .Loop		;and loop while not negative.

.notFound
	LDA #$FF		; if no Luigi found, return FF
	STA $00

.return
    PLY
    PLX
	RTS			;end? return.
