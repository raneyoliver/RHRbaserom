
        ; NPCs (version 4.2 I guess)
        ; made in 2021-22 by WhiteYoshiEgg

        ; This is a sprite that doesn't hurt the player and doesn't interact with any other sprites.
        ; It can stay still, walk around, or jump, and also display a message if the player
        ; presses a button while touching it.

        ; It's compatible with SMW's regular message boxes (can use any message in any level
        ; and show up to two at once), the Message Box Expansion patch,
        ; and also the VWF Dialogues patch.

        ; The movement, graphics and message behavior are *highly* customizable.
        ; All the options are in the extra bytes (of which it uses all 12).
        ; This means you only need to have *one entry* in your sprite list
        ; and can fully customize it *as you place it in your level*!


        ; ### !!! HOW TO USE THIS !!! ###

        ; ##############################################################################################
        ; #                                                                                            #
        ; #  All the customization options are explained in HOW_TO_USE.html, so please refer to that!  #
        ; #  It also has a user-friendly configuration tool.                                           #
        ; #                                                                                            #
        ; ##############################################################################################


        ; You shouldn't need to handle the details yourself, but if you're interested,
        ; the extra byte usage is documented at the bottom of this file.



; definitions

;----------------------------------------------------------------------------------------------------------------------------------

; free ram start = 7F9C7B
; this uses $7FA007, $7FA008, $7FA009, $7FA00A

        !TeleportingSpeed = $7F                 ; Speed the camera/teleport moves
        !FreezeTimeWhenTeleporting = 1          ; 0 = no, 1 = yes
        !StopTeleportWithin = #$0010

        !State =                !1504,x
        !Timer =                !1528,x
        ;!TeleportReady =       !1534,x
        !PlayerPosXLow =        $7FA007 ;!1558,x ;!1602,x
        !PlayerPosXHigh =       $7FA008
        !PlayerSpeedX =         $7FA009
        !PlayerSpeedY =         $7FA00A
        !PlayerPosYLow =        !1626,x
        !PlayerPosYHigh =       !1534,x

        !CanStandOnIt = 0                       ; 1 = Mario can stand on the sprite
        !SolidSides = 0                         ; 1 = the sprite is solid from the sides


        ;  The below defines are used if !FreezeTimeWhenTeleporting is 1.
        ;  Due to an issue in timing, sprites may not properly freeze while using a pipe.
        ;  Setting !FixFreeze to 1 will fix this issue, in exchange for using one byte of free RAM.
        
        !FixFreeze              = 1               ; 0 = no, 1 = yes
        !FreezeRAM              = $1FFF|!Base2    ; 1 byte of free RAM.

        !DashSpeed = #$50                       ; Rightward Speed post-teleport
        !DashSpeedNegative = #$AF               ; Leftward Speed post-teleport
        !UpSpeed = #$9F                         ; Upward Speed post-teleport
        !DownSpeed = #$40                       ; Downward Speed post-teleport

if !FreezeTimeWhenTeleporting && !FixFreeze
    pushpc
    org $00A2E2 : JSL RestoreFreeze
    pullpc
        
    RestoreFreeze:
        LDA !FreezeRAM
        BEQ +
        STA $9D
        LDA #$00
        STA !FreezeRAM
      + JML $01808C|!BankB
else
    pushpc
    org $00A2E2 : JSL $01808C|!BankB
    pullpc
endif

;----------------------------------------------------------------------------------------------------------------------------------


        !NPCState               = !C2,x
        ;!JumpTimer              = !1540,x
        ;!WalkTimer              = !1540,x
        ;!IdleTimer              = !1558,x
        ;!MessageTimer           = !163E,x
        !LevelNumberBackup      = !1510,x ;!1504,x
        ;!PowerupGivenFlag       = !1602,x
        !Frame                  = !1570,x
        !SolidContactOccurred   = !187B,x

        !WalkingTopLeftTile     = $00
        !JumpingTopLeftTile     = $04
        !TalkingTopLeftTile     = $06



        ; if you have applied the Message Box Expansion patch,
        ; make sure these three definitions are the same as in message_box_expansion.asm
        ; (you probably don't need to change this)

        !MessageBoxState        = $1426|!addr
        !MessageBoxTimer        = $1B88|!addr
        !MessageToShow          = $1B89|!addr



        ; if you have applied the VWF Dialogues Patch, take note!

        ; - do you have version 1.3 (released in 2022) or newer?
        ;   if so, it comes with a file called "vwfsharedroutines.asm".
        ;   copy that file into PIXI's "sprites" folder to make sure that the VWF dialogs work as intended.
        ;   if you don't do that, the NPC sprite should work anyway, it's just not recommended.

        ; - do you have version 1.2 or older?
        ;   if so, don't worry, the NPC sprite still works!
        ;   just make sure these definitions below are the same as in vwfconfig.cfg.
        ;   (if you're not sure what that means, you probably don't need to do anything.)

        !varram                 = $702000 ; for all VWF Dialogues versions
        if read1($00A1DA|!BankB) != $5C
        !varramSA1              = $419000 ; for VWF Dialogues version 1.2
        else
        !varramSA1              = $415000 ; for VWF Dialogues version 1.3 and up
                                          ; (only used if the routine file can't be found)
        endif





; macros

;macro prepare_extra_bytes()
;        LDA !extra_byte_1,x                     ; \
;        STA $00                                 ;  | load extra byte address to into $00-$02
;        LDA !extra_byte_2,x                     ;  | (if there's more than 4 extra bytes, the addresses for 1-3
;        STA $01                                 ;  | actually serve as pointers to the real data)
;        LDA !extra_byte_3,x                     ;  |
;        STA $02                                 ; /
;endmacro
;
;macro load_extra_byte(num)
;        LDY #<num>-1                            ; \  I'm counting extra bytes from 1 to 12
;        LDA [$00],y                             ; /
;endmacro
;
;macro safe_JSL(addr)
;        JSL <addr>                              ; \  after JSLing to something that could mess with $00-$02,
;        %prepare_extra_bytes()                  ; /  make sure to set that back to the expected value afterwards
;endmacro





; try including shared routines for the VWF Dialogues patch version 1.3 and up

if read1($00A1DA|!BankB) == $5C
        if getfilestatus("vwfsharedroutines.asm") == 0
                incsrc "vwfsharedroutines.asm"
        else
                print "Using legacy code for VWF Dialogues patch. To get rid of this warning, copy 'vwfsharedroutines.asm' from the VWF patch to your 'sprites' folder."
        endif
endif





; init routine

print "INIT ",pc

        STZ !NPCState
        LDA $13BF|!addr
        STA !LevelNumberBackup

        LDA #$09
        STA !14C8,x

        RTL

; main routine

print "MAIN ",pc

        PHB : PHK : PLB : JSR SpriteCode : PLB : RTL : SpriteCode:

        LDA !Timer
        BEQ +
        DEC !Timer
+
        LDA $71      ;\ Skip everything and just draw graphics if Mario is dying.
        CMP #$09     ;|
        BEQ .return  ;/

        LDA $9D
        BNE .noCarry
        JSR HandleCarryableSpriteStuff
        BRA .noCarry
.noCarry
        ;JSR HandleState
        JSR HandleInteraction

        LDA $9D
        BNE .return

        JSR Stationary

.return
        ; set the "process when off-screen" flag
        LDA !167A,x
        ORA #$04   
        STA !167A,x

        JSR Graphics
        RTS

HandleState:

        LDA !State
        JSL $0086DF|!BankB
        dw .idle, .enteringPipe, .teleporting, .stalling, .exitingPipe



        ; state 00: idle (carryable and solid, waiting for player to enter)

.idle      
        JSR HandleInteraction                   ; \
        ;CPX !CurrentTeleportTarget              ;  | Only initiate if this was the last teleport sprite touched
        ;BNE ..notLastTarget                     ;  |           
        
        LDA $18								    ;  | initiate teleporting if you press R
        AND #$10                                ;  | 00010000 -> AXLR---- , so check if R pressed.
        BNE ..checkForCursor                  ; /
        RTS

..checkForCursor
        LDA $9D
        BEQ ..beginTeleporting
        RTS

;..notLastTarget
        ;RTS

..beginTeleporting

        LDA $94
        STA !PlayerPosXLow
        LDA $95
        STA !PlayerPosXHigh
        LDA $96
        STA !PlayerPosYLow
        LDA $97
        STA !PlayerPosYHigh

        LDA $7B
        STA !PlayerSpeedX
        LDA $7D
        STA !PlayerSpeedY

        LDA $1470|!Base2                        ; \
        ORA $148F|!Base2                        ;  | don't allow teleporting if you're carrying something

        BNE ..dontTeleport                      ; /

        LDA $1426|!Base2                        ; \  don't allow teleporting if a message box is active

        BNE ..dontTeleport                      ; /

        ;LDA !TeleportReady                      ; \ don't allow teleporting if the sprite is not touched yet
        ;BEQ ..dontTeleport                      ; /

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

        JSR EraseFireballs

        ; STZ $17C0|!Base2                      ; \
        ; STZ $17C1|!Base2                      ;  | erase all smoke sprites?
        ; STZ $17C2|!Base2                      ;  | (this doesn't seem to work)
        ; STZ $17C3|!Base2                      ; /

        LDA #$25                                ; \  play blargg roar
        STA $1DF9|!Base2                        ; / 

        ;LDA #$02                                ; \ all kinds of teleportation settings
        ;STA $13F9|!Base2                        ; /

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

        LDA #$08
        STA !Timer
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

        LDA !Timer
        BEQ ..nextState

        STZ $73                                 ; \
        ;STZ $7B                                 ;  |
        ;LDA #$01                                ;  | all kinds of teleportation settings
        ;STA $185C|!Base2                        ;  | (hiding the player, disabling interaction etc.)
        ;LDA #$02                                ;  |
        ;STA $13F9|!Base2                        ;  |
        if !FreezeTimeWhenTeleporting           ;  |
          LDA #$FF                              ;  |
          STA $9D                               ;  |
          if !FixFreeze                         ;  |
            STA !FreezeRAM                      ;  |
          endif                                 ;  |
        endif                                   ; /
        RTS

..nextState

        JSR EraseFireballs

        ;JSR SetTeleportingXSpeed
        ;JSR SetTeleportingYSpeed

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
        if !FreezeTimeWhenTeleporting           ;  |
          STA $9D                               ;  |
          if !FixFreeze                         ;  |
            STA !FreezeRAM                      ;  |
          endif                                 ;  |
        endif                                   ; /

        JSR SetTeleportingXSpeed                ; \  move the player to the other pipe
        JSR SetTeleportingYSpeed                ; /

        LDA $7B                                 ; \
        ORA $7D                                 ;  | if the player doesn't need to move anymore
        ORA $17BC|!Base2                        ;  | and the screen has caught up with them too,
        ORA $17BD|!Base2                        ;  | we're done teleporting
        BNE ..keepTeleporting                   ; /



..doneTeleporting
        

        LDA #$18                                ; \  play Thunder sound
        STA $1DFC|!Base2                        ; /

        LDA #$FF
        STA !Timer
        INC !State

..keepTeleporting
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
      ;+
        ;RTS


        ; state 04: "exiting pipe" animation

.exitingPipe

        LDA !Timer
        BEQ ..nextState

        ;LDA #$01                                ; \
        ;STA $185C|!Base2                        ;  | all kinds of teleportation settings
        ;LDA #$02                                ;  |
        ;STA $13F9|!Base2                        ;  |
        if !FreezeTimeWhenTeleporting           ;  |
          LDA #$FF                              ;  |
          STA $9D                               ;  |
          if !FixFreeze                         ;  |
            STA !FreezeRAM                      ;  |
          endif                                 ;  |
        endif                                   ;  |
        RTS                                     ; /

..nextState

        LDA.w !E4,x                             ; \
        STA $94                                 ;  | fix the player's position to
        LDA !14E0,x                             ;  | right on the sprite
        STA $95                                 ;  |
        LDA.w !D8,x                             ;  |
        SEC : SBC #$11                          ;  |
        STA $96                                 ;  |
        LDA !14D4,x                             ;  |
        SBC #$00                                ;  |
        STA $97                                 ; /

        ;also take sprite's speed
        LDA !B6,x
        STA $7B
        LDA !AA,x
        STA $7D

        LDA !PlayerPosXLow                             ; \
        STA !E4,x                                     ;  | fix the sprite's position to
        LDA !PlayerPosXHigh                           ;  | right on the player's previous
        STA !14E0,x                                   ;  |
        LDA !PlayerPosYLow                            ;  |
        ;SEC : SBC #$11                                ;  |

        ; don't add so much that it screen wraps
        CMP #$F9
        BCS +
        SEC : ADC #$5                                ;  |  sprite was too high without this
+
        STA !D8,x                                     ;  |
        LDA !PlayerPosYHigh                           ;  |
        ;SBC #$00                                      ;  |
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

        ;STZ !14C8,X                             ; Destroy the sprite after use once

        ;Set state back to idle
        LDA !State       ; Load the value of !State into the accumulator
        SEC              ; Set the carry flag to indicate subtraction
        SBC #$04         ; Subtract 4 from the value in the accumulator
        STA !State       ; Store the result back into !State

        BRA ..return

..return
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
        LDA #!TeleportingSpeed                  ;  |
        BRA +                                   ;  |
.negativeSpeed                                  ;  |
        LDA #-!TeleportingSpeed                 ;  |
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
        LDA #!TeleportingSpeed
        BRA +
.negativeSpeed
        LDA #-!TeleportingSpeed
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
;----------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------------------------

; extra bit set: walking
; DELETED

; extra bit clear: stationary

Stationary:

        ;%load_extra_byte(10)                    ; \
        ;AND #$01                                ;  |
        ;BEQ .dontFacePlayer                     ;  | face the player if set to
;.facePlayer                                     ;  |
        ;%SubHorzPos()                           ;  |
        ;TYA : STA !157C,x                       ;  |
.dontFacePlayer                                 ; /

        ;%load_extra_byte(10)                    ; \
        ;AND #$02                                ;  | don't jump if not set to
        ;BEQ .dontJump                           ; /
        ;LDA !1588,x                             ; \
        ;AND #$04                                ;  | don't jump if in the air
        ;BEQ .dontJump                           ; /

        ;LDA !JumpTimer                          ; \  only jump when the jump timer has expired
        ;BNE .dontJump                           ; /

        ;%load_extra_byte(10)                    ; \
        ;AND #$FC                                ;  |
        ;LSR                                     ;  | jump with the given height
        ;EOR #$FF : INC                          ;  |
        ;STA !AA,x                               ; /
        ;%load_extra_byte(11)                    ; \  reset the jump timer
        ;STA !JumpTimer                          ; /
        ;%load_extra_byte(12)                    ; \
        ;AND #$01                                ;  |
        ;BEQ .noSound                            ;  | play jump sound if set to
        ;db $A9 : db read1($00D65F)              ;  |
        ;db $8D : dw read2($00D661)              ; /
.noSound

.dontJump

        LDA !1588,x
        AND #$04
        BEQ +
        JSR SetFrameWalking1
        BRA ++
+       JSR SetFrameJumping
++
        ;%safe_JSL($01802A|!BankB)               ;    update position with gravity
        RTS





; message box handling
; DELETED

; graphics routine

Graphics:

        ;%prepare_extra_bytes()

        ;%load_extra_byte(7)                     ; \
        ;BPL .notInvisible                       ;  | skip the graphics routine
        ;RTS                                     ;  | if the sprite is set to be invisible
.notInvisible                                   ; /

        ; set up properties byte

        LDA !157C,x                             ; \
        AND #$01                                ;  |
        EOR #$01                                ;  | set the x flip bit based on direction
        ROR #3                                  ;  |
        STA $03                                 ; /
        ;%load_extra_byte(8)                     ; \
        ;BPL .defaultPalette                     ;  |
        LDA #$01        ;palette 8?
        ;AND #$70                                ;  | use a custom palette row if set to
        ;LSR #3                                  ;  |
        ;BRA +                                   ;  |
.defaultPalette                                 ;  |
;        LDA #$0C                                ;  |
        TSB $03                                 ; /
        ;AND #$01


        ;%load_extra_byte(7)
        ;AND #$30
        ;CMP #$30 : BEQ .32x32
        ;CMP #$10 : BEQ .16x16

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



;.16x16
;
;        %GetDrawInfo()
;
;        LDA $00
;        STA $0300|!Base2,y
;        LDA $01
;        STA $0301|!Base2,y
;        LDA !Frame
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        LDY #$02
;        LDA #$00
;        JSL $01B7B3|!BankB
;
;        RTS
;
;
;
;.32x32
;
;        %GetDrawInfo()
;
;        LDA !157C,x
;        BNE + : JMP ..right : +
;
;..left
;
;        LDA $00
;        SEC : SBC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        SEC : SBC #$10
;        STA $0301|!Base2,y
;        LDA !Frame
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        INY #4
;
;        LDA $00
;        SEC : SBC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        STA $0301|!Base2,y
;        LDA !Frame
;        CLC : ADC #$20
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        INY #4
;
;        LDA $00
;        CLC : ADC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        SEC : SBC #$10
;        STA $0301|!Base2,y
;        LDA !Frame
;        CLC : ADC #$02
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        INY #4
;
;        LDA $00
;        CLC : ADC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        STA $0301|!Base2,y
;        LDA !Frame
;        CLC : ADC #$22
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        JMP +
;
;..right
;
;        LDA $00
;        SEC : SBC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        SEC : SBC #$10
;        STA $0301|!Base2,y
;        LDA !Frame
;        CLC : ADC #$02
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        INY #4
;
;        LDA $00
;        SEC : SBC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        STA $0301|!Base2,y
;        LDA !Frame
;        CLC : ADC #$22
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        INY #4
;
;        LDA $00
;        CLC : ADC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        SEC : SBC #$10
;        STA $0301|!Base2,y
;        LDA !Frame
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;        INY #4
;
;        LDA $00
;        CLC : ADC #$08
;        STA $0300|!Base2,y
;        LDA $01
;        STA $0301|!Base2,y
;        LDA !Frame
;        CLC : ADC #$20
;        STA $0302|!Base2,y
;        LDA #$31
;        ORA $03
;        STA $0303|!Base2,y
;
;+
;
;        LDY #$02
;        LDA #$03
;        JSL $01B7B3|!BankB
;
;        RTS





; show smoke

Smoke:

        LDY #$03
.loop
        LDA $17C0|!addr,y
        BEQ .break
        DEY
        BPL .loop
        RTS
.break
        LDA #$01
        STA $17C0|!addr,y
        LDA #$1B
        STA $17CC|!addr,y
        LDA !D8,x
        STA $17C4|!addr,y
        LDA !E4,x
        STA $17C8|!addr,y
        RTS



; routines that set the current animation frame
; (called at various places)

; if the corresponding "use custom frame" bit isn't set it uses the default value,
; otherwise it uses the tile given in the extra bytes.

; the format in the extra bytes is "top left corner in SP3/4, aligned to 16x16 tiles"
; (0 is the first 16x16 tile, 1 is the 16x16 tile next to it, and 3F is the very last 16x16 tile.)
; this is so everything fits into 6 bits.
; there's a few bitwise shenanigans going on to convert that to an actual tile number,
; and the conversion is slightly different for each one because they're at different positions within a byte.

; the tile specified is the top one (if the sprite is not 16x16, the other is always one below that).
; the "custom walking frame" setting has two tiles (the second frame is one to the right, or two for 32x32 sprites).

SetFrameWalking:

;        %load_extra_byte(8)                     ; \
        LDA #$87
        AND #$03                                ;  |
        TAY                                     ;  | slow down the frame counter
        LDA $14                                 ;  | depending on the given walk animation speed
        LSR                                     ;  |
        CPY #$00 : BEQ +                        ;  |
        LSR                                     ;  |
        DEY : BEQ +                             ;  |
        LSR                                     ;  |
        DEY : BEQ +                             ;  |
        LSR                                     ; /
+       AND #$01
        BEQ +
        JSR SetFrameWalking1
        BRA ++
+       JSR SetFrameWalking2
++      RTS



SetFrameWalking1:

        ;%load_extra_byte(5)
        ;BPL .default
        ;AND #$3F
        ;LSR #2
        ;AND #$FE
        ;ASL #4
        ;STA !Frame
        ;%load_extra_byte(5)
        ;AND #$3F
        ;ASL
        ;AND #$0F
        ;CLC : ADC !Frame
        ;STA !Frame
        ;RTS
.default
        LDA #!WalkingTopLeftTile
        STA !Frame
        RTS



SetFrameWalking2:

        ;%load_extra_byte(5)
        ;BPL .default
        ;AND #$3F
        ;LSR #2
        ;AND #$FE
        ;ASL #4
        ;STA !Frame
        ;%load_extra_byte(5)
        ;AND #$3F
        ;ASL
        ;AND #$0F
        ;CLC : ADC !Frame
        ;CLC : ADC #$02
        ;BRA +
.default
        LDA #!WalkingTopLeftTile+2
+       STA !Frame

        ;%load_extra_byte(7)                     ; \
        ;AND #$30                                ;  |
        ;CMP #$30                                ;  | if the sprite is 32x32,
        ;BNE +                                   ;  | move the second frame one tile over
        ;LDA !Frame                              ;  |
        ;CLC : ADC #$02                          ;  |
        ;STA !Frame                              ;  |
+       RTS                                     ; /



SetFrameJumping:

        ;%load_extra_byte(12)
        ;BPL .default
        ;AND #$7E
        ;LSR #3
        ;AND #$FE
        ;ASL #4
        ;STA !Frame
        ;%load_extra_byte(12)
        ;AND #$0E
        ;CLC : ADC !Frame
        ;STA !Frame
        ;RTS
.default
        LDA #!JumpingTopLeftTile
        STA !Frame
        ;%load_extra_byte(7)                     ; \
        ;AND #$30                                ;  |
        ;CMP #$30                                ;  | if the sprite is 32x32,
        ;BNE +                                   ;  | move the default jumping frame two tiles over
        ;LDA !Frame                              ;  |
        ;CLC : ADC #$04                          ;  |
        ;STA !Frame                              ;  |
+       RTS                                     ; /



;SetFrameTalking:
;
;        %load_extra_byte(5)
;        AND #$40
;        BEQ .default
;        %load_extra_byte(6)
;        AND #$FC
;        LSR #5
;        AND #$FE
;        ASL #5
;        STA !Frame
;        %load_extra_byte(6)
;        LSR
;        AND #$1E
;        CLC : ADC !Frame
;        STA !Frame
;        RTS
;.default
;        LDA #!TalkingTopLeftTile
;        STA !Frame
;        %load_extra_byte(7)                     ; \
;        AND #$30                                ;  |
;        CMP #$30                                ;  | if the sprite is 32x32,
;        BNE +                                   ;  | move the default talking frame three tiles over
;        LDA !Frame                              ;  |
;        CLC : ADC #$06                          ;  |
;        STA !Frame                              ;  |
;+       RTS                                     ; /



; "solid sprite" routine
; adapted from https://www.smwcentral.net/?p=section&a=details&id=9571
; (check that for a commented version)

;SolidContact:

        ;STZ !SolidContactOccurred

        ;%load_extra_byte(7)                     ; \
        ;AND #$30                                ;  | set up "sprite clipping A" values
        ;CMP #$30 : BEQ .32x32                   ;  | depending on size
        ;CMP #$10 : BEQ .16x16                   ; /

;.16x32
;        LDA !E4,x
;        STA $04
;        LDA !14E0,x
;        STA $0A
;        LDA !14D4,x
;        XBA
;        LDA !D8,x
;        REP #$20
;        SEC : SBC #$0010
;        SEP #$20
;        STA $05
;        XBA
;        STA $0B
;        LDA #$10
;        STA $06
;        LDA #$20
;        STA $07
;        BRA +

;.16x16
;        LDA !E4,x
;        STA $04
;        LDA !14E0,x
;        STA $0A
;        LDA !D8,x
;        STA $05
;        LDA !14D4,x
;        STA $0B
;        LDA #$10
;        STA $06
;        STA $07
;        BRA +

;.32x32
;        LDA !14E0,x
;        XBA
;        LDA !E4,x
;        REP #$20
;        SEC : SBC #$0008
;        SEP #$20
;        STA $04
;        XBA
;        STA $0A
;        LDA !14D4,x
;        XBA
;        LDA !D8,x
;        REP #$20
;        SEC : SBC #$0010
;        SEP #$20
;        STA $05
;        XBA
;        STA $0B
;        LDA #$20
;        STA $06
;        STA $07
;
;+
;        JSL $03B664|!BankB
;
;        JSL $03B72B|!BankB
;        BCS .contact
;        RTS

;.contact
;
;        JSR Get_Solid_Vert
;        LDY $187A|!Base2
;        LDA $0F
;        CMP .heightReq,y
;        BCS .decideDownOrSides
;        BPL .decideDownOrSides
;
;        INC !SolidContactOccurred
;
;        LDA #$01
;        STA $1471|!Base2
;
;        %prepare_extra_bytes()                  ; \
;        %load_extra_byte(6)                     ;  |
;        AND #$02                                ;  | if the sprite is set to be rideable,
;        BEQ .dontRide                           ;  | move the player along when they're on top of it
;.ride                                           ;  | (taken from imamelia's mega mole disassembly)
;        LDY #$00                                ;  |
;        LDA $1491|!Base2                        ;  |
;        BPL .rightXOffset                       ;  |
;        DEY                                     ;  |
;.rightXOffset                                   ;  |
;        CLC                                     ;  |
;        ADC $94                                 ;  |
;        STA $94                                 ;  |
;        TYA                                     ;  |
;        ADC $95                                 ;  |
;        STA $95                                 ;  |
;.dontRide                                       ; /
;
;        LDA #$E1
;        LDY $187A|!Base2
;        BEQ .noYoshi
;        LDA #$D1
;.noYoshi
;        CLC
;        ADC $05
;        DEC
;        STA $96
;        LDA $0B
;        ADC #$FF
;        STA $97
;
;        RTS
;
;.heightReq
;        db $D4,$C6,$C6
;
;.decideDownOrSides
;        LDA $0A
;        XBA
;        LDA $04
;        REP #$20
;        SEC
;        SBC #$000C
;        CMP $D1
;        SEP #$20
;        BCS .horzCheck
;
;        REP #$20
;        CLC
;        ADC #$0008
;        STA $0C
;        SEP #$20
;
;        LDA $0C
;        CLC
;        ADC $06
;        STA $0C
;        LDA $0D
;        ADC #$00
;        STA $0D
;        REP #$20
;        LDA $0C
;        CMP $D1
;        SEP #$20
;        BCC .horzCheck
;
;        LDA $7D
;        BPL .noContact
;
;        LDA #$08
;        STA $7D
;
;        INC !SolidContactOccurred
;
;        RTS
;
;.horzCheck
;        JSR Get_Solid_Horz
;        LDA $0F
;        BMI .marioLeft
;
;        SEC
;        SBC $06
;        BPL .noContact
;
;        INC !SolidContactOccurred
;
;        LDA $04
;        CLC
;        ADC $06
;        STA $0C
;
;        LDA $0A
;        ADC #$00
;        STA $0D
;
;        REP #$20
;        LDA $0C
;        DEC
;        DEC
;        STA $94
;        SEP #$20
;
;        LDA $7B
;        BPL .noContact
;        STZ $7B
;
;        RTS
;
;.marioLeft
;
;        CLC
;        ADC #$10
;        BMI .noContact
;
;        INC !SolidContactOccurred
;
;        LDA $04
;        SEC
;        SBC #$0D
;        STA $0C
;
;        LDA $0A
;        SBC #$00
;        STA $0D
;
;        REP #$20
;        LDA $0C
;
;        DEC     ; I added this line to prevent the player "sticking" to the left side of the sprite
;                ; (originally, when you touched the left edge and started moving left,
;                ; you'd need to build up some speed for about half a second before actually moving away)
;                ; does it have side effects? who knows
;
;        STA $94
;        SEP #$20
;
;        LDA $7B
;        BMI .noContact
;        STZ $7B
;
;.noContact
;        RTS
;Get_Solid_Vert:
;        LDY #$00
;        LDA $D3
;        SEC
;        SBC #$10
;        SBC $05
;        STA $0F
;        LDA $D4
;        SBC $0B
;        BPL .marioLower
;        INY
;.marioLower
;        STY $0E
;        RTS
;
;Get_Solid_Horz:
;        LDY #$00
;        LDA $D1
;        SEC
;        SBC $04
;        STA $0F
;        LDA $D2
;        SBC $0A
;        BPL .marioRight
;        INY
;.marioRight
;        STY $0E
;        RTS



; the code below is mostly copied from RussianMan's Key disassembly (thanks!)
; Currently set to not ever alter Mario's speed.

HandleCarryableSpriteStuff:

        LDA !14C8,x
        CMP #$0B
        BEQ .carried
.notCarried
        JSL $019138|!BankB
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

        ;STX !CurrentTeleportTarget            ; Assign this sprite as the most recently carried version
        ;LDA #$01
        ;STA !TeleportReady
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


        ; EXTRA BYTE DOCUMENTATION

        ; extra bytes are counted from 1 to 12; bit 0 is the least significant bit.

        ; extra bytes 1-9 are shared, extra bytes 10-12 have different behavior
        ; depending on whether the sprite is stationary (extra bit clear) or walking (extra bit set).


        ; EXTRA BYTE 1
        ; bits 6-7: message to show (0 = none, 1 = message 1, 2 = message 2, 3 = both 1 and 2 in succession)
        ; bit 5:    show a VWF message (overrides number of messages)
        ; bit 4:    "disappear after talking" flag
        ; bit 3:    "different talking animation frame" flag
        ; bits 1-2: powerup to give the player after showing the message (0 = none)
        ; bit 0:    "give powerup only once per level" flag

        ; EXTRA BYTE 2
        ;           VWF message number (high byte)

        ; EXTRA BYTE 3
        ;           VWF message number (low byte)

        ; IF MESSAGE BOX EXPANSION PATCH IS NOT INSTALLED

                ; EXTRA BYTE 4
                ; bit 7:    "use message from another level" flag
                ; bits 0-6: level number to use message from ($13BF format)

        ; IF MESSAGE BOX EXPANSION PATCH IS INSTALLED

                ; EXTRA BYTE 4
                ;           number of message to show (=number of entry in message_list.asm, starting from 1, plus 6)

        ; EXTRA BYTE 5
        ; bit 7:    "use custom walking frames" flag
        ; bit 6:    "use custom talking frame" flag
        ; bits 0-5: custom walking frames (top left corner of the frame in SP3/4, aligned to 16x16 tiles)

        ; EXTRA BYTE 6
        ; bits 2-7: custom talking frame (top left corner of the frame in SP3/4, aligned to 16x16 tiles)
        ; bit 1:    "rideable" flag (only applies if "solid to player" flag is set")
        ; bit 0:    "solid to player" flag

        ; EXTRA BYTE 7
        ; bit 7:    "invisible" flag
        ; bit 6:    "set player pose" flag
        ; bits 4-5: sprite size (1 = 16x16, 2 = 16x32, 3 = 32x32)
        ; bits 0-3: button to press to show a message (index to a table with the actual bits and address)

        ; EXTRA BYTE 8
        ; bit 7:    "use custom palette row" flag
        ; bits 4-6: custom palette row
        ; bit 3:    "teleport after showing message" flag
        ; bit 2:    "play sound when showing message" flag
        ; bits 0-1: walk animation speed (0 = fast, 3 = slow)

        ; EXTRA BYTE 9
        ; bit 7:    "play jump sound when jumping while against a wall" flag
        ; bits 0-6: walking speed

        ; FOR STATIONARY SPRITES (EXTRA BIT CLEAR)

                ; EXTRA BYTE 10
                ; bits 2-7: jump height
                ; bit 1:    "jump" flag
                ; bit 0:    "face player" flag

                ; EXTRA BYTE 11
                ;           time between jumps

                ; EXTRA BYTE 12
                ; bit 7:    "use custom jumping frame" flag
                ; bits 1-6: custom jumping frame (top left corner of the frame in SP3/4, aligned to 16x16 tiles)
                ; bit 0:    "play jump sound" flag

        ; FOR WALKING SPRITES (EXTRA BIT SET)

                ; EXTRA BYTE 10
                ; bit 7:    "stay on ledges" flag
                ; bit 6:    "walk indefinitely" flag
                ; bit 5:    initial direction
                ; bit 4:    "follow player" flag (overrides "stay on ledges" flag)
                ; bit 3:    "jump when against a wall" flag
                ; bits 0-2: jump height when against a wall (index to a table with 8 sensible values)

                ; EXTRA BYTE 11
                ;       walk time

                ; EXTRA BYTE 12
                ;       idle time
