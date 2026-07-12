;===============================================================
; Sprite Interaction System
;===============================================================
; Handles interactions with other sprites and special blocks
;
; To add new sprite interactions:
; 1. Add sprite number to appropriate list below
; 2. Add handler routine if needed
; 3. Update CheckSpriteInteraction to handle new case
;===============================================================

incsrc "../Config.asm"

; Sprite lists for different interaction types
!NoInteractSprites:
    db $7B        ; Goal tape
    db $1C        ; Bullet Bill
    db $B9        ; Message box
    db $79        ; Growing vine
    db $80        ; Key
    db $3E        ; P-Switch
    db $3F        ; P-Switch (pressed)
    db $FF        ; End of list

!BounceableSprites:
    db $04,$05,$06,$07,$08,$09,$0A,$0B,$0C  ; Various Koopas
    db $13        ; Spiny
    db $1A        ; Piranha Plant
    db $26        ; Thwomp
    db $3B        ; Urchin
    db $4F        ; Jumping Piranha
    db $0F        ; Goomba
    db $11        ; Buzzy Beetle
    db $FF        ; End of list

!PlatformSprites:
    db $61        ; Floating skulls
    db $C4        ; Grey platform
    db $62        ; Brown platform
    db $63        ; Checker platform
    db $64        ; Orange platform
    db $FF        ; End of list

;===============================================================
; Main interaction handler
;===============================================================
HandleSpriteInteraction:
    JSR FindContactedSprite    ; Returns sprite slot in Y, sets carry if found
    BCS .found
    RTS

.found
    JSR CheckSpriteType        ; Returns interaction type in A
    JSL $0086DF|!BankB
    dw ReturnRoutine           ; 0 = No interaction
    dw HandleBounceSprite      ; 1 = Bounceable sprite
    dw HandlePlatformSprite    ; 2 = Platform sprite
    dw HandleShellSprite       ; 3 = Shell sprite
    dw HandleCustomSprite      ; 4 = Custom sprite

;===============================================================
; Sprite type checking
;===============================================================
CheckSpriteType:
    LDA !7FAB10,y             ; Check if custom sprite
    AND #$08
    BNE .checkCustom
    
    ; Check vanilla sprite lists
    LDA !9E,y
    
    ; First check no-interact list
    LDX #$00
.checkNoInteract
    CMP !NoInteractSprites,x
    BEQ .noInteraction
    INX
    LDA !NoInteractSprites,x
    CMP #$FF
    BNE .checkNoInteract
    
    ; Check bounceable list
    LDX #$00
.checkBounce
    CMP !BounceableSprites,x
    BEQ .checkIfSpiky
    INX
    LDA !BounceableSprites,x
    CMP #$FF
    BNE .checkBounce
    
    ; Check platform list
    LDX #$00
.checkPlatform
    CMP !PlatformSprites,x
    BEQ .platform
    INX
    LDA !PlatformSprites,x
    CMP #$FF
    BNE .checkPlatform
    
    ; Check if shell
    CMP #$DA
    BCS .checkShellRange
    RTS

.checkShellRange
    CMP #$E0
    BCC .shell
    RTS

.checkCustom
    LDA !7FAB9E,y
    ; Custom sprites also need spiky check
    BRA .checkIfSpiky

.checkIfSpiky
    LDA !1656,y              ; Check sprite properties
    AND #$10                 ; Check if spiky (bit 5)
    BEQ .bounceable         ; If not spiky, treat as bounceable
    LDA #$04                ; If spiky, return spiky type
    RTS

.noInteraction
    LDA #$00
    RTS

.bounceable
    LDA #$01
    RTS

.platform
    LDA #$02
    RTS

.shell
    LDA #$03
    RTS

HandleBounceSprite:
    JSR CheckIfAboveSprite
    BCC .killLuigi
    
    LDA !Spinning
    BNE .spinKill
    
    ; Normal bounce
    LDA !JumpHeld
    BEQ .lowBounce
    
.highBounce
    LDA #!NonSpikyHighBounce
    BRA .setBounce
    
.lowBounce
    LDA #!NonSpikyLowBounce
    
.setBounce
    STA !BouncingSpeed
    JSR GivePoints
    RTS

.spinKill
    LDA !JumpHeld
    BEQ .lowSpin
    
.highSpin
    LDA #!NonSpikyHighSpin
    BRA +
.lowSpin
    LDA #!NonSpikyLowSpin
+   STA !BouncingSpeed

    JSR GivePoints
    %SetSpriteStatus(#$04, y)    ; Kill with spinjump
    RTS

.killLuigi
    JSR KillLuigi
    RTS

HandlePlatformSprite:
    JSR CheckIfAboveSprite
    BCC .return
    
    JSR SetOnPlatform
    
.return
    RTS

HandleShellSprite:
    LDA !14C8,y
    CMP #$0B
    BEQ .shellCarried
    
    JSR CheckIfAboveSprite
    BCC .tryKick
    
    ; Bounce off shell
    LDA !Spinning
    BEQ .normalBounce
    
    ; Kill shell if spinning
    %SetSpriteStatus(!StationaryCarryable, y)
    
.spinBounce
    LDA !JumpHeld
    BEQ .lowSpin
    
.highSpin
    LDA #!NonSpikyHighSpin
    BRA .setBounce
    
.lowSpin
    LDA #!NonSpikyLowSpin
    
.setBounce
    STA !BouncingSpeed
    JSR GivePoints
    RTS

.normalBounce
    JMP HandleBounceSprite

.shellCarried
    RTS

.tryKick
    LDA !154C,y             ; Check kick timer
    BNE .return
    
    LDA !14C8,y
    CMP #$09                ; Check if shell stationary
    BNE .return
    
    ; Kick the shell
    %SetSpriteStatus(#$0A, y)
    
    ; Set shell speed based on direction
    JSR GetLuigiRightOfContactSprite
    BMI .kickRight
    
.kickLeft
    LDA #$D2                ; -2E
    BRA +
    
.kickRight
    LDA #$2E
+   STA !B6,y
    
    ; Set kick timer
    LDA #$08
    STA !154C,y
    
    ; Sound effect
    LDA #$03
    STA $1DF9|!Base2
    
    JSR GivePoints

.return
    RTS

HandleCustomSprite:
    ; Add custom sprite interaction code
    RTS

;===============================================================
; Helper functions
;===============================================================
FindContactedSprite:
    LDY #!sprite_slots-1
.loop
    LDA !14C8,y
    BEQ .next
    
    PHX
    TYX
    JSL $03B6E5|!BankB
    PLX
    JSL $03B69F|!BankB
    JSL $03B72B|!BankB
    BCS .found
    
.next
    DEY
    BPL .loop
    CLC
    RTS
    
.found
    SEC
    RTS

CheckIfAboveSprite:
    ; Returns carry set if Luigi is above sprite
    LDA !D8,y
    SEC : SBC !D8,x
    CMP #!NumPixelsAboveSpriteRequiredToBounce
    RTS

SetOnPlatform:
    LDA #$01
    STA !OnPlatform
    
    ; Match platform Y position
    LDA !D8,y
    SEC : SBC #$0F
    STA !D8,x
    LDA !14D4,y
    SBC #$00
    STA !14D4,x
    
    ; Match speeds
    LDA !B6,y
    STA !B6,x
    LDA !AA,y
    STA !AA,x
    RTS

ReturnRoutine:
    RTS 