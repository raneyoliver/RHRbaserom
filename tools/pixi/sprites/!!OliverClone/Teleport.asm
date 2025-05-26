;===============================================================
; Teleport Mechanics
;===============================================================
; Handles the teleport/swap functionality of the Oliver Clone sprite
; States:
; 0 = Idle/Not teleporting
; 1 = Entering teleport
; 2 = Moving to destination
; 3 = Exiting teleport
;===============================================================

incsrc "../Config.asm"
incsrc "../../routines/SpriteFreezing.asm"

!TeleportingSpeed = $60            ; Speed of camera/teleport movement
!StopTeleportWithin = $0010        ; Distance threshold to stop movement
!PlayerMinX = $02                  ; Minimum valid X position
!PlayerMaxX = $DF                  ; Maximum valid X position  
!PlayerMinY = $02                  ; Minimum valid Y position
!PlayerMaxY = $BE                  ; Maximum valid Y position

;===============================================================
; Main teleport state handler
;===============================================================
HandleTeleportState:
    LDA !State
    JSL $0086DF|!BankB
    dw .idle
    dw .enteringPipe
    dw .teleporting  
    dw .exitingPipe

;===============================================================
; State 0: Check for teleport trigger
;===============================================================
.idle
    LDA $18                     ; Check L/R buttons
    AND #$30                    ; %00110000 = L/R mask
    BEQ .return
    
    ; Cancel if sprites frozen
    LDA $9D                     
    BNE .return

    ; Don't allow if carrying something
    LDA $1470|!Base2           
    ORA $148F|!Base2
    BNE .return

    ; Don't allow during message box
    LDA $1426|!Base2
    BNE .return

    ; Must have touched clone first
    LDA !TeleportReady
    BEQ .return

    JSR SetupTeleport
    INC !State                  ; Move to entering state

.return
    RTS

;===============================================================
; State 1: Start teleport sequence
;===============================================================
.enteringPipe
    STZ $73                     ; Clear ducking
    LDA #$FF                    
    STA $9D                     ; Freeze sprites
    
    STZ !B6,x                   ; Zero speeds
    STZ !AA,x
    STZ $7B
    STZ $7D
    
    JSR EraseFireballs         ; Clear fireballs
    
    INC !State                  ; Move to teleporting state
    RTS

;===============================================================
; State 2: Move player and clone
;===============================================================
.teleporting
    ; Set teleport flags
    LDA #$01                    
    STA $1404|!Base2
    STA $1406|!Base2
    STZ $73
    LDA #$01
    STA $185C|!Base2
    LDA #$02
    STA $13F9|!Base2
    LDA #$FF
    STA $78
    STA $9D
    
    ; Move X position
    JSR SetTeleportingXSpeed
    
    ; Move Y position  
    JSR SetTeleportingYSpeed
    
    ; Check if done moving
    LDA $7B
    ORA $7D
    ORA $17BC|!Base2
    ORA $17BD|!Base2
    BNE .stillMoving
    
    INC !State                  ; Move to exit state
    
.stillMoving
    STZ !B6,x                   ; Keep speeds zeroed
    STZ !AA,x
    RTS

;===============================================================
; State 3: Complete teleport
;===============================================================
.exitingPipe
    JSR FlipMarioLuigi         ; Switch Mario/Luigi if needed
    
    ; Clear teleport flags
    STZ $185C|!Base2
    STZ $13F9|!Base2
    STZ $1419|!Base2
    STZ $9D                     ; Unfreeze sprites
    
    ; Reset state
    LDA !State
    SEC : SBC #$03
    STA !State
    
    LDA #$00
    STA !Frozen
    RTS

;===============================================================
; Helper functions 
;===============================================================

; Sets up initial teleport state
SetupTeleport:
    LDA #$01
    STA !Frozen
    
    LDA #$00  
    STA !StareTimer
    
    JSR SetupAttributesOfClone
    
    ; Backup sprite states
    PHX
    JSR BackupAllSpriteProperties
    PLX
    
    LDA #$FF
    STA $9D
    
    JSR EraseFireballs
    JSR PlaySound
    RTS

;---------------------------------------------------------------
; Sets X speed for teleport movement
;---------------------------------------------------------------
SetTeleportingXSpeed:
    LDA $7E                     ; Check screen boundaries
    CMP #!PlayerMinX
    BCC .return
    CMP #!PlayerMaxX  
    BCS .return

    ; Calculate distance between sprite and player
    LDA !14E0,x                
    XBA                        
    LDA !E4,x                  
    REP #$20                   
    SEC : SBC $D1              
    STA $00                    
    SEP #$20                   

    ; Check if close enough to stop
    BPL + 
    EOR #$FFFF 
    INC A
+   CMP #!StopTeleportWithin
    SEP #$20
    BCS .movePlayer
    
    ; Close enough - stop movement
    STZ $7B                    
    RTS

.movePlayer
    REP #$20                   
    LDA $00                    
    SEP #$20                   
    BMI .moveRight
    
.moveLeft
    LDA #$80                   ; Move left at max speed
    BRA .setSpeed
    
.moveRight
    LDA #$7F                   ; Move right at max speed

.setSpeed
    STA $7B

.return
    RTS

;---------------------------------------------------------------
; Sets Y speed for teleport movement  
;---------------------------------------------------------------
SetTeleportingYSpeed:
    LDA $80                     ; Check screen boundaries
    CMP #!PlayerMinY
    BCC .haltReturn
    CMP #!PlayerMaxY
    BCS .haltReturn

    ; Calculate Y distance
    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    SEC : SBC $D3
    STA $00
    SEP #$20

    ; Check if close enough
    BPL +
    EOR #$FFFF
    INC A
+   CMP #!StopTeleportWithin
    SEP #$20
    BCS .movePlayer
    
    ; Close enough - stop movement
    STZ $7D
    RTS

.movePlayer
    REP #$20
    LDA $00
    SEP #$20
    BMI .moveDown
    
.moveUp
    LDA #$80                   ; Move up at max speed
    BRA .setSpeed
    
.moveDown
    LDA #$7F                   ; Move down at max speed

.setSpeed
    STA $7D
    RTS

.haltReturn
    STZ $7D
    RTS

;---------------------------------------------------------------
; Switches between Mario and Luigi
;---------------------------------------------------------------
FlipMarioLuigi:
    LDA !IsMario
    EOR #$01                   ; Toggle Mario/Luigi flag
    STA !IsMario
    RTS

;---------------------------------------------------------------
; Backs up clone and player attributes before teleport
;---------------------------------------------------------------
SetupAttributesOfClone:
    ; Backup direction
    LDA !157C,x
    STA !SpriteDirection

    ; Backup positions
    LDA $D1                    ; Player X low
    STA !PlayerPosXLow
    LDA $D2                    ; Player X high
    STA !PlayerPosXHigh
    LDA $D3                    ; Player Y low  
    STA !PlayerPosYLow
    LDA $D4                    ; Player Y high
    STA !PlayerPosYHigh

    ; Backup speeds
    LDA $7B                    ; Player X speed
    STA !PlayerSpeedX
    LDA $77                    ; Check if on ground
    AND #$04
    BNE .removeGravity

.withGravity
    LDA $7D                    ; Player Y speed with gravity
    STA !PlayerSpeedY
    BRA .continue

.removeGravity
    LDA #$00                   ; No Y speed on ground
    STA !PlayerSpeedY

.continue
    ; Backup clone speeds
    LDA !B6,x
    STA !CloneSpeedX
    LDA !AA,x  
    STA !CloneSpeedY

    ; Backup spin states
    LDA !Spinning
    STA !TempSpinning
    LDA $140D|!addr            ; Player spin flag
    STA !Spinning

    ; Set jump held if A/B pressed
    LDA $15                    ; Controller flags
    AND #$80                   ; Check A/B buttons
    BEQ .noJump
    LDA #$01
    BRA +
.noJump
    LDA #$00
+   STA !JumpHeld

    RTS

;---------------------------------------------------------------
; Erases all fireballs on screen
;---------------------------------------------------------------
EraseFireballs:
    LDY #$09
.loop
    LDA !extended_num,y
    CMP #$05                   ; Fireball sprite number
    BNE .next
    LDA #$00
    STA !extended_num,y
.next
    DEY
    BPL .loop
    RTS

;---------------------------------------------------------------
; Plays appropriate teleport sound
;---------------------------------------------------------------
PlaySound:
    LDA #$25                   ; Teleport sound effect
    STA $1DF9|!Base2
    RTS