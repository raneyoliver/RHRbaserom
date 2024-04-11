; definitions

        !distL	=	$0010	; distance to check offscreen on the left (0040 = 4 16x16 tiles)
        !distR	=	$0010	; distance to check offscreen on the right

        !TeleportingSpeed = $60                 ; Speed the camera/teleport moves
        !FreezeTimeWhenTeleporting = 1          ; 0 = no, 1 = yes
        !StopTeleportWithin = #$0010

        !State =                !1504,x
        !Timer =                !1528,x
        !SparkleTimer =         $7FA01D
        !TeleportReady =        $7FA016
        !PlayerPosXLow =        $7FA007
        !PlayerPosXHigh =       $7FA008
        !PlayerSpeedX =         $7FA009
        !PlayerSpeedY =         $7FA00A
        !CloneSpeedX =          $7FA00E
        !CloneSpeedY =          $7FA00F
        !PlayerPosYLow =        !1626,x
        !PlayerPosYHigh =       !1534,x
        !Spinning =             $7FA00C
        !TempSpinning =         $7FA019
        !SpinTimer =            $7FA017
        !JumpHeld =             $7FA018
        !SpinDirection       =  $7FA01E
        !StareTimer =           $7FA01F
        !StareTimerHigh =       $7FA020
        !Frozen =               $7FA021
        !FreezeBlockFrozenFlag = $7FA022        ; from uberASM/level/FreezeSpritesOnTrigger.asm

        !CanStandOnIt = 0                       ; 1 = Mario can stand on the sprite
        !SolidSides = 0                         ; 1 = the sprite is solid from the sides
        
        !FixFreeze              = 1               ; 0 = no, 1 = yes
        !FreezeRAM              = $1FFF|!Base2    ; 1 byte of free RAM.

        
        !Lvl18XSpeed =           $24
        !Lvl1AXSpeed =           $24

        !UpSpeed = #$9F                         ; Upward Speed post-teleport
        !DownSpeed = #$40                       ; Downward Speed post-teleport

        !LowBounce =         #$E6
        !HighBounce =        #$AA
        !BounceLeftSpeed   =    #$DC
        !BounceRightSpeed =     #$24

        !NPCState               = !C2,x
        !LevelNumberBackup      = !1510,x ;!1504,x
        !Frame                  = !1570,x
        !SolidContactOccurred   = !187B,x

        !WalkingTopLeftTile     = $00
        !JumpingTopLeftTile     = $04
        ;!TalkingTopLeftTile     = $06
        !SpinningForwardTopLeftTile    = $06
        !SpinningBackwardTopLeftTile    = $08
        !DeadTopLeftTile        = $0A
        !StareForwardTopLeftTile     = $0C
        !StareBackwardTopLeftTile     = $0E


; init routine

print "INIT ",pc

        STZ !NPCState
        LDA $13BF|!addr
        STA !LevelNumberBackup

        LDA #$09
        STA !14C8,x
        LDA #$00
        STA !Spinning
        STA !JumpHeld
        STA !StareTimerHigh
        STA !Frozen

        LDA #$FF
        STA !StareTimer

        LDA $7E010B
        CMP #$0A                ; level 0A
        BEQ .lvl0A

        CMP #$18                ; level 18
        BEQ .lvl18

        CMP #$1A
        BEQ .lvl1A

        BRA .startReady

.lvl0A
        LDA #$00
        STA !TeleportReady      ; Make sure that it starts as not teleport ready
        RTL

.lvl18
        ; LVL 18: Fall right, spin, can't tp, low bounce
        LDA #!Lvl18XSpeed
        STA !B6,x

        LDA #$01
        STA !Spinning

        LDA #$00
        STA !JumpHeld

        LDA #$00
        STA !TeleportReady

        RTL

.lvl1A
        ; LVL 1A: Fall right, no spin, can tp, high bounce
        LDA #!Lvl1AXSpeed
        STA !B6,x

        LDA #$01
        STA !Spinning

        LDA #$01
        STA !JumpHeld

        LDA #$01
        STA !TeleportReady

        RTL

.startReady
        LDA #$01
        STA !TeleportReady
        RTL

; main routine

print "MAIN ",pc

        PHB : PHK : PLB : JSR SpriteCode : PLB : RTL : SpriteCode:

        LDA !Timer
        BEQ +

        DEC !Timer

+
        JSR DecrementTimers

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
        JSR HandleState

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

        ;JSR SolidContact

        JSR Graphics
        RTS



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

DecrementTimers:
;if spinning
        ;if timer not 0
                ;dec timer
        ;else
                ;set timer to ff
;else
        ;skip

        LDA !Spinning
        BEQ .sparkle

        LDA !SpinTimer
        BEQ .resetSpinTimer
.decSpinTimer
        SEC : SBC #$01
        STA !SpinTimer
        BRA .sparkle

.resetSpinTimer
        LDA #$FF
        STA !SpinTimer

.sparkle
        LDA !SparkleTimer
        BEQ .resetSparkleTimer

.decSparkleTimer
        SEC : SBC #$01
        STA !SparkleTimer

        LDA !Frame
        CMP #$04        ;was ground
        BCC .continueStareCountdown

        CMP #$0C        ;was ground
        BCS .continueStareCountdown

        LDA !1588,x     ;just now landing
        AND #$04
        BEQ .re

.startStareCountdown    ;if wasn't on ground and just now landing
        LDA #$FF
        STA !StareTimer ;start timer as landing
        LDA #$00
        STA !StareTimerHigh
        BRA .re

.continueStareCountdown
        LDA !StareTimer
        BEQ .resetStareTimer

        SEC : SBC #$01
        STA !StareTimer
.re
        RTS

.resetSparkleTimer
        LDA #$FF
        STA !SparkleTimer
        RTS

.resetStareTimer
        LDA #$FF
        STA !StareTimer
        LDA !StareTimerHigh
        INC A
        STA !StareTimerHigh
        RTS

HandleState:

        LDA !State
        JSL $0086DF|!BankB
        dw .idle, .enteringPipe, .teleporting, .stalling, .exitingPipe



        ; state 00: idle (carryable and solid, waiting for player to enter)

.idle      
        JSR HandleInteraction                   ; \
        
        LDA $18								    ;  | initiate teleporting if you press R
        AND #$10                                ;  | 00010000 -> AXLR---- , so check if R pressed.
        BNE ..check                  ; /
        RTS

..check
        LDA $9D
        BNE ..cancel

        LDA !FreezeBlockFrozenFlag
        BNE ..cancel

        BRA ..beginTeleporting

..cancel
        RTS

..beginTeleporting
        LDA $1470|!Base2                        ; \
        ORA $148F|!Base2                        ;  | don't allow teleporting if you're carrying something
        BNE ..dontTeleport                      ; /

        LDA $1426|!Base2                        ; \  don't allow teleporting if a message box is active
        BNE ..dontTeleport                      ; /

        LDA !TeleportReady                      ; \ don't allow teleporting if the sprite is not touched yet
        BEQ ..dontTeleport                      ; /

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

..doTeleport
        LDA #$01
        STA !Frozen

        LDA #$00
        STA !StareTimerHigh

        LDA #$FF
        STA !StareTimer

        JSR SetupAttributesOfClone

        LDA #$FF
        STA $9D

        JSR EraseFireballs

        LDA #$25                                ; \  play blargg roar
        STA $1DF9|!Base2                        ; / 

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
        LDA $16                                 ; \
        AND #$04                                ;  | if you're not allowed to teleport,
        BEQ .return                             ;  | play "wrong" sound once
        LDA #$2A                                ;  |
        STA $1DFC|!Base2                        ; /

.return
        RTS

        ; state 01: "entering pipe" animation

.enteringPipe

        STZ $73                                 ; \
        LDA #$FF                              ;  |
        STA $9D                               ;  |

        ; freeze clone and player, speed is already stored
        STZ !B6,x
        STZ !AA,x
        STZ $7B
        STZ $7D


        LDA !Timer
        BEQ ..nextState

        
        RTS

..nextState

        JSR EraseFireballs

        INC !State
        RTS

        ; state 02: teleporting (player is invisible and moving between pipes)

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
;        if !FreezeTimeWhenTeleporting           ;  |
;          STA $9D                               ;  |
;          if !FixFreeze                         ;  |
;            STA !FreezeRAM                      ;  |
;          endif                                 ;  |
;        endif                                   ; /

        JSR SetTeleportingXSpeed                ; \  move the player to the other pipe
        JSR SetTeleportingYSpeed                ; /

        LDA $7B                                 ; \
        ORA $7D                                 ;  | if the player doesn't need to move anymore
        ORA $17BC|!Base2                        ;  | and the screen has caught up with them too,
        ORA $17BD|!Base2                        ;  | we're done teleporting
        BNE ..keepTeleporting                   ; /



..doneTeleporting
        

        ;LDA #$18                                ; \  play Thunder sound
        ;STA $1DFC|!Base2                        ; /

        ;LDA #$01
        ;STA $1DFC|!Base2

        LDA #$FF
        STA !Timer
        INC !State

..keepTeleporting

        STZ !B6,x
        STZ !AA,x

        LDA #$FF
        STA $9D
;        if !FreezeTimeWhenTeleporting           ;  |
;          LDA #$FF                              ;  |
;          STA $9D                               ;  |
;          if !FixFreeze                         ;  |
;            STA !FreezeRAM                      ;  |
;          endif                                 ;  |
;        endif                                   ;  |

        RTS


        ; state 03: Stalling for 08 frames. 
        ; this is very finicky, so be careful if you want to change how long the stalling occurs.

.stalling

        ;LDA !Timer
        ;BEQ +
        LDA #$01
        STA !Timer
        INC !State
        RTS


        ; state 04: "exiting pipe" animation

.exitingPipe

        ;LDA !Timer
        ;BEQ ..nextState

        ;LDA #$01                                ; \
        ;STA $185C|!Base2                        ;  | all kinds of teleportation settings
        ;LDA #$02                                ;  |
        ;STA $13F9|!Base2                        ;  |
;        if !FreezeTimeWhenTeleporting           ;  |
;          LDA #$FF                              ;  |
;          STA $9D                               ;  |
;          if !FixFreeze                         ;  |
;            STA !FreezeRAM                      ;  |
;          endif                                 ;  |
;        endif                                   ;  |
;        RTS                                     ; /

..nextState

;        ; store sprite high/low x to player high/low x
;        LDA !14E0,x
;        XBA  
;        LDA.w !E4,x
;        REP #$20
;        STA $D1
;        SEP #$20
;
;        ; store sprite high/low y to player high/low y
;        LDA !14D4,x
;        XBA
;        LDA.w !D8,x
;        REP #$20
;        SEC : SBC #$0020
;        STA $D3
;        SEP #$20

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

        BRA ..nonePressed
..upPressed
        LDA $15
        AND #$08
        BEQ ..nonePressed
        LDA !UpSpeed
        STA $7D
..nonePressed
                                                ; \
        STZ $185C|!Base2                        ;  |
        STZ $13F9|!Base2                        ;  | all kinds of teleportation settings
        STZ $1419|!Base2                        ;  |
        ;STZ $78                                 ; /

        ;Set state back to idle
        LDA !State       ; Load the value of !State into the accumulator
        SEC              ; Set the carry flag to indicate subtraction
        SBC #$04         ; Subtract 4 from the value in the accumulator
        STA !State       ; Store the result back into !State

        LDA #$00
        STA !Frozen

        BRA ..return

..return
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
        LDA #$FF
        STA !SpinTimer


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
        BRA ++

.notDead
        LDA !1588,x
        AND #$04
        BEQ +

        JSR SetFrameWalking
        LDA $72
        BNE ++

        LDA #$00
        STA !Spinning           ; not spinning if on ground
        STA !SpinTimer
        STA !JumpHeld

        BRA ++
+       JSR SetFrameJumping
        
++
        RTS

; graphics routine

Graphics:
        ; set up properties byte
        LDA !157C,x                             ; \
        STA $03

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
        LDA !157C,x                             ; \
        AND #$01                                ;  |
        EOR #$01                                ;  | set the x flip bit based on direction
        ROR #3                                  ;  |
        STA $03                                 ; /

.defaultPalette                                 ;  |
        LDA !JumpHeld
        BEQ .jumpNotHeld

.jumpHeld
        JSR DisplaySparkle

        LDA #$01
        BRA +

.jumpNotHeld
        LDA #$01        ;palette 8?
+
        TSB $03

.16x32

        %GetDrawInfo()

        LDA $00
        STA $0300|!Base2,y
        LDA $01
        SEC : SBC #$10
        STA $0301|!Base2,y
        LDA !Frame
        STA $0302|!Base2,y              ; YXPP CCCT
        LDA #$31                        ; 0001 1111
        ORA $03
        STA $0303|!Base2,y

        INY #4

        LDA $00
        STA $0300|!Base2,y
        LDA $01
        STA $0301|!Base2,y
        LDA !Frame
        CLC : ADC #$20
        STA $0302|!Base2,y
        LDA #$31
        ORA $03
        STA $0303|!Base2,y

        LDY #$02
        LDA #$01
        JSL $01B7B3|!BankB

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


DisplaySparkle:
        JSR CheckHorzOffscreen
        BCC .okay

        RTS

.okay
        LDA !SparkleTimer
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
        LDA !TeleportReady
        BEQ .walk
        
        LDA !StareTimerHigh
        JSR GetModuloFourOfA
        CMP #$03
        BNE .walk

        LDA !StareTimer
        CMP #$C0
        BCC .stare

.walk
        JSR SetFrameWalking1
        BRA ++

.stare                  ;stare is run when StareTimer is <C0 and StareTimerHigh % 4 == 3, so there's a while before you set the clone down until he actually stares
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



SetFrameWalking1:
        LDA #!WalkingTopLeftTile
        STA !Frame
        RTS



SetFrameWalking2:
        LDA #!WalkingTopLeftTile+2
        STA !Frame
        RTS                                     ; /

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
        LDA !SpinTimer

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
        LDA #!JumpingTopLeftTile
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
        JSL $019138|!BankB

        JSR SpinInteraction
.carried
        LDA !1588,x
        AND #$04
        BEQ .notOnGround

        JSR HandleLandingBounce

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
        LDA !B6,x
        ASL
        PHP
        ROR !B6,x
        ASL
        ROR !B6,x
        PLP
        ROR !B6,x

.notOnGround
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

        LDA !B6,x
        PHP
        BPL +
        EOR #$FF : INC
+       LSR
        PLP
        BPL +
        EOR #$FF : INC
+       STA !B6,x
        LDA !AA,x
        PHA

        LDA !1588,x
        BMI .speed2
        LDA #$00
        LDY !15B8,x
        BEQ .store
.speed2
        LDA #$18
.store
        STA !AA,x

        PLA
        LSR #2
        TAY
        LDA .bounceSpeeds,y
        LDY !1588,x
        BMI .return
        STA !AA,x

.return
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
if !CanStandOnIt
        LDA $7D            
        BMI .return

        STZ $7D
        STZ $72
        INC $1471|!Base2

        LDA #$1F           ; Check Yoshi state
        LDY $187A|!Base2
        BEQ .notOnYoshi
        LDA #$2F
.notOnYoshi
        STA $00

        LDA !D8,x
        SEC : SBC $00
        STA $96
        LDA !14D4,x
        SBC #$00
        STA $97

        SEC
        RTS
endif

.return
        CLC
        RTS

.solidSides
if !SolidSides
        STZ $7B
        %SubHorzPos()
        TYA : ASL : TAY
        REP #$21
        LDA $94
        ADC .DATA_01AB2D,y
        STA $94
        SEP #$20
        CLC
endif
        RTS

.DATA_01AB2D
        db $01,$00,$FF,$FF


SpinInteraction:
; Spin Interaction
; Get Sprite-Sprite Contact
        JSR SprSprContact       ; clone = x, sprite in contact = y

; If Contact Not Found, Skip
        LDA $00
        BNE .done
        PHX     ; store sprite index

; If button, skip (bug where clone can spin on button sprites)
        TYX
        LDA !7FAB9E,x
        PLX     ; restore sprite index
        CMP #$18
        BEQ .done

        CMP #$19
        BEQ .done

; If PlayerCursor Sprite (above mario's head), skip
        CMP #$15
        BEQ .done

; If spinyshell.asm (5B), and it's stationary or interaction disabled, skip
        CMP #$5B
        BNE +

        LDA !14C8,y
        CMP #$09
        BEQ .done

        LDA !154C,y             ;\ If contact is disabled, skip interaction.
        BNE .done

+
; Check if Clone is Spinning
        LDA !Spinning
        BEQ .done

; Check if Sprite is Able to be Bounced On
        LDA !1656,y
        AND #$30                ; gets j and J bits - dies when jumped on and can be jumped on 
        BNE .done               ; if both aren't 0, sprite can't be bounced on

; If Spinning, Bounce Clone and Play Sound and Show Effect
.spinBounce
        LDA !JumpHeld
        BEQ .low

.high
        LDA !HighBounce
        BRA +
.low
        LDA !LowBounce

+
        STA !AA,x
.sound
        LDA #$02
        STA $1DF9|!Base2

        BRA .done

; If not, Kill Clone Sprite and Play Sound and Show Effect
.notSpinning
        STZ !14C8,x

        LDA #$06
        STA $1DF9|!Base2

        RTS

.done
        RTS

SprSprContact:
        LDY #!SprSize-1		;loop count (loop though all sprite number slots)

.Loop
	PHX
	LDA !14C8,y		;load sprite status
	BEQ .LoopSprSpr		;if non-existant, keep looping.

	LDA !7FAB9E,x		;load this sprite's number
	STA $07			;store to scratch RAM.
	TXA			;transfer X to A (sprite index)
	STA $08			;store it to scratch RAM.
	TYA			;transfer Y to A
	CMP $08			;compare with sprite index
	BEQ .LoopSprSpr		;if equal, keep looping.
	TYX			;transfer Y to X
	LDA !7FAB9E,x		;load sprite number according to index
	CMP $07			;compare with cursor's number from scratch RAM
	BEQ .LoopSprSpr		;if equal, keep looping.

	PLX			;restore sprite index.
	JSL $03B6E5|!BankB	;get sprite A clipping (this sprite)
	PHX			;preserve sprite index
	TYX			;transfer Y to X
	JSL $03B69F|!BankB	;get sprite B clipping (interacted sprite)
	JSL $03B72B|!BankB	;check for contact
	BCC .LoopSprSpr		;if carry is set, there's contact, so exit loop.
	
        LDA #$00
        STA $00                 ;set flag to show found contact
	PLX			;restore sprite index
	RTS			;return.

.LoopSprSpr
	PLX			;restore sprite index
	DEY			;decrement loop count by one
	BPL .Loop		;and loop while not negative.

        LDA #$FF
        STA $00                 ;set flag to show did not find contact
	RTS			;end? return.
