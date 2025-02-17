;;;;;;;;; GENERAL PROPERTIES ;;;;;;;;;

!distL							= $0010	; distance to check offscreen on the left (0040 = 4 16x16 tiles)
!distR							= $0010	; distance to check offscreen on the right

!StationaryCarryable			= #$09

!Frame                  		= !1570,x
!SolidContactOccurred   		= !187B,x

!StartRAM						= $7FB900		; FreeRAM start address to backup the sprites.

!FreezeMiscTables				= 0		; If set, the miscellaneous sprite tables which control various sprite behaviours will also be frozen.
							; This can prevent jank with certain sprites and enables freezing for sprites not controlled by their X/Y speeds and positions.
							; However, it uses a lot more freeRAM than if disabled (see below). It also isn't guaranteed to behave nicely with custom sprites.

!sprite_slots					= $0C							
!MarioSpriteNumber				= $14	; in pixi_list.txt
!KoopaShellTeleports			= $12	; in pixi_list.txt
!SpinyShell						= $5B	; in pixi_list.txt

;;;;;;;;; PLAYER PROPERTIES ;;;;;;;;;

; Position
!PlayerPosXLow					= $7FA007
!PlayerPosXHigh					= $7FA008
!PlayerPosYLow					= $7FA025 ;7FA00B was used in MarioGFXAndPaletteChangeOnTrigger.asm
!PlayerPosYHigh					= !1534,x

; Speed
!PlayerSpeedX					= $7FA009
!PlayerSpeedY					= $7FA00A

; Mario-Luigi Changing
!IsMario                                        = $7FA026

;;;;;;;;; MarioSprite PROPERTIES ;;;;;;;;;

!State							= !1504,x

!Spinning						= $7FA00C
!CloneSpeedX					= $7FA00E
!CloneSpeedY					= $7FA00F
!TeleportReady					= $7FA016
!JumpHeld						= $7FA018
!TempSpinning					= $7FA019
!SpinDirection					= $7FA01E
!StareTimer						= $7FA020
!Frozen							= $7FA021
!FreezeBlockFrozenFlag			= $7FA022       ; from uberASM/level/FreezeSpritesOnTrigger.asm
!BouncingSpeed					= $7FA023		; also used as a flag ($01=delay bounce $00=okay to bounce)
!PlayerOnlyStomped         = $7FA024

!TitleScreenLevel				= $C7

!Lvl18XSpeed					= $24
!Lvl1AXSpeed					= $24
!Lvl21XSpeed					= $24
!Lvl21YSpeed					= $AA

!TeleportingSpeed				= $60                 ; Speed the camera/teleport moves
!StopTeleportWithin				= #$0010

!BounceDelay					= $08
!NumPixelsAboveSpriteRequiredToBounce	= $00 ;$02

!NonSpikyLowBounce				= $E6
!NonSpikyHighBounce				= $AA
!NonSpikyLowSpin				= $FE
!NonSpikyHighSpin				= $FC

!SpikyLowSpin					= $D3	;$E2
!SpikyHighSpin					= $AA	; estimated

!StationaryHatTLTile			= $00
!WalkingTopLeftTile     		= $20
!JumpingTopLeftTile     		= $04
!JumpingPSpeedTLTile			= $02
!SpinningForwardTopLeftTile    	= $06
!SpinningBackwardTopLeftTile    = $08
!DeadTopLeftTile        		= $0A
!StareForwardTopLeftTile     	= $0C
!StareBackwardTopLeftTile     	= $0E
!RunningTile					= $2C
!RunningTile2					= $48

;;;;;;;;; OTHER ;;;;;;;;;

!ShellKickXSpeed         		= $2E

;;;;;;;;; MACROS ;;;;;;;;;

macro SetSpriteStatus(status, index)
    LDA <status>
	STA !14C8,<index>
endmacro

macro SprToRAM(addr, offset)
LDA <addr>,x
STA !StartRAM+(!sprite_slots*<offset>),x
endmacro

macro RAMToSpr(addr, offset)
LDA !StartRAM+(!sprite_slots*<offset>),x
STA <addr>,x
endmacro

macro prepare_extra_bytes()
        LDA !extra_byte_1,x                     ; \
        STA $00                                 ;  | load extra byte address to into $00-$02
        LDA !extra_byte_2,x                     ;  | (if there's more than 4 extra bytes, the addresses for 1-3
        STA $01                                 ;  | actually serve as pointers to the real data)
        LDA !extra_byte_3,x                     ;  |
        STA $02                                 ; /
endmacro

macro load_extra_byte(num)
        LDY #<num>-1                            ; \  I'm counting extra bytes from 1 to 12
        LDA [$00],y                             ; /
endmacro

;;;;;;;;; FUNCTIONS ;;;;;;;;;

InitMarioSpriteProperties:

	; Set MarioSprite Stationary/Carryable
	%SetSpriteStatus(!StationaryCarryable, x)

	; Set Properties False
	LDA #$00
	STA !Spinning
	STA !JumpHeld
	STA !StareTimer
	STA !Frozen
	STA !BouncingSpeed
	STA !PlayerOnlyStomped
	STA !IsMario
	STA !1626,x
	
	; Set Properties True
	LDA #$01
	STA !TeleportReady

	; Level-specific
	LDA $7E010B
	CMP #$1A                ; level 1A
	BEQ .lvl1A

	CMP #$21
	BEQ .lvl21

	BRA .return

.lvl1A
	LDA #$01				; level 1A starts spinning with some X speed 
	STA !Spinning

	LDA #!Lvl1AXSpeed
	STA !B6,x

	BRA .return

.lvl21
	LDA #$01
	STA !JumpHeld			; level 21 JumpHeld and slight left X speed

	LDA #!Lvl21XSpeed
	STA !B6,x

	LDA #!Lvl21YSpeed
	STA !AA,x

	BRA .return

.return
	RTS

GivePoints:
	STY $02
	PHY

	; Trigger Custom F to make 1-up green
	LDA !IsMario
	BNE .mario

.luigi
	REP #$20
	LDA $7FC0FC	; custom triggers 0-F bits
	ORA #$8000	; first bit (F)
	STA $7FC0FC	; switch on first bit
	SEP #$20

.mario
    INC !1626,x	        	;|
	JSR RememberPoints
    LDA $1697|!addr        	;\
    ;CLC                    	;|	Don't add SpriteStomped--It should already be added via RememberPoints
    ;ADC !1626,x		       	;|
    TAY                    	;| Play bounce SFX when $1697+$1626,x < #$08
    ;INY                    	;| (if >= @$08, it spawns a 1up score sprite which plays the SFX)
    CPY #$08               	;|
    BCS +                  	;|

    LDA .SFX-1,y            ;|
    STA $1DF9|!addr         ;/
+   TYA                     ;\
    CMP #$08                ;|
    BCC +                   ;| Give points accordingly (input capped to $08 = 1up)

    LDA #$08                ;|
+   JSL $02ACE5|!bank       ;/

	PLY
    RTS

.SFX:
    db $13,$14,$15,$16,$17,$18,$19

print "INIT ",pc

	; temporary
	LDA #$00
	STA !FreezeBlockFrozenFlag

	; Initialize MarioSprite's Properties
    JSR InitMarioSpriteProperties
	JSR UnsetCustomFTrigger

	RTL

UpdateMarioSpriteSpeed:
	LDA !BouncingSpeed
	BEQ .return	; if $00 do nothing

	CMP #!BounceDelay+1
	BCC	.decrement	; else if <= delay, decrement

	;else if > delay, store speed then set to delay
	STA !AA,x	; bounce MarioSprite
	LDA #!BounceDelay
	STA !BouncingSpeed
	BRA .return

.decrement
	LDA !BouncingSpeed
	DEC A
	STA !BouncingSpeed
.return
	RTS

print "MAIN ",pc

	PHB : PHK : PLB : JSR SpriteCode : PLB : RTL : SpriteCode:

    JSR RememberPoints
	JSR UnsetCustomFTrigger

	; If !StareTimer % 4 == 3, MarioSprite uses stare graphics
	JSR UpdateMarioSpriteStareTimer

	; If bouncing previous frame, update MarioSprite speed this frame (one frame delayed)
	; This is to mimick the way mario bounces- using $94 and $96
	JSR UpdateMarioSpriteSpeed

	JSR PerLevelSettings

	LDA $71      ;\ Skip everything and just draw graphics if Mario is dying.
	CMP #$09     ;|
	BEQ .return  ;/

	JSR CheckIfKilled
	LDA $00 ; 01 if killed
	BNE .killPlayer

	LDA $9D
	BNE .noCarry
	JSR HandleCarryableSpriteStuff

.noCarry
	; Teleporting Function
	JSR HandleState

	LDA !State
	BEQ .notTeleporting

.teleporting
	; keep sprites frozen while teleporting (BackupAllSpriteProperties called in HandleState)
	PHX
	JSR FreezeAllSprites
	PLX

.notTeleporting
	LDA $9D
	BNE .return

	JSR Stationary
	BRA .return

.killPlayer
	LDA #!DeadTopLeftTile
	STA !Frame
	JSR Graphics

	JSL $00F606     ;kill mario
	RTS
.return
	LDA !167A,x
	ORA #$04
	STA !167A,x

	JSR Graphics
	RTS

PerLevelSettings:
	LDA $7E010B		; Get current level
	CMP #!TitleScreenLevel
	BNE .return

	; Level AF
	LDA #$30		; 30 X Speed
	STA !B6,x

.return
	RTS

UnsetCustomFTrigger:
	; Unset Custom F Trigger (1-up color: mario-off, luigi-on)
	REP #$20
	LDA $7FC0FC	; custom triggers 0-F bits
	AND #$7FFF	; 0 only first bit
	STA $7FC0FC	; switch off first bit
	SEP #$20
	RTS

RememberPoints:
	;First, set SpriteStomped
	LDA !1588,x             ; Check if sprite is blocked downward (on ground)
	AND #$04                
	BEQ .inAir		     	; If sprite is not on ground (airborne), branch

	STZ !1626,x	

	LDA $72                 ; Check if player is airborne
	BNE .inAir              ; If player is airborne, branch to .inAir

	; At this point, both player and sprite are on the ground
	BRA .updateAndExit      ; Branch to update and exit logic if both are on ground

.inAir
	; If here, either player or sprite is airborne
	LDA $1697|!addr          	; Get number of consecutive enemies stomped
	SBC !1626,x					; Subtract SpriteStomped
	BMI .restore
	CMP !PlayerOnlyStomped     	; Compare to previous frame
	BCS .updateAndExit        	; If >=, branch to update and exit logic

.restore
	; If <, restore the counter and proceed
	LDA !PlayerOnlyStomped     
	CLC : ADC !1626,x
	STA $1697|!addr        		; Restore consecutive enemies count

.updateAndExit
	LDA $1697|!addr            	; Get number of consecutive enemies stomped
	SEC : SBC !1626,x			; isolate player count
	STA !PlayerOnlyStomped     	; Save for next frame
	RTS                      	; Return from subroutine


CheckIfKilled:
        LDA !14C8,x
        BEQ .killPlayer

        CMP #$02
        BEQ .killPlayer

        CMP #$03
        BEQ .killPlayer

        CMP #$04
        BEQ .killPlayer

        CMP #$05
        BEQ .killPlayer

.dontKillPlayer
        LDA #$00
        STA $00
        RTS

.killPlayer
        LDA #$01
        STA $00
        RTS

UpdateMarioSpriteStareTimer:
	LDA !Frame
	CMP #$04        ;was on ground if less	(!WalkingTopLeftTile)
	BCC .marioSpriteOnGround

	CMP #$0C        ;was on ground if more (!StareForwardTopLeftTile or !StareBackwardTopLeftTile)
	BCS .marioSpriteOnGround

	LDA !1588,x     ;just now landing (MarioSprite blocked down)
	AND #$04
	BNE .marioSpriteJustNowLanding

.marioSpriteInAir
	RTS

.marioSpriteJustNowLanding
	LDA #$00
	STA !StareTimer
	RTS

.marioSpriteOnGround
	LDA $14	; if 0-FF counter hits 0, increment StareTimer
	BNE .re

	LDA !StareTimer
	INC A
	STA !StareTimer

.re
	RTS

HandleState:
	LDA !State
	JSL $0086DF|!BankB
	dw .idle, .enteringPipe, .teleporting, .exitingPipe

.idle      
	JSR HandleInteraction
	
	; LDA $18			;  | initiate teleporting if you press R
	; AND #$10		;  | 00010000 -> AXLR---- , so check if R pressed.
	; BNE ..check
	WDM #$01
	LDA $15			;  | initiate teleporting if you press R
	AND #$20		; select
	BNE ..check
	RTS

..check
	; Cancel if sprites frozen
	LDA $9D
	BNE ..cancel

	; Cancel if sprites frozen by FreezeBlock
	LDA !FreezeBlockFrozenFlag
	BNE ..cancel

	BRA ..beginTeleporting

..cancel
	RTS

..beginTeleporting
	;temp delay
	LDA !154C,x
	BNE ..dontTeleportBridge

	LDA $1470|!Base2                        ; \
	ORA $148F|!Base2                        ;  | don't allow teleporting if you're carrying something
	BNE ..dontTeleportBridge                      ; /

	LDA $1426|!Base2                        ; \  don't allow teleporting if a message box is active
	BNE ..dontTeleportBridge                      ; /

	LDA !TeleportReady                      ; \ don't allow teleporting if the sprite is not touched yet
	BEQ ..dontTeleportBridge                      ; /

	LDA $5D                                 ; \
	DEC                                     ;  |
	XBA                                     ;  | don't allow teleporting if the other pipe
	LDA #$F0                                ;  | is beyond the edges of the level
	REP #$20                                ;  |
	STA $00                                 ;  |
	SEP #$20                                ;  |
	LDA !14E0,x                             ;  |
	CMP #$FF

	BEQ ..dontTeleport                      ;  |
	XBA                                     ;  |
	LDA.w !E4,x                             ;  |
	REP #$20                                ;  |
	CMP $00 
	BCS ..dontTeleport                      ;  |
	SEP #$20                                ; /

	LDA $13F9|!Base2                        ; \  don't allow teleporting (and don't even play "wrong" sound)
	BNE .return                             ; /  if you're already teleporting (this can happen when you're standing on two at once)
	BRA ..doTeleport

..dontTeleportBridge
	BRA ..dontTeleport

..doTeleport
	;temp delay
	LDA #$20
	STA !154C,x

	LDA #$01
	STA !Frozen

	LDA #$00
	STA !StareTimer

	JSR SetupAttributesOfClone

	; Backup sprite properties to use in freezing
	PHX
	JSR BackupAllSpriteProperties
	PLX

	LDA #$FF
	STA $9D

	JSR EraseFireballs

	;LDA #$25                                ; \  play blargg roar
	;STA $1DF9|!Base2                        ; / 

	LDY $18DF|!Base2 						
	BEQ ..noYoshi
	DEY
	LDA #$00
	STA !151C,y
	STA !1594,y
	STZ $18AE|!Base2
	STZ $14A3|!Base2
	LDA !160E,y
	BEQ ..noYoshi
	TAY
	LDA #$00
	STA !15D0,y

..noYoshi
	; freeze clone and player, speed is already stored
	STZ !B6,x
	STZ !AA,x
	STZ $7B
	STZ $7D

	INC !State
	RTS

..dontTeleport
	SEP #$20
	LDA $16                                ; \
	AND #$04                               ;  | if you're not allowed to teleport,
	BEQ .return                            ;  | play "wrong" sound once
	LDA #$2A                               ;  |
	STA $1DFC|!Base2                       ; /

.return
        RTS

.enteringPipe
	STZ $73
	LDA #$FF
	STA $9D

	; freeze clone and player, speed is already stored
	STZ !B6,x
	STZ !AA,x
	STZ $7B
	STZ $7D

..nextState
	JSR EraseFireballs

	INC !State
	RTS


.teleporting
	LDA #$01                                ; \
	STA $1404|!Base2                        ;  |
	STA $1406|!Base2                        ;  | all kinds of teleportation settings
	STZ $73                                 ;  |
	LDA #$01                                ;  |
	STA $185C|!Base2                        ;  |
	LDA #$02                                ;  |
	STA $13F9|!Base2                        ;  |
	LDA #$FF                                ;  |
	STA $78                                 ;  |
	STA $9D

	; Auto-Scroll
	LDA $7E010B
	CMP #!TitleScreenLevel
	BNE +

	; If autoscrolling level, just instantly tp the player to the sprite and continue
	LDA.w !E4,x                             ; \low X
	STA $94                                 ;  | fix the player's position to
	LDA !14E0,x                             ;  | right on the sprite                high X
	STA $95                                 ;  |
	LDA.w !D8,x                             ;  |low Y
	SEC : SBC #$0A                          ;  |
	STA $96                                 ;  |
	LDA !14D4,x                             ;  |high Y
	SBC #$00                                ;  |
	STA $97                                 ; /

	INC !State
	RTS

+
	JSR SetTeleportingXSpeed                ; \  move the player to the other pipe
	JSR SetTeleportingYSpeed                ; /

	LDA $7B                                 ; \
	ORA $7D                                 ;  | if the player doesn't need to move anymore
	ORA $17BC|!Base2                        ;  | and the screen has caught up with them too,
	ORA $17BD|!Base2                        ;  | we're done teleporting
	BNE ..keepTeleporting                   ; /

..doneTeleporting
	INC !State

..keepTeleporting
	STZ !B6,x
	STZ !AA,x

	LDA #$FF
	STA $9D

	RTS

.exitingPipe
        JSR FlipMarioLuigi
..nextState
	LDA #$FF
	STA $9D

	LDA.w !E4,x                             ; \low X
	STA $94                                 ;  | fix the player's position to
	LDA !14E0,x                             ;  | right on the sprite                high X
	STA $95                                 ;  |
	LDA.w !D8,x                             ;  |low Y
	SEC : SBC #$0A                          ;  |
	STA $96                                 ;  |
	LDA !14D4,x                             ;  |high Y
	SBC #$00                                ;  |
	STA $97                                 ; /

	;also take sprite's speed
	LDA !CloneSpeedX
	STA $7B

;---------------------
;		ground		|air
;fast	p-speed		|p-speed, fly
;slow		   		|jump

;also give p-speed if the sprite was fast enough
	LDA !CloneSpeedX
	BPL + : EOR #$FF : INC : +
	CMP #$30
	BCC ..slow

..fast
	LDA #$70	; 70 means max p-speed (needed for cape flying)
	STA $13E4|!Base2

	LDA !1588,x
	AND #$04
	BEQ ..inAirFast

..onGroundFast
	BRA ..ySpeed

..inAirFast
	LDA #$0C	; pose for jump fly
	STA $72		; mario jumping poses	
	BRA ..ySpeed

..slow
	LDA !1588,x
	AND #$04
	BEQ ..inAirSlow

..onGroundSlow
	BRA ..ySpeed

..inAirSlow
	LDA #$0B	; pose for jump
	STA $72		; mario jumping poses	

;--------------------
..ySpeed
	LDA !CloneSpeedY
	STA $7D


	;also take sprite's spinning flag
	LDA !TempSpinning
	STA $140D

	LDA !PlayerPosXLow                             ; \
	STA !E4,x                                     ;  | fix the sprite's position to
	LDA !PlayerPosXHigh                           ;  | right on the player's previous
	STA !14E0,x                                   ;  |
	LDA !PlayerPosYLow                            ;  |
	CMP #$EC ;#$F9                               ; don't add so much that it screen wraps
	BCS +
	SEC : ADC #$12 ;#$0F                                ;  |  sprite was too high without this
+
	STA !D8,x                                     ;  |
	LDA !PlayerPosYHigh                           ;  |
	STA !14D4,x                                   ; /

	;also take player's speed
	LDA !PlayerSpeedX
	STA !B6,x
	LDA !PlayerSpeedY
	STA !AA,x

..nonePressed
	STZ $185C|!Base2                        ;  |
	STZ $13F9|!Base2                        ;  | all kinds of teleportation settings
	STZ $1419|!Base2                        ;  |

	;Set state back to idle
	LDA !State       ; Load the value of !State into the accumulator
	SEC              ; Set the carry flag to indicate subtraction
	SBC #$03         ; Subtract 4 from the value in the accumulator
	STA !State       ; Store the result back into !State

	STZ $9D

	LDA #$00
	STA !Frozen

..return
        RTS

FlipMarioLuigi:
        ; Switch mario-luigi
        LDA !IsMario
        EOR #$01
        STA !IsMario
        RTS

SetupAttributesOfClone:
        LDA $D1;$94
        STA !PlayerPosXLow
        LDA $D2;$95
        STA !PlayerPosXHigh
        LDA $D3;$96
        STA !PlayerPosYLow
        LDA $D4;$97
        STA !PlayerPosYHigh

        LDA $7B
        STA !PlayerSpeedX

        LDA $77
        AND #$04
        BNE .removeGravity      ; on ground

.withGravity
        LDA $7D
        STA !PlayerSpeedY
        BRA .continue

.removeGravity
        LDA #$00
        STA !PlayerSpeedY
.continue
        LDA !B6,x
        STA !CloneSpeedX
        LDA !AA,x
        STA !CloneSpeedY

        LDA !Spinning
        STA !TempSpinning         ; store copy of clone's spinning flag for later

        LDA $140D       ; overwrite clone spinning with mario spinning
        STA !Spinning

        LDA #$00
        STA !JumpHeld

        ; jump held if a or b held
        LDA $15
        ;Controller buttons currently held down. Format: byetUDLR.
        ;b = A or B; y = X or Y; e = select; t = Start; U = up; D = down; L = left, R = right.
        AND #$80                                ;  | 10000000 -> AXLR---- , so check if a or b pressed.
        BNE .jumpIsHeld                  ; /        

        BRA +

.jumpIsHeld
        LDA #$01
        STA !JumpHeld
+
        RTS

; determines where to move the player horizontally when teleporting

SetTeleportingXSpeed:

        LDA !14E0,x                             ; \
        XBA                                     ;  | calculate the distance
        LDA.w !E4,x                             ;  | between the player and the sprite
        REP #$20                                ;  |
        SEC : SBC $D1                           ;  |
        STA $00                                 ; /

        BPL + : EOR #$FFFF : INC : +            ; \
        CMP !StopTeleportWithin                              ;  |
        SEP #$20                                ;  | if the distance is less than a tile,
        BCS .notCloseEnough                     ;  | stop moving
.closeEnough                                    ;  | (it doesn't need to be an exact match,
        STZ $7B                                 ;  | the player's position will be set to the exact value later on)
        RTS                                     ;  |
.notCloseEnough                                 ; /

        REP #$20                                ; \
        LDA $00                                 ;  |
        SEP #$20                                ;  | otherwise, move the player left or right
        BMI .negativeSpeed                      ;  | depending on whether the distance is negative or positive
.positiveSpeed                                  ;  |
        LDA #$7F ;#!TeleportingSpeed                  ;  |
        BRA +                                   ;  |
.negativeSpeed                                  ;  |
        LDA #$80                 ;  |
+       STA $7B                                 ;  |
.return                                         ;  |
        RTS                                     ; /




; determines where to move the player vertically when teleporting

SetTeleportingYSpeed:

        LDA !14D4,x
        XBA
        LDA.w !D8,x
        REP #$20
        SEC : SBC $D3
        STA $00

        BPL + : EOR #$FFFF : INC : +
        
        CMP !StopTeleportWithin
        SEP #$20
        BCS .notCloseEnough
.closeEnough
        STZ $7D
        RTS
.notCloseEnough
        REP #$20
        LDA $00
        SEP #$20
        BMI .negativeSpeed
.positiveSpeed
        LDA #$7F ;#!TeleportingSpeed
        BRA +
.negativeSpeed
        LDA #$80 ;#-!TeleportingSpeed
+       STA $7D
.return
        RTS




; erases (player's) fireballs on screen

EraseFireballs:

        LDY #$09
.loop
        LDA !extended_num,y
        CMP #$05
        BNE .continue
        LDA #$00
        STA !extended_num,y
.continue
        DEY
        BPL .loop

        RTS

; extra bit clear: stationary

Stationary:
        JSR CheckIfKilled
        LDA $00
        BEQ .notDead

.dead
        JSR SetFrameDead
        BRA .return

.notDead
		LDA !14C8,x
		CMP #$0B
		BNE .notCarried

.carried
		LDA #!JumpingTopLeftTile
		STA !Frame
		BRA .return

.notCarried
        LDA !1588,x
        AND #$04
        BEQ .jumping	; in air

;         LDA !1588,x                             ; \
;         AND #$03                                ;  | check if against a wall
;         BEQ .walking		                    ; /

; ..againstWall
; 		%prepare_extra_bytes()
;         %load_extra_byte(10)                    ; \
;         AND #$08                                ;  | if set to jump when against a wall, try jumping
;         BNE ..tryJumping                        ; /
        
; 		BRA .walking

; ..tryJumping
;         %load_extra_byte(10)                    ; \
;         AND #$07                                ;  |
;         TAY                                     ;  | jump with the given height
;         LDA .jumpSpeeds,y                      ;  |
;         EOR #$FF : INC                          ;  |
;         STA !AA,x                               ; /
;         %load_extra_byte(9)                     ; \
;         BPL .return                           ;  | play jump sound if set to
;         db $A9 : db read1($00D65F)              ;  |
;         db $8D : dw read2($00D661)              ; /

.walking
        JSR SetFrameWalking
        LDA $72
        BNE .return

        LDA #$00
        STA !Spinning           ; not spinning if on ground
        STA !JumpHeld

        BRA .return

.jumping
		JSR SetFrameJumping
        
.return
        RTS

.jumpSpeeds
        db $20,$30,$3C,$46,$4C,$50,$58,$60      ;    the setting for jump height against a wall has only 8 values
                                                ;    so I picked some reasonable-ish ones

; graphics routine

Graphics:
;         ; set up properties byte
;         LDA !157C,x                             ; \
; +       STA $03

        LDA !Spinning
        BEQ .setXFlipRegular   ;not spinning

.setXFlipSpin
        LDA !SpinDirection
        CMP #$02
        BCS .defaultPalette

        ROR #3
        STA $03

        BRA .defaultPalette
.setXFlipRegular
		LDA $7E010B		; Get current level
		CMP #!TitleScreenLevel	; Always face right on this level (title)
		BNE ..normal

		LDA #$00
		BRA +

..normal
        LDA !157C,x                             ; \
+       AND #$01                                ;  |
        EOR #$01                                ;  | set the x flip bit based on direction
        ROR #3                                  ;  |
		STA $03                                 ; /

.defaultPalette                                 ;  |
        LDA !JumpHeld
        BEQ .jumpNotHeld

.jumpHeld
        JSR DisplaySparkle

.jumpNotHeld
        LDA !IsMario
        BNE .mario

.luigi
        LDA #$0F        ;palette F?
        TSB $03
        BRA .16x32

.mario
        LDA #$0C        ;palette E?
        TSB $03
.16x32

        %GetDrawInfo()

        LDA $00
        STA $0300|!Base2,y
        LDA $01
        SEC : SBC #$10
        STA $0301|!Base2,y
        JSR GetTopTile
        STA $0302|!Base2,y              ; YXPP CCCT
        LDA #$11                        ; 0001 0001
        ORA $03
        STA $0303|!Base2,y

        INY #4

        LDA $00
        STA $0300|!Base2,y
        LDA $01
        STA $0301|!Base2,y
        JSR GetBottomTile
        STA $0302|!Base2,y
        LDA #$11
        ORA $03
        STA $0303|!Base2,y

        LDY #$02
        LDA #$01
        JSL $01B7B3|!BankB

        RTS

GetTopTile:
	JSR SetCarryIfReusingHatTile

	BCS .topTileIsHat

.topTileIsOther
	LDA !Frame	; should already be TL tile
	BRA .return

.topTileIsHat
	LDA #!StationaryHatTLTile

.return
	RTS

GetBottomTile:
	JSR SetCarryIfReusingHatTile

	BCS .topTileIsHat

.topTileIsOther
	LDA !Frame			; should already be TL tile
	CLC : ADC #$20		; go 2 tiles down in GFX
	BRA .return

.topTileIsHat
	LDA !Frame			; should already be bottom tile

.return
	RTS

SetCarryIfReusingHatTile:
	LDA !Frame
	AND #$0F
	CMP #$04
	BCC .reuse

	CMP #$0C
	BCS .reuse

.doNotReuse
	CLC
	BRA .return

.reuse
	SEC

.return
	RTS

CheckHorzOffscreen:
	LDA $14E0,x
	XBA
	LDA $E4,x
	REP #$20
	SEC : SBC $1A
	CLC : ADC #!distL
	CMP #$0100+!distL+!distR
	SEP #$20
	RTS

SetCarryIfShell:	;requires sprite in y
	; check type of sprite found 
	PHX
		TYX
		LDA !7FAB10,x
	PLX

	AND #$08
	BNE .isCustom

	PHX
		TYX
		LDA !7FAB9E,x
	PLX

	CMP #$DA		; DA-DF vanilla shells
	BCC .isNotShell
	CMP #$E0
	BCS .isNotShell

	BRA .isShell

.isCustom
	PHX
		TYX
		LDA !7FAB9E,x ;!9E,x
	PLX
.tpShellCheck
	CMP #!KoopaShellTeleports
	BEQ .isShell	; try bounce if

.spinyShellCheck
	CMP #!SpinyShell
	BNE .isNotShell

.isShell
	SEC
	BRA .return

.isNotShell
	CLC

.return
	RTS

DisplaySparkle:
        JSR CheckHorzOffscreen
        BCC .okay

        RTS

.okay
		LDA $14	; Increments each frame
        JSR GetModuloFourOfA
        CMP #$00
        BEQ .okay2

        RTS

.okay2
        LDY #$0B                ; \ find a free slot to display effect
FindFree:
        LDA $17F0|!Base2,y             ;  |
        BEQ FoundOne            ;  |

        DEY                     ;  |
        BPL FindFree            ;  |

        RTS                     ; / RETURN if no slots open
FoundOne:
        LDA $14
        JSR GetModuloFiveOfA
        STA $00                         ; random offset?

        LDA #$02;#$05                   ; \ set effect graphic to sparkle graphic
        STA $17F0|!Base2,y              ; /
        LDA #$00                        ; \ set time to show sparkle
        STA $1820|!Base2,y              ; /
        LDA !D8,x                       ; \ sparkle y position LOW
        SEC : ADC $00                   ; random offset?
        STA $17FC|!Base2,y              ; /
        LDA !14D4,x                     ; \ sparkle y position HIGH
        STA $1814|!Base2,y              ; /
        LDA !E4,x                       ; \ sparkle x position LOW
        STA $1808|!Base2,y              ; /
        LDA !14E0,x                     ; \ sparkle x position HIGH
        STA $18EA|!Base2,y              ; /
        LDA #$17                        ; \ load generator x position and store it for later
        STA $1850|!Base2,y              ; /
        RTS                     ; RETURN

; routines that set the current animation frame
; (called at various places)

; the format in the extra bytes is "top left corner in SP3/4, aligned to 16x16 tiles"
; (0 is the first 16x16 tile, 1 is the 16x16 tile next to it, and 3F is the very last 16x16 tile.)
; this is so everything fits into 6 bits.
; there's a few bitwise shenanigans going on to convert that to an actual tile number,
; and the conversion is slightly different for each one because they're at different positions within a byte.

; the tile specified is the top one (if the sprite is not 16x16, the other is always one below that).
; the "custom walking frame" setting has two tiles (the second frame is one to the right, or two for 32x32 sprites).

SetFrameDead:
        LDA #!DeadTopLeftTile
        STA !Frame
        RTS

SetFrameWalking:
	
	LDA $7E010B		; Get current level
	CMP #!TitleScreenLevel	; Don't touch X speed if on this level
	BNE .notRunning

.running
	LDA $14
	AND #$01
	BEQ +

	JSR SetFrameRunning
	BRA ++

+	JSR SetFrameRunning2
	BRA ++

.notRunning
	; If StareTimer % 4 == 3, stare
	LDA !StareTimer
	JSR GetModuloFourOfA
	CMP #$03
	BEQ .stare

.walk
        JSR SetFrameWalking1
        BRA ++

.stare
        LDA !157C,x
        BEQ ..right

..left
        LDA !14E0,x                             ; \
        XBA                                     ;  | calculate the distance
        LDA.w !E4,x                             ;  | between the player and the sprite
        REP #$20                                ;  |
        SEC : SBC $D1                           ;  |
        SEP #$20

        BPL ..forward
        BRA ..backward

..right
        LDA !14E0,x                             ; \
        XBA                                     ;  | calculate the distance
        LDA.w !E4,x                             ;  | between the player and the sprite
        REP #$20                                ;  |
        SEC : SBC $D1                           ;  |
        SEP #$20

        BPL ..backward

..forward
        LDA #!StareForwardTopLeftTile
        STA !Frame
        RTS

..backward
        LDA #!StareBackwardTopLeftTile
        STA !Frame
++      RTS


SetFrameRunning:
	LDA #!RunningTile
	STA !Frame
	RTS

SetFrameRunning2:
	LDA #!RunningTile2
	STA !Frame
	RTS

SetFrameWalking1:
        LDA #!WalkingTopLeftTile
        STA !Frame
        RTS



; SetFrameWalking2:
;         LDA #!WalkingTopLeftTile+2
;         STA !Frame
;         RTS                                     ; /

GetModuloTwoOfA:
.loop
        SEC : SBC #$02
        CMP #$02
        BCS .loop

        RTS

GetModuloFourOfA:
.loop
        SEC : SBC #$04
        CMP #$04
        BCS .loop

        RTS

GetModuloFiveOfA:
.loop
        SEC : SBC #$05
        CMP #$05
        BCS .loop

        RTS

SetFrameJumping:
        LDA !Spinning
        BEQ .regJump

        LDA !SpinDirection
        CMP #$02
        BCC +

        LDA #$00
        STA !SpinDirection
+
        LDA $14

        JSR GetModuloTwoOfA

        CMP #$00
        BEQ .change     ; only change every 4 frames

        BRA .noChangeReturn     ; else don't change

.change
        LDA !Frame
        CMP #!WalkingTopLeftTile
        BNE .notSide    ; CURRENTLY: forward/back

        BRA .side       ; CURRENTLY: left/right

;---


.notSide
        CMP #!SpinningForwardTopLeftTile
        BEQ .right      ; forward -> right

        BRA .left       ; back -> left
.side
        LDA !SpinDirection
        BEQ .backward   ; right -> back

        BRA .forward    ; left -> forward


;---

.left
        LDA #$01
        STA !SpinDirection
        LDA #!WalkingTopLeftTile
        BRA .changeReturn

.forward
        LDA #!SpinningForwardTopLeftTile
        BRA .changeReturn     

.right
        LDA #$00
        STA !SpinDirection
        LDA #!WalkingTopLeftTile
        BRA .changeReturn

.backward
        LDA #!SpinningBackwardTopLeftTile
.changeReturn
        STA !Frame
        RTS

.noChangeReturn
        RTS

.regJump
		LDA !B6,x
		BPL + : EOR #$FF : INC : +
		CMP #$30
		BCC .noPSpeed

.pSpeed
		LDA #!JumpingPSpeedTLTile
		BRA ++

.noPSpeed
        LDA #!JumpingTopLeftTile
++
        STA !Frame
        RTS                                     ; /


; from RussianMan's key disassembly

SolidContact:
        LDA !14C8,x			;don't run this code if's being carried
        CMP #$09			;
        BNE .Return			;

        STZ !154C,x			;always contact with player

        LDA !D8,x
        SEC : SBC $D3
        CLC : ADC #$08
        CMP #$20
        BCC .SolidSides
        BPL .OnTop

        LDA #$10			;if hit from the bottom, act like "ceiling"
        STA $7D				;just give mario some downward speed, alright
        RTS				;

.OnTop
        LDA $7D				;if player jumps off
        BMI .Return			;goodbye

        STZ $7D				;act like solid ground and reset Y-speed
        STZ $72				;player's not in air. Player's on key!

        INC $1471|!Base2		;player's on solid sprite

        LDA #$1F
        LDY $187A|!Base2		;make player stand on key propertly if on yoshi
        BEQ .NoYoshi			;
        LDA #$2F			;by placing him/her a bit higher

.NoYoshi
        STA $00				;basically makes key transport player upward if it's also moving upward

        LDA !D8,x			;
        SEC : SBC $00			;
        STA $96				;

        LDA !14D4,x			;
        SBC #$00			;
        STA $97				;

.Return
        RTS

.SolidSides
        STZ $7B				;reset X speed
        %SubHorzPos()			;
        TYA				;
        ASL				;
        TAY				;
        REP #$21			;
        LDA $94				;
        ADC .DATA_01AB2D,y		;
        STA $94				;
        SEP #$20			;
        RTS				;

.DATA_01AB2D:
        db $01,$00,$FF,$FF		;




; "solid sprite" routine
; adapted from https://www.smwcentral.net/?p=section&a=details&id=9571
; (check that for a commented version)

SolidContactOld:
       STZ !SolidContactOccurred
.16x32
        LDA !E4,x
        STA $04
        LDA !14E0,x
        STA $0A
        LDA !14D4,x
        XBA
        LDA !D8,x
        REP #$20
        SEC : SBC #$0010
        SEP #$20
        STA $05
        XBA
        STA $0B
        LDA #$10
        STA $06
        LDA #$20
        STA $07
        JSL $03B664|!BankB

        JSL $03B72B|!BankB
        BCS .contact
        RTS
.contact

        JSR Get_Solid_Vert
        LDY $187A|!Base2
        LDA $0F
        CMP .heightReq,y
        BCS .decideDownOrSides
        BPL .decideDownOrSides

        INC !SolidContactOccurred

        LDA #$01
        STA $1471|!Base2

                                                ;  | if the sprite is set to be rideable,
                                                ;  | move the player along when they're on top of it
.ride                                           ;  | (taken from imamelia's mega mole disassembly)
        LDY #$00                                ;  |
        LDA $1491|!Base2                        ;  |
        BPL .rightXOffset                       ;  |
        DEY                                     ;  |
.rightXOffset                                   ;  |
        CLC                                     ;  |
        ADC $94                                 ;  |
        STA $94                                 ;  |
        TYA                                     ;  |
        ADC $95                                 ;  |
        STA $95                                 ;  |
.dontRide                                       ; /

        LDA #$E1
        LDY $187A|!Base2
        BEQ .noYoshi
        LDA #$D1
.noYoshi
        CLC
        ADC $05
        DEC
        STA $96
        LDA $0B
        ADC #$FF
        STA $97

        RTS

.heightReq
        db $D4,$C6,$C6

.decideDownOrSides
        LDA $0A
        XBA
        LDA $04
        REP #$20
        SEC
        SBC #$000C
        CMP $D1
        SEP #$20
        BCS .horzCheck

        REP #$20
        CLC
        ADC #$0008
        STA $0C
        SEP #$20

        LDA $0C
        CLC
        ADC $06
        STA $0C
        LDA $0D
        ADC #$00
        STA $0D
        REP #$20
        LDA $0C
        CMP $D1
        SEP #$20
        BCC .horzCheck

        LDA $7D
        BPL .noContact

        LDA #$08
        STA $7D

        INC !SolidContactOccurred

        RTS

.horzCheck
        JSR Get_Solid_Horz
        LDA $0F
        BMI .marioLeft

        SEC
        SBC $06
        BPL .noContact

        INC !SolidContactOccurred

        LDA $04
        CLC
        ADC $06
        STA $0C

        LDA $0A
        ADC #$00
        STA $0D

        REP #$20
        LDA $0C
        DEC
        DEC
        STA $94
        SEP #$20

        LDA $7B
        BPL .noContact
        STZ $7B

        RTS

.marioLeft

        CLC
        ADC #$10
        BMI .noContact

        INC !SolidContactOccurred

        LDA $04
        SEC
        SBC #$0D
        STA $0C

        LDA $0A
        SBC #$00
        STA $0D

        REP #$20
        LDA $0C

        DEC     ; I added this line to prevent the player "sticking" to the left side of the sprite
                ; (originally, when you touched the left edge and started moving left,
                ; you'd need to build up some speed for about half a second before actually moving away)
                ; does it have side effects? who knows

        STA $94
        SEP #$20

        LDA $7B
        BMI .noContact
        STZ $7B

.noContact
        RTS
        
Get_Solid_Vert:
        LDY #$00
        LDA $D3
        SEC
        SBC #$10
        SBC $05
        STA $0F
        LDA $D4
        SBC $0B
        BPL .marioLower
        INY
.marioLower
        STY $0E
        RTS

Get_Solid_Horz:
        LDY #$00
        LDA $D1
        SEC
        SBC $04
        STA $0F
        LDA $D2
        SBC $0A
        BPL .marioRight
        INY
.marioRight
        STY $0E
        RTS



; the code below is mostly copied from RussianMan's Key disassembly (thanks!)
; Currently set to not ever alter Mario's speed.

HandleCarryableSpriteStuff:

        LDA !14C8,x
        CMP #$0B
        BEQ .carried
.notCarried
        LDA !1588,x
        PHA
	JSL $019138|!BankB	; interact w/ blocks
	JSR SpriteAndSpecialBlockInteraction
        PLA
        STA !1588,x
.carried
        LDA !1588,x
        AND #$04
        BEQ .notOnGround

        JSR HandleLandingBounce

.notOnGround
        LDA !1588,x
        AND #$08
        BEQ .notAgainstCeiling

.againstCeiling
        LDA #$10
        STA !AA,x
        
        LDA !1588,x
        AND #$03
        BEQ .notAgainstWall

        LDA !E4,x
        CLC : ADC #$08
        STA $9A
        LDA !14E0,x
        ADC #$00
        STA $9B
        LDA !D8,x
        AND #$F0
        STA $98
        LDA !14D4,x
        STA $99

        LDA !1588,x
        AND #$20
        ASL #3
        ROL
        AND #$01
        STA $1933|!Base2

        LDY #$00
        LDA $1868|!Base2
        JSL $00F160|!BankB

        LDA #$08
        STA !1FE2,x

.notAgainstCeiling
        LDA !1588,x
        AND #$03
        BEQ .notAgainstWall

        JSR HandleBlockHit
        
        ; reverse x speed if wall hit
        ; LDA !B6,x
        ; ASL
        ; PHP
        ; ROR !B6,x
        ; ASL
        ; ROR !B6,x
        ; PLP
        ; ROR !B6,x

        ; kill x speed if wall hit (this code never runs?)
        LDA #$00
        STA !B6,x

;.notOnGround
.notAgainstWall

        RTS





HandleBlockHit:

        LDA #$01
        STA $1DF9|!Base2

        LDA !15A0,x
        BNE .return

        LDA !E4,x
        SEC : SBC $1A
        CLC : ADC #$14
        CMP #$1C
        BCC .return

        LDA !1588,x
        AND #$40
        ASL #2
        ROR
        AND #$01
        STA $1933|!Base2

        LDY #$00
        LDA $18A7|!Base2
        JSL $00F160|!BankB

        LDA #$05
        STA !1FE2,x

.return
        RTS





HandleLandingBounce:

	LDA $7E010B		; Get current level
	CMP #!TitleScreenLevel	; Don't touch X speed if on this level
	BEQ .return

.halveXSpeed
	LDA !B6,x
	PHP
	BPL +
	EOR #$FF : INC
+   LSR
	PLP
	BPL +
	EOR #$FF : INC
+   STA !B6,x
;         LDA !AA,x
;         PHA

;         LDA !1588,x
;         BMI .speed2
;         LDA #$00
;         LDY !15B8,x
;         BEQ .store
; .speed2
;         LDA #$18
; .store
;         STA !AA,x

;         PLA
;         LSR #2
;         TAY
;         LDA .bounceSpeeds,y
;         LDY !1588,x
;         BMI .return
;         STA !AA,x

.return
	STZ !AA,x	; Sprite should never bounce up and down because mario doesn't work like that
	RTS

.bounceSpeeds
        db $00,$00,$00,$F8,$F8,$F8,$F8,$F8
        db $F8,$F7,$F6,$F5,$F4,$F3,$F2,$E8
        db $E8,$E8,$E8,$00,$00,$00,$00,$FE
        db $FC,$F8,$EC,$EC,$EC,$E8,$E4,$E0
        db $DC,$D8,$D4,$D0,$CC,$C8


HandleInteraction:

        LDA !154C,x          ; Interaction timer
        BNE .return
        JSL $01803A|!BankB   ; Player interaction
        BCC .return

        LDA #$01
        STA !TeleportReady
        LDA $15
        AND #$40
        BEQ .checkSprite

        LDA $1470|!Base2     ; Checking if the player can carry it
        ORA $148F|!Base2
        ORA $187A|!Base2
        BNE .checkSprite

        LDA #$0B
        STA !14C8,x

.keepCarried
        INC $1470|!Base2
        LDA #$08
        STA $1498|!Base2
        CLC
        RTS

.checkSprite
        LDA !14C8,x
        CMP #$09
        BNE .return

        ; Player carries object
        STZ !154C,x
        LDA !D8,x
        SEC : SBC $D3
        CLC : ADC #$08
        CMP #$20
        BCC .solidSides
        BPL .onTop

        LDA #$10
        STA $7D

        CLC
        RTS

.onTop
        ; I do not want the player to be able to stand on top to avoid key jump type tricks.
        ; Uncomment this code if you wish to re-enable it.
;if !CanStandOnIt
;        LDA $7D            
;        BMI .return
;
;        STZ $7D
;        STZ $72
;        INC $1471|!Base2
;
;        LDA #$1F           ; Check Yoshi state
;        LDY $187A|!Base2
;        BEQ .notOnYoshi
;        LDA #$2F
;.notOnYoshi
;        STA $00
;
;        LDA !D8,x
;        SEC : SBC $00
;        STA $96
;        LDA !14D4,x
;        SBC #$00
;        STA $97
;
;        SEC
;        RTS
;endif

.return
        CLC
        RTS

.solidSides
;if !SolidSides
;        STZ $7B
;        %SubHorzPos()
;        TYA : ASL : TAY
;        REP #$21
;        LDA $94
;        ADC .DATA_01AB2D,y
;        STA $94
;        SEP #$20
;        CLC
;endif
        RTS

.DATA_01AB2D
        db $01,$00,$FF,$FF

CheckInteractableBlocksList:
	; Get X, Y position of block from $19138
	LDA $0F
	PHA

	JSL $019138|!BankB
	LDA $0C
	STA $98
	LDA $0D
	STA $99
	LDA $0A
	STA $9A
	LDA $0B
	STA $9B
	STZ $1933

	PLA
	STA $0F

	; Get Map16 Bytes (in A, 16-bit)
	%GetMap16()

	;Koopa Block is 299 (#$0299)
	REP #$20
	CMP #$0299
	SEP #$20
	;BEQ .koopaBlock        I decided to handle this directly from KoopaBlock.asm for better or worse

	RTS

.koopaBlock
	LDA !Spinning
	BEQ ..notSpinning

..spinning
	LDA !JumpHeld
	BEQ ..low

..high
	LDA #!NonSpikyHighSpin
	BRA +
..low
	LDA #!NonSpikyLowSpin
+
	STA !BouncingSpeed
	BRA .return
	
..notSpinning
	LDA !JumpHeld
	BNE ..highJump

..lowJump
	LDA #!NonSpikyLowBounce
	STA !BouncingSpeed
	BRA .return

..highJump
	LDA #!NonSpikyHighBounce
	STA !BouncingSpeed
.return
	
	RTS

SpriteAndSpecialBlockInteraction:
	LDA !BouncingSpeed
	BNE .done
; Spin Interaction
; Get Sprite-Sprite Contact
	JSR SprSprContact       ; clone = x, sprite in contact = y

; If Contact Not Found, Try Blocks
	LDA $00
	BEQ .sprSprContactFound

	JMP CheckInteractableBlocksList

.sprSprContactFound
	JSR SetCarryIfShell
	BCC .koopaCheck

.spriteIsVanillaShell
	JMP MarioSpriteInteractWithVanillaShell

.koopaCheck
        CMP #$0D        ; vanilla koopas are <= 0C
        BCS .spinyCheck
        BRA .tryBounce

.spinyCheck
        CMP #$13        ; spiny is 13
        BNE .done

.tryBounce
	JMP MarioSpriteTryBounceOrSpin	; not shell, maybe koopa/spiny?

.done
	RTS

MarioSpriteInteractWithVanillaShell:
	; if IFrames on shell, don't interact
	LDA !154C,y
	BNE .return

	; if shell carried AND MarioSprite is grounded, don't interact
	LDA !14C8,y
	CMP #$0B
	BNE .checkStationary

	LDA !1588,x
	AND #$04
	BNE .return

	; if shell carried and MarioSprite in air, only bounce
	JMP MarioSpriteTryBounceOrSpin

.checkStationary
	; if shell just sitting there, interact
	CMP !StationaryCarryable
	BEQ .tryKickShell

.tryBounceOffKickedShell
	PHY
		JSR MarioSpriteTryBounceOrSpin
	PLY

	PHX
		TYX
		LDA !7FAB9E,x
	PLX
	CMP #!KoopaShellTeleports
	BNE .dontSetTPShellCarried		; if not TPShell, continue

.setTPShellCarried
	; unless player not holding X or Y
	LDA $15
	;Controller buttons currently held down. Format: byetUDLR.
	;b = A or B; y = X or Y; e = select; t = Start; U = up; D = down; L = left, R = right.
	AND #$40                                ;  | 01000000, so check if X or Y pressed.
	BEQ .dontSetTPShellCarried					;byetUDLR | if not pressed, do normal behavior

	%SetSpriteStatus(#$0B, y)
	BRA .return

.dontSetTPShellCarried
	%SetSpriteStatus(!StationaryCarryable, y)
	BRA .return

.tryKickShell
	; if spinning, don't kick, just kill the shell
	LDA !Spinning
	BEQ ..okToKick

	JMP MarioSpriteTryBounceOrSpin_spinning

..okToKick
	; set shell to kicked and don't bounce
	%SetSpriteStatus(#$0A, y)
	; give shell its speed
	JSR GetMarioSpriteRightOfContactSprite
	BMI ..kickRight

..kickLeft
	LDA #!ShellKickXSpeed
	EOR #$FF
	INC
	BRA ..store

..kickRight
	LDA #!ShellKickXSpeed
..store
	STA !B6,y
..kickIFrames
	; shells don't interact a few frames after being kicked
	LDA #$08
    STA !154C,y
..kickSoundAndPoints
	;sound
	LDA #$03
	STA $1DF9|!Base2

.givePoints
	;points
	JSR GivePoints

.return
	RTS

GetMarioSpriteRightOfContactSprite:
    LDA !14E0,y
    XBA
    LDA !E4,y
    REP #$20
    STA $00
    SEP #$20

    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$20
    CLC : SBC $00
    SEP #$20

    RTS

MarioSpriteTryBounceOrSpin:
	LDA !14C8,y	; if carried, just allow bouncing/spinning regardless if on top
	CMP #$0B
	BEQ .checkIfSpinning

	; For leniency on shell jumps, just let the clone bounce/spin if it's airborne already
	CMP #$0A	; check if kicked
	BNE .normalHeightCheck

	LDA !1588,x             					; Check if sprite is blocked downward (on ground)
	AND #$04                
	BEQ .airborneLenientShellJump              	; If sprite is not on ground (airborne), branch to .airborneLenientShellJump

	; if clone is on ground, normal height check
.normalHeightCheck
	; Will either skip to death, skip to normal jumping, or
	; return here to try to spin jump.
	; (depending if MarioSprite is above the sprite, and
	; sprite is non-spiky, etc.)
	JMP CheckIfMarioSpriteOnTop
	
.airborneLenientShellJump
.checkIfSpinning
; Check if Clone is Spinning
	LDA !Spinning
	BEQ .notSpinning

; Check if Sprite is Able to be Bounced On
.spinning
	LDA !1656,y
	AND #$10              	; gets J bit - can be jumped on
	BNE .notSpiky         	; if not spiky, try spin kill.

; If spiky, spin bounce
.spiky
	LDA !JumpHeld
	BEQ ..low

..high
	LDA #!SpikyHighSpin
	BRA +
..low
	LDA #!SpikyLowSpin
+
	STA !BouncingSpeed
.spikySoundAndGFX
	STZ $00 : STZ $01
	LDA #$08 : STA $02
	LDA #$02	; contact graphic
	%SpawnSmoke()

	; Sound
	LDA #$02
	STA $1DF9|!Base2
	BRA .killSpriteIfNeed

.notSpiky
	LDA !JumpHeld
	BEQ ..low

..high
	LDA #!NonSpikyHighSpin
	BRA +
..low
	LDA #!NonSpikyLowSpin
+
	STA !BouncingSpeed
.notSpikySound
	PHY
	STZ $00 : STZ $01
	LDA #$08 : STA $02
	LDA #$02	; contact graphic (smoke not working)
	%SpawnSmoke()
	JSL $07FC3B|!bank       ;> Generate stars from spinjump kill.
	PLY
    JSR GivePoints          ;> Give points.
    LDA #$08                ;\ Play SFX.
    STA $1DF9|!addr         ;/
.killSpriteIfNeed
	LDA !1656,y
	AND #$30                ; gets j bit - dies when jumped on and gets J bit - can be jumped on (#$20 and #$10)
	BEQ .done               ; if both of these are false, don't kill.

	%SetSpriteStatus(#$04, y)	; kill with spinjump
	BRA .done

.notSpinning
	JSR CheckIfMarioSpriteJumpingOnJumpableSprite

.done
	RTS

SprSprContact:
	LDY #!SprSize-1		;loop count (loop though all sprite number slots)

.Loop
	PHX
	LDA !14C8,y			;load sprite status
	BEQ .LoopSprSpr		;if non-existant, keep looping.

	LDA !7FAB9E,x		;load this sprite's number
	STA $07				;store to scratch RAM.
	TXA					;transfer X to A (sprite index)
	STA $08				;store it to scratch RAM.
	TYA					;transfer Y to A
	CMP $08				;compare with sprite index
	BEQ .LoopSprSpr		;if equal, keep looping.

	TYX					;transfer Y to X
	LDA !7FAB9E,x		;load sprite number according to index
	CMP $07				;compare with this sprite's number from scratch RAM
	BEQ .LoopSprSpr		;if equal, keep looping.

	; If squished koopa, skip
	LDA !14C8,x
	CMP #$03
	BEQ .LoopSprSpr

	; If button, skip (bug where clone can spin on button sprites)
	LDA !7FAB9E,x
	CMP #$18
	BEQ .LoopSprSpr

	CMP #$19
	BEQ .LoopSprSpr

; If PlayerCursor Sprite (above mario's head), skip
	CMP #$15
	BEQ .LoopSprSpr

; If spinyshell.asm (5B), and it's stationary or interaction disabled, skip
	CMP #$5B
	BNE +

	LDA !14C8,x
	CMP #$09
	BEQ .LoopSprSpr

	LDA !154C,x             ;\ If contact is disabled, skip interaction.
	BNE .LoopSprSpr

+
	PLX					;restore sprite index.
	JSL $03B6E5|!BankB	;get sprite A clipping (this sprite)
	PHX					;preserve sprite index
	TYX					;transfer Y to X
	JSL $03B69F|!BankB	;get sprite B clipping (interacted sprite)
	JSL $03B72B|!BankB	;check for contact
	BCC .LoopSprSpr		;if carry is set, there's contact, so exit loop.

	LDA #$00
	STA $00             ;set flag to show found contact
	PLX					;restore sprite index

	RTS					;return.

.LoopSprSpr
	PLX					;restore sprite index
	DEY					;decrement loop count by one
	BPL .Loop			;and loop while not negative.

	LDA #$FF
	STA $00             ;set flag to show did not find contact
	RTS					;end? return.

CheckIfMarioSpriteOnTop:
    LDA #!NumPixelsAboveSpriteRequiredToBounce    ;#$14       ;\ the lower this value, the more lenient 
    STA $01                 ;|
    LDA $05                 ;|
    SEC                     ;|
    SBC $01                 ;|
    ROL $00                 ;|
    CMP !D8,x ;$D3                 ;|	player y pos
    PHP                     ;|
    LSR $00                 ;|
    LDA $0B                 ;|
    SBC #$00                ;| Don't bounce on the sprite if one of these is true:
    PLP                     ;|  - Mario's Y position is too low w.r.t. the sprite's Y position.
    SBC !14D4,x ;$D4 ;player y pos   ;|  - Mario is moving upwards, the sprite can't be hit while moving upward

	;LDA !14D4,x
	;XBA
	;LDA.w !D8,x
	;REP #$20
	;SEC : SBC $D3
	;STA $00
    BMI KillMarioSprite         ;|     and Mario hasn't bounced on any other enemies.
    LDA !AA,x ;$7D ;player y speed ;|  - Both Mario and the sprite are on the ground.
    BPL +                   ;|
    LDA !190F,y ;,x         ;|
    AND #$10                ;| if can't be jumped with upspeed
    BEQ KillMarioSprite		;  kill mariosprite
+   LDA !1588,y              ;if touched sprite in air skip
    AND #$04                 
    BEQ ++                   
    LDA !1588,x ;$72         
	AND #$04                ; else, if both MarioSprite and
    BNE KillMarioSprite     ; touched sprite on ground, kill
++  LDA !1656,y ;x          
    AND #$10                ;| If the sprite can be bounced on, jump.
    BNE CheckIfMarioSpriteJumpingOnJumpableSprite        ;/
	; Otherwise, return to SpriteAndSpecialBlockInteraction to try spin.
	JMP MarioSpriteTryBounceOrSpin_checkIfSpinning

CheckIfMarioSpriteJumpingOnJumpableSprite:
	; x = MarioSprite, y = contact sprite
	; Check if Sprite is Able to be Bounced On
	LDA !1656,y
	AND #$10	; J bit (can be jumped on)
	BEQ .cannotBeJumpedOn

.canBeJumpedOn
	LDA !JumpHeld
	BNE ..highJump

..lowJump
	LDA #!NonSpikyLowBounce
	STA !BouncingSpeed
	BRA ..checkIfSpriteNeedsToBeKilled

..highJump
	LDA #!NonSpikyHighBounce
	STA !BouncingSpeed
..checkIfSpriteNeedsToBeKilled
	LDA !1656,y
	AND #$20
	BEQ ..jumpSoundAndPoints

..alsoKillSprite
	%SetSpriteStatus(#$03, y) ; LDA #$03 : STA !14C8,y (squish)
..jumpSoundAndPoints
	STZ $00 : STZ $01
	LDA #$08 : STA $02
	LDA #$02	; contact graphic
	%SpawnSmoke()

	; JSR SetCarryIfShell
	; BCC .return
	;; only give points if not shell? (since shells inherently give points when jumped on)
	JSR GivePoints

	BRA .return

.cannotBeJumpedOn	; SpikySprite+normaljump=die
	JSR KillMarioSprite
	
.return
	RTS

KillMarioSprite:
	LDA #!DeadTopLeftTile
	STA !Frame
	JSR Graphics	;rerun graphics before mario dies

	JSL $00F606     ;kill mario
	RTS


;;;;;;;;; SPRITE FREEZING ;;;;;;;;;

FreezeAllSprites:
LDX #!sprite_slots-1
.loop
LDA !9E,x								;/
.checkGoalTape
CMP #$7B								;| Don't freeze the goal tape.
BNE .checkMarioSprite					;| 
JMP .next

.checkMarioSprite
LDA !7FAB9E,x
CMP #!MarioSpriteNumber					;| Don't freeze the MarioSprite.
BNE +									;| 
JMP .next
+
if !FreezeMiscTables
CMP !StartRAM+(!sprite_slots*28),x		; If the sprite number changed last frame (e.g. Parakoopa to Koopa when jumped on), backup the sprite tables instead.
BNE +

CMP #$98					;/
BNE .NotPitchChuck			;|
LDA !1540,x					;|
AND #$1F					;|
CMP #$06					;|
BEQ +						;|
BRA .DontCheckChange		;|
.NotPitchChuck				;|
CMP #$9B					;|
BNE .NotHammerBro			;| Pitchin' Chuck, Flyin' Hammer Bro and Dry Bones need a check for their timer that controls when they throw.
LDA !1540,x					;| Otherwise, freezing them on the same frame they throw will cause them to keep throwing every frame until the extended sprite slots are full.
BNE +						;|
BRA .DontCheckChange		;|
.NotHammerBro				;|
CMP #$30					;|
BNE .NotDryBones			;|
LDA !1540,x					;|
CMP #$01					;|
BEQ +						;|
BRA .DontCheckChange		;|
.NotDryBones				;\

CMP #$3E								;/
BEQ .CheckPChange						;|
CMP #$9C								;|
BEQ .CheckC2Change						;|
CMP #$AB								;|
BEQ .CheckC2Change						;|
CMP #$C8								;|
BEQ .CheckC2Change						;| Various sprites which require a check for a state change.
CMP #$83								;|
BEQ .CheckC2Change						;|
CMP #$84								;|
BEQ .CheckC2Change						;|
CMP #$B9								;|
BNE .DontCheckChange					;\
.CheckC2Change
LDA !C2,x								;/
CMP !StartRAM+(!sprite_slots*7),x		;| If C2 changed last frame for the Flying Grey Platform, Rex, the Light Switch Block, the Message Box or the Flying ?-blocks,
BEQ .DontCheckChange					;\ backup the sprite tables.
+
-
JSR SprRAMTransfer
JMP .next

.CheckPChange
LDA !163E,x				;/
BNE -					;\ Backup the sprite tables if it's a pressed P-switch.
.DontCheckChange
endif

LDA !14C8,x				;/
CMP #$0B				;| Backup the tables if the sprite is carried or a goal coin (but actually only carried since the code immediately returns if $1493 is set).
BCC +					;\
-
JSR SprRAMTransfer
JMP .next
+
CMP #$08								; If the sprite isn't alive (or empty/init), backup the tables.
BCC -
CMP !StartRAM+(!sprite_slots*6),x		; If the sprite status changed last frame, backup the tables. Ensures the sprite's tables are initialized properly before freezing. 
BNE -

TXA									;/
INC									;|
CMP $18E2|!addr						;|
BNE +								;|
LDA $187A|!addr						;|
BNE -								;| If Mario is riding Yoshi or the ride flag changed last frame, backup Yoshi's tables. Prevents jank with mounting/dismounting.
if !FreezeMiscTables				;|
CMP !StartRAM+(!sprite_slots*29)	;|
else								;|
CMP !StartRAM+(!sprite_slots*7)		;|
endif								;|
BNE -								;\
+

%RAMToSpr(!E4, 0)					; Moves all the RAM backups to the sprite tables every frame, freezing them.
%RAMToSpr(!14E0, 1)					; If !FreezeMiscTables is disabled then only the sprite position, speed, and fraction bits are backed up.
%RAMToSpr(!D8, 2)
%RAMToSpr(!14D4, 3)
%RAMToSpr(!AA, 4)
%RAMToSpr(!B6, 5)
if !FreezeMiscTables
LDA !9E,x							;/
CMP #$35							;|
BEQ +								;| Don't ever change C2 for Yoshi.
%RAMToSpr(!C2, 7)					;|
+									;\
%RAMToSpr(!1504, 8)
%RAMToSpr(!1510, 9)
%RAMToSpr(!151C, 10)
%RAMToSpr(!1528, 11)
%RAMToSpr(!1534, 12)
LDA !9E,x							;/
CMP #$2F                            ; added by SJC
BEQ +
CMP #$04							;|
BCC .NotKoopa						;|
CMP #$08							;|
BCC +								;| Don't ever change 1540 for the normal Koopas (prevents spawn jank with the sliding koopa when a normal Koopa is bounced on).
.NotKoopa							;|
%RAMToSpr(!1540, 13)				;|
+									;\

LDA !7FAB9E,x
CMP #$1B
BEQ ++
%RAMToSpr(!154C, 14) ; leave 154C (contact disabled flag) alone for 1B: sprites/KoopaShell.asm
++
%RAMToSpr(!1558, 15)
%RAMToSpr(!1564, 16)
%RAMToSpr(!1570, 17)
%RAMToSpr(!157C, 18)
%RAMToSpr(!1594, 19)
%RAMToSpr(!15AC, 20)
%RAMToSpr(!15D0, 21)
%RAMToSpr(!15F6, 22)
%RAMToSpr(!1602, 23)
%RAMToSpr(!160E, 24)
%RAMToSpr(!1626, 25)
%RAMToSpr(!163E, 26)
%RAMToSpr(!187B, 27)
endif
STZ !14EC,x							;/
STZ !14F8,x							;\ Zero the fraction bits to prevent jittering.

.next
DEX
BMI +
JMP .loop
+
LDA $187A|!addr						;/
if !FreezeMiscTables				;|
STA !StartRAM+(!sprite_slots*29)	;| Backup the riding Yoshi flag.
else								;|
STA !StartRAM+(!sprite_slots*7)		;\
endif
RTS;RTL

; --------------------

BackupAllSpriteProperties:					; Pretty much the same stuff but for backing up the sprite tables in freeRAM when not frozen.
LDX #!sprite_slots-1
.loop
LDA !9E,x
CMP #$7B
BEQ .next
.checkMarioSprite
LDA !7FAB9E,x
CMP #!MarioSpriteNumber
BEQ .next
LDA !14C8,x
BEQ .next
CMP #$01
BEQ +
CMP #$0B
BCS .next
+

JSR SprRAMTransfer

.next
DEX
BPL .loop
LDA $187A|!addr
if !FreezeMiscTables
STA !StartRAM+(!sprite_slots*29)
else
STA !StartRAM+(!sprite_slots*7)
endif
RTS;RTL

SprRAMTransfer:		; This is in a subroutine since it also needs to be accessed by some sprites in the loop when the freeze is active.

%SprToRAM(!E4, 0)
%SprToRAM(!14E0, 1)
%SprToRAM(!D8, 2)
%SprToRAM(!14D4, 3)
%SprToRAM(!AA, 4)
%SprToRAM(!B6, 5)
%SprToRAM(!14C8, 6)
if !FreezeMiscTables
%SprToRAM(!C2, 7)
%SprToRAM(!1504, 8)
%SprToRAM(!1510, 9)
%SprToRAM(!151C, 10)
%SprToRAM(!1528, 11)
%SprToRAM(!1534, 12)
LDA !9E,x
CMP #$2F   ; added by 
BEQ +      ; SJC
CMP #$04
BCC .NotKoopa
CMP #$08
BCC +
.NotKoopa
%SprToRAM(!1540, 13)
+

LDA !7FAB9E,x
CMP #$1B
BEQ ++
%SprToRAM(!154C, 14) ; leave 154C (contact disabled flag) alone for 1B: sprites/KoopaShell.asm
++
%SprToRAM(!1558, 15)
%SprToRAM(!1564, 16)
%SprToRAM(!1570, 17)
%SprToRAM(!157C, 18)
%SprToRAM(!1594, 19)
%SprToRAM(!15AC, 20)
%SprToRAM(!15D0, 21)
%SprToRAM(!15F6, 22)
%SprToRAM(!1602, 23)
%SprToRAM(!160E, 24)
%SprToRAM(!1626, 25)
%SprToRAM(!163E, 26)
%SprToRAM(!187B, 27)
%SprToRAM(!9E, 28)
endif

RTS

; if !PlatformsFix && !FreezeMiscTables
; pushpc					;/
; ORG $01B498				;|
; JSL Fix					;|
; ORG $01CA56				;|
; JSL Fix					;|
; pullpc					;|
; 						;| Fixes Mario sliding on platforms while frozen if he's stood on one.
; Fix:					;|
; LDA !FreeRAMTimer		;|
; BNE .NoMove				;|
; LDA $77					;|
; AND #$03				;|
; .NoMove					;|
; RTL						;\

; else
; pushpc					;/
; ORG $01B498				;|
; LDA $77					;|
; AND #$03				;|
; ORG $01CA56				;| Restore hijacked code if the platform fix is disabled.
; LDA $77					;|
; AND #$03				;|
; pullpc					;\
; endif