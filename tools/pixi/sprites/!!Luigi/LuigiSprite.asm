;===============================================================
; Mario/Luigi Luigi Sprite
;===============================================================
; A sprite that mimics player physics and behaviors, with the 
; ability to teleport/swap places with the real player.
;
; Extra Byte 1: Initial Properties
;   - Bit 0: Start spinning
;   - Bit 1: Start with jump held
;   - Bit 2: Teleport ready
;   - Bits 3-7: Reserved
;
; Extra Byte 2: Initial X Speed (-128 to 127)
; Extra Byte 3: Initial Y Speed (-128 to 127)
; Extra Byte 4: Special Level Properties
;   - If non-zero, treat as running level
;===============================================================

incsrc "../Config.asm"
incsrc "Teleport.asm"

; Animation frame definitions
!StationaryHatTLTile    = $00
!WalkingTopLeftTile     = $20
!JumpingTopLeftTile     = $04
!JumpingPSpeedTLTile    = $02
!SpinningForwardTLTile  = $06
!SpinningBackwardTLTile = $08
!DeadTopLeftTile        = $0A
!StareForwardTLTile     = $0C
!StareBackwardTLTile    = $0E
!RunningTile            = $2C
!RunningTile2           = $48
!SwimmingTile          = $22

; Sprite states
!StationaryCarryable    = $09

print "INIT ",pc
    PHB : PHK : PLB
    
    ; Initialize sprite as stationary/carryable
    LDA #!StationaryCarryable
    STA !14C8,x
    STA !PreviousState
    
    ; Set "Don't get stuck in walls" flag
    LDA !190F,x
    ORA #$80
    STA !190F,x
    
    ; Initialize from extra bytes
    JSR InitFromExtraBytes
    
    PLB
    RTL

print "MAIN ",pc
    PHB : PHK : PLB
    JSR SpriteMain
    PLB
    RTL

;===============================================================
; Main sprite routine
;===============================================================
SpriteMain:
    JSR UpdatePoints
    JSR UnsetCustomFTrigger
    JSR UpdateStareTimer
    JSR UpdateBounceSpeed
    
    ; Skip graphics if dying
    LDA $71
    CMP #$09
    BEQ .justGraphics
    
    JSR CheckIfKilled
    LDA $00
    BNE .killPlayer
    
    LDA $9D
    BNE .noCarry
    JSR HandleCarryableSpriteStuff
    
.noCarry
    JSR HandleTeleportState
    
    LDA !State
    BEQ .notTeleporting
    
    ; Keep sprites frozen while teleporting
    PHX
    JSR FreezeAllSprites
    PLX
    BRA .graphics
    
.notTeleporting
    LDA $9D
    BNE .graphics
    
    JSR HandleNormalState
    
.graphics
    JSR Graphics
    RTS

.justGraphics
    JSR Graphics
    RTS

.killPlayer
    LDA #!DeadTopLeftTile
    STA !Frame
    JSR Graphics
    JSL $00F606|!bank     ; Kill Mario
    RTS

;===============================================================
; Initialize sprite from extra bytes
;===============================================================
InitFromExtraBytes:
    %prepare_extra_bytes()
    
    ; Extra byte 1: Initial properties
    %load_extra_byte(1)
    
    ; Set spinning if bit 0 set
    AND #$01
    STA !Spinning
    
    ; Set jump held if bit 1 set
    %load_extra_byte(1)
    AND #$02
    LSR
    STA !JumpHeld
    
    ; Set teleport ready if bit 2 set
    %load_extra_byte(1)
    AND #$04
    LSR #2
    STA !TeleportReady
    
    ; Extra byte 2: Initial X speed
    %load_extra_byte(2)
    STA !B6,x
    
    ; Extra byte 3: Initial Y speed
    %load_extra_byte(3)
    STA !AA,x
    
    ; Extra byte 4: Special level properties
    %load_extra_byte(4)
    STA !RunningLevel
    
    ; Initialize other properties
    LDA #$00
    STA !StareTimer
    STA !Frozen
    STA !BouncingSpeed
    STA !PlayerOnlyStomped
    STA !IsMario
    STA !1626,x
    STA !OnPlatform
    STA !164A,x
    
    RTS

;===============================================================
; Helper functions
;===============================================================

; Updates consecutive enemy stomp counter
UpdatePoints:
    LDA !14C8,x
    CMP #$0B
    BEQ .checkPlayer
    
    LDA !1588,x
    AND #$04
    BEQ .inAir
    
    STZ !1626,x
    
.checkPlayer
    LDA $72
    BNE .inAir
    
    LDA $1697|!addr
    SEC : SBC !1626,x
    BMI .restore
    CMP !PlayerOnlyStomped
    BCS .updateAndExit
    
.restore
    LDA !PlayerOnlyStomped
    CLC : ADC !1626,x
    STA $1697|!addr
    
.updateAndExit
    LDA $1697|!addr
    SEC : SBC !1626,x
    STA !PlayerOnlyStomped
    RTS
    
.inAir
    RTS

; Unsets custom F trigger (used for 1-up color)
UnsetCustomFTrigger:
    REP #$20
    LDA $41C0FC
    AND #$7FFF
    STA $41C0FC
    SEP #$20
    RTS

; Updates stare animation timer
UpdateStareTimer:
    LDA !Frame
    CMP #$04
    BCC .onGround
    CMP #$0C
    BCS .onGround
    
    LDA !1588,x
    AND #$04
    BNE .justLanded
    RTS
    
.onGround
    LDA $14
    BNE .return
    INC !StareTimer
    
.justLanded
.return
    RTS

; Updates bounce speed (one frame delayed)
UpdateBounceSpeed:
    LDA !BouncingSpeed
    BEQ .return
    
    CMP #!BounceDelay+1
    BCC .decrement
    
    STA !AA,x
    LDA #!BounceDelay
    STA !BouncingSpeed
    RTS
    
.decrement
    DEC A
    STA !BouncingSpeed
    
.return
    RTS

;===============================================================
; Constants for bounce speeds and behaviors
;===============================================================
!NonSpikyLowBounce   = $E6
!NonSpikyHighBounce  = $AA
!NonSpikyLowSpin     = $FE
!NonSpikyHighSpin    = $FC
!SpikyLowSpin        = $D3
!SpikyHighSpin       = $AA
!BounceDelay         = $08

; Sprite interaction
!NumPixelsAboveSpriteRequiredToBounce = $00
!NumPixelsBelowSprite                 = $0011
!XOffset                              = $08

;===============================================================
; Normal state handling
;===============================================================
HandleNormalState:
    JSR CheckIfKilled
    LDA $00
    BEQ .notDead

.dead
    JSR SetFrameDead
    RTS

.notDead
    LDA !14C8,x
    CMP #$0B
    BNE .notCarried

.carried
    LDA !Spinning
    BNE .jumping

    LDA !164A,x
    BEQ .noSwim

.swim
    LDA #!SwimmingTile
    BRA ++
    
.noSwim
    LDA #!JumpingTopLeftTile
++  STA !Frame
    RTS

.notCarried
    LDA !1588,x
    AND #$04
    BEQ .jumping

.walking
    JSR SetFrameWalking
    LDA $72
    BNE .return

    LDA #$00
    STA !Spinning
    STA !JumpHeld

.return
    RTS

.jumping
    JSR SetFrameJumping
    RTS

;===============================================================
; Frame setting routines
;===============================================================
SetFrameDead:
    LDA #!DeadTopLeftTile
    STA !Frame
    RTS

SetFrameWalking:
    ; Check if running level
    LDA $40010B
    CMP #!RunningLevel
    BNE .notRunning

.running
    LDA $14
    AND #$01
    BEQ +

    JSR SetFrameRunning
    BRA ++

+   JSR SetFrameRunning2
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
    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$20
    SEC : SBC $D1
    SEP #$20
    BPL ..forward
    BRA ..backward

..right
    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$20
    SEC : SBC $D1
    SEP #$20
    BPL ..backward

..forward
    LDA #!StareForwardTopLeftTile
    STA !Frame
    RTS

..backward
    LDA #!StareBackwardTopLeftTile
    STA !Frame
++  RTS

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

SetFrameJumping:
    LDA !Spinning
    BEQ .regJump

    LDA !SpinDirection
    CMP #$02
    BCC +

    LDA #$00
    STA !SpinDirection
+   LDA $14
    JSR GetModuloTwoOfA
    CMP #$00
    BEQ .change

    BRA .noChangeReturn

.change
    LDA !Frame
    CMP #!WalkingTopLeftTile
    BNE .notSide

    BRA .side

.notSide
    CMP #!SpinningForwardTLTile
    BEQ .right
    BRA .left

.side
    LDA !SpinDirection
    BEQ .backward
    BRA .forward

.left
    LDA #$01
    STA !SpinDirection
    LDA #!WalkingTopLeftTile
    BRA .changeReturn

.forward
    LDA #!SpinningForwardTLTile
    BRA .changeReturn

.right
    LDA #$00
    STA !SpinDirection
    LDA #!WalkingTopLeftTile
    BRA .changeReturn

.backward
    LDA #!SpinningBackwardTLTile

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
    LDA !164A,x
    BEQ .noSwim

.swim
    LDA #!SwimmingTile
    BRA ++

.noSwim
    LDA #!JumpingTopLeftTile
++  STA !Frame
    RTS

;===============================================================
; Utility functions
;===============================================================
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

CheckIfKilled:
    LDA !14C8,x
    CMP #$06
    BCC .killPlayer

.dontKillPlayer
    LDA #$00
    STA $00
    RTS

.killPlayer
    LDA #$01
    STA $00
    RTS

;===============================================================
; Graphics Routine
;===============================================================
Graphics:
    %GetDrawInfo()

    LDA $00                     ; X position
    STA $0300|!Base2,y
    
    LDA $01                     ; Y position
    SEC : SBC #$10             ; Offset up by 16 pixels
    STA $0301|!Base2,y
    
    JSR GetTopTile
    STA $0302|!Base2,y
    
    ; Set properties
    LDA !TeleportReady 
    BNE + 
    LDA #$11                    ; If not teleport ready, use different palette
    BRA ++ 
+   LDA #$21                    ; Normal palette
++  ORA $03                     ; Add flip bits
    STA $0303|!Base2,y

    INY #4                      ; Move to next tile slot

    ; Draw bottom tile
    LDA $00
    STA $0300|!Base2,y
    LDA $01
    STA $0301|!Base2,y
    
    JSR GetBottomTile
    STA $0302|!Base2,y
    
    ; Set properties (same as top tile)
    LDA !TeleportReady 
    BNE + 
    LDA #$11
    BRA ++ 
+   LDA #$21
++  ORA $03
    STA $0303|!Base2,y

    LDY #$02                    ; 2 tiles
    LDA #$01                    ; 16x32 size
    JSL $01B7B3|!BankB
    RTS

;---------------------------------------------------------------
; Get top tile number
;---------------------------------------------------------------
GetTopTile:
    PHX
    LDX $15E9|!addr
    JSR SetCarryIfReusingHatTile
    BCS .topTileIsHat

.topTileIsOther
    LDA !Frame
    BRA .return

.topTileIsHat
    LDA #!StationaryHatTLTile

.return
    PLX
    RTS

;---------------------------------------------------------------
; Get bottom tile number
;---------------------------------------------------------------
GetBottomTile:
    JSR SetCarryIfReusingHatTile
    BCS .topTileIsHat

.topTileIsOther
    LDA !Frame
    CLC : ADC #$20             ; Next row in GFX
    BRA .return

.topTileIsHat
    LDA !Frame

.return
    RTS

;---------------------------------------------------------------
; Check if should reuse hat tile
;---------------------------------------------------------------
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

;---------------------------------------------------------------
; Handles points when bouncing on enemies
;---------------------------------------------------------------
GivePoints:
    INC !1626,x             ; Increment consecutive hits
    JSR RememberPoints      ; Update point counters
    
    LDA $1697|!addr        ; Get consecutive enemies hit
    TAY
    CPY #$08               ; Cap at 1-up (8)
    BCS .playSound
    
    LDA .SFX-1,y          ; Play appropriate sound
    STA $1DF9|!addr
    
.playSound
    TYA
    CMP #$08
    BCC +
    
    LDA #$08              ; Cap points at 1-up
+   JSL $02ACE5|!bank     ; Give points
    RTS

.SFX:
    db $13,$14,$15,$16,$17,$18,$19

;---------------------------------------------------------------
; Handles sprite behavior when carryable
;---------------------------------------------------------------
HandleCarryableSpriteStuff:
    LDA !14C8,x
    CMP #$0B
    BEQ .carried

    CMP #$0A
    BNE .notCarried

.kicked
    LDA !PreviousState
    CMP #$0B
    BNE .notCarried

    LDA #$10              ; Set kick timer
    STA !154C,x

.notCarried
    LDA !1588,x
    PHA
    JSL $019138|!BankB    ; Interact with blocks
    PLA
    STA !1588,x

    LDA !OnPlatform       ; If on platform, force ground flag
    BEQ +

.onPlatform
    LDA !1588,x
    ORA #$04
    STA !1588,x
    BRA .groundCodeDone

.carried
+   LDA !1588,x           ; Check if on ground
    AND #$04
    BEQ .notOnGround

    JSR HandleLandingBounce

.notOnGround
.groundCodeDone
    LDA !1588,x           ; Check ceiling collision
    AND #$08
    BEQ .notAgainstCeiling

.againstCeiling
    LDA #$10
    STA !AA,x             ; Bounce off ceiling

    LDA !1588,x           ; Check wall collision
    AND #$03
    BEQ .notAgainstWall

    JSR HandleBlockHit

    LDA #$00              ; Kill X speed on wall hit
    STA !B6,x

.notAgainstCeiling
.notAgainstWall
    RTS

;---------------------------------------------------------------
; Handles bouncing when landing
;---------------------------------------------------------------
HandleLandingBounce:
    LDA !B6,x             ; Halve X speed on landing
    PHP
    BPL +
    EOR #$FF : INC
+   LSR
    PLP
    BPL +
    EOR #$FF : INC
+   STA !B6,x
    STZ !AA,x             ; Zero Y speed
    RTS

;---------------------------------------------------------------
; Handles block hit effects
;---------------------------------------------------------------
HandleBlockHit:
    LDA !15A0,x           ; Return if offscreen
    BNE .return

    LDA !E4,x             ; Check if in visible range
    SEC : SBC $1A
    CLC : ADC #$14
    CMP #$1C
    BCC .return

    LDA !1588,x           ; Get block direction
    AND #$40
    ASL #2
    ROR
    AND #$01
    STA $1933|!Base2

    LDY #$00
    LDA $18A7|!Base2
    JSL $00F160|!BankB    ; Show block hit sprite

    LDA #$05
    STA !1FE2,x           ; Set block hit timer

.return
    RTS 