;Cursor by Blind Devil
;A sprite that can be controlled with the D-pad and can click stuff.
;It doesn't interact with objects, but detects screen limits to avoid going out of bounds,
;and depending on the extra bit and extra byte (Extension) configuration, it can spawn or kill sprites via clicking.
;It also freezes Mario in place.

;Extra bit options:
;clear = won't spawn invisible object interactable sprite.
;set = will spawn invisible object interactable sprite (useful for clickable custom blocks).

;Extension options:
;0 = cursor can kill sprites.
;1 = cursor can spawn a normal sprite.
;2 = cursor can spawn a custom sprite with extra bit clear.
;3 = cursor can spawn a custom sprite with extra bit set.
;4 = cursor can't kill or spawn sprites.
;5 = makes it an invisible object interactable sprite. Used internally by the cursor, so don't use it.

;stop 1337-asm-writing lul
;and please comment properly your codes - for your own and everyone else's good :3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Customizable defines below.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;TILEMAPS
;Here you define what tiles the cursor will use.
	!CursorTile = $C0	;tile used for the cursor.
	!CursorPress = $E0	;tile used for the cursor when clicking.

;BUTTON TO CLICK
;What button to use for clicking. Depending on the controller data address:
;RAM $16: $80=B, $40=Y, $20=Select, $10=Start. UDLR not recommended, as they're already used to move the cursor.
;RAM $18: $80=A, $40=X, $20=L, $10=R.
	!ClickButton = $10
	!ControllerData = $18;$16		;can only be $16 or $18!

;CURSOR SPEED
;Speed which the cursor should move when a button in the D-pad is pressed.
;Applies to all directions.
	!CursorSpd = $40
	!CameraSpdU = #$BF
	!CameraSpdD = #$40
	!CameraSpdL = #$C0
	!CameraSpdR = #$40

;CURSOR CLICK TIMER
;How long, in frames, to display the clicked cursor tile when the button is pressed.
;It also prevents multiple rapid-clicking during this time.
	!CursorTimer = $0C

;SPRITE TO SPAWN
;What normal or custom sprite to spawn depending on the extension byte.
	!NormalSprite = $0F
	!CustomSprite = $BE


;enable/disable cursor
	!CursorToggle = !1504,x ;$7FA00B

;original player pos
	!PlayerPosXLow 	 =         !1626,x ;$7FA00C ;!1558,x ;!1602,x
	!PlayerPosXHigh  =	      	$7FA00D
	!PlayerPosYLow	 =        	$7FA014
	!PlayerPosYHigh	 =        	$7FA015

	!PlayerSpeedX =				$7FA012
	!PlayerSpeedY =				$7FA013


;clone sprite index from pixi_list
	!CloneIndex =				$14
	!CloneSpawned =				$7FA010
	!DummyIndex =				$7FA011


;return tp speed
	!TeleportingSpeed = $40                 ; Speed the camera/teleport moves
	!Teleporting =				!187B,x		; #$00 if okay, #$01 if tping

;;;;;;;;;;;;;;;;;;;;;;;;;
;Sprite code starts here.
;;;;;;;;;;;;;;;;;;;;;;;;;
print "INIT ",pc
	LDA #$00
	STA !CursorToggle
	STA !Teleporting
	STA !CloneSpawned

	RTL

print "MAIN ",pc
	PHB : PHK : PLB : JSR SpriteCode : PLB : RTL : SpriteCode:

	LDA $1470|!Base2
	ORA $148F|!Base2                        ;  | don't allow cursor if you're carrying something
	BEQ .checkButton
	
	; carrying something
	;BRA .conditionsNotMet
	; .conditionsNotMet copied here since branch is too far
	
	; re-enable interaction w objects
	LDA #$00
	STA $185C|!Base2

	LDA #$00
	STA $13F9|!Base2	;reset mario to layer 1

	RTS


.checkButton
	LDA $18								    ;  | toggle cursor if you press L
	AND #$20                                ;  | 00100000 -> AXLR---- , so check if L pressed.
	BNE .switchState

	; L not pressed this frame but recently and needs to tp back
	LDA !Teleporting
	BNE .sendPlayerBack

	; L not pressed
	LDA !CursorToggle
	BNE .toMainCode	; L not pressed but cursor still toggled on

	
	; L not pressed and cursor toggled off
	BRA .conditionsNotMet






;if pressed:
.switchState

	LDA #$10			;load sound effect
	STA $1DF9|!Base2	;store to address to play it.

	LDA !CursorToggle
	BEQ .switchOn

.switchOff
	LDA #$01
	STA !Teleporting	; set to 1 to show that we need to tp back
	BRA .sendPlayerBack	; L was pressed during cursor, send player back

.switchOn
	LDA #$01
	STA !CursorToggle
	STA !CloneSpawned	;need clone to spawn
	BNE .markLocation	;switched on

	; switched off
.sendPlayerBack
	;send player back to when cursor was switched on

	JSR HidePlayer

	;keep dummy mario still
	PHX
	LDA !DummyIndex
	TAX
	STZ !B6,x
	STZ !AA,x
	PLX

	LDA !Teleporting
	BEQ +				; if 0, okay to skip
	JSR TeleportBack	; !Teleporting is #$00 if done teleporting
	LDA !Teleporting
	BNE +

	; If tp back finished, turn off cursor next cycle
	LDA #$00
	STA !CursorToggle

	; give back previous speed to player
	LDA !PlayerSpeedX
	STA $7B
	LDA !PlayerSpeedY
	STA $7D

	; remove dummy mario
	PHX
	LDA !DummyIndex
	TAX
	STZ !14C8,x
	PLX

+
	RTS

.toMainCode ;needed for branch distance
	BRA .mainCode

.markLocation	;switched on
	; save the player's position
	LDA $D1
	STA !PlayerPosXLow
	LDA $D2
	STA !PlayerPosXHigh
	LDA $D3
	STA !PlayerPosYLow
	LDA $D4
	STA !PlayerPosYHigh
	
	LDA $7B
	STA !PlayerSpeedX
	LDA $7D
	STA !PlayerSpeedY

	BRA .mainCode

.conditionsNotMet
	; re-enable interaction w objects
	LDA #$00
	STA $185C|!Base2

	LDA #$00
	STA $13F9|!Base2	;reset mario to layer 1

	RTS

.mainCode
	LDA $D1
	ADC #$04
	STA !E4,x                         ; fix the sprite's position to
	LDA $D2                           ; right on the player's
	STA !14E0,x
	LDA $D3
	STA !D8,x
	LDA $D4
	STA !14D4,x


	;Spawn Dummy Mario
	JSR SpawnClone

	;keep dummy mario still
	PHX
	LDA !DummyIndex
	TAX
	STZ !B6,x
	STZ !AA,x
	PLX

	JSR DrawGraphics	;draw graphics subroutine.

	JSR HidePlayer

; set mario's movement to nothing
	LDA #$00
	STA $7B
	STA $7D

	LDA !14C8,x		;load sprite status
	CMP #$08		;check if it's regular/active
	BNE MotherReturn	;if not equal, return.

	JSR Hover

	JSR Click		;subroutine that handles cursor clicking.

	;check if clicked
	LDA $02
	CMP #$FF
	BNE +
	LDA #$00
	STA !CursorToggle
	BRA MotherReturn

+
	JSR ScreenDetect	;subroutine that handles screen range detection.

	JSR Up			;more subroutines.
	JSR Down		;these handle cursor movement
	JSR Left		;depending on the
	JSR Right		;pressed D-pad button.

	LDA $15			;load controller data 1
	AND #$0C		;check if up or down buttons are pressed
	BNE +			;if any of them are pressed, branch ahead.

	STZ !AA,x		;reset sprite Y speed.

+
	LDA $15			;load controller data 1 again
	AND #$03		;check if left or right buttons are pressed
	BNE +			;if any of them are pressed, branch ahead.

	STZ !B6,x		;reset sprite X speed.

+
	JSL $01801A|!BankB	;update ypos no gravity
	JSL $018022|!BankB	;update xpos no gravity

MotherReturn:
	RTS

InvisibleSprite:
	JSL $019138|!BankB	;make sprite interact with objects (why it didn't interact even with the unchecked option in CFG is beyond me)

	LDA !15AC,x		;load sprite decrementer
	BNE +			;if not zero, return.

	STZ !14C8,x		;else erase itself.

+
	RTS			;return.

Up:
	LDA $15			;load controller data 1
	AND #$08		;check if up button is pressed
	BEQ .ret		;if not pressed, return.

	; Fix camera up?
	LDA #$01
	STA $1404|!Base2
	STA $1406|!Base2 

	LDA !151C,x		;load sprite address used for flags
	AND #$08		;check if bit is set (block upwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$0C		;mask up and down buttons - clear all other bits
	CMP #$0C		;check if both buttons are pressed at the same time
	BEQ .zero		;if they are, then zero speed. Done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	EOR #$FF		;flip all bits
	INC A			;increment A value by one
	STA !AA,x		;store to sprite's Y speed.

	; Move player Up
	LDA !CameraSpdU
	STA $7D

.ret
	RTS			;return.

.zero
	STZ !AA,x		;reset sprite Y speed.
	RTS			;return.

Down:

	LDA $15			;load controller data 1
	AND #$04		;check if down button is pressed
	BEQ .ret		;if not pressed, return.

	; Fix camera up?
	LDA #$01
	STA $1404|!Base2
	STA $1406|!Base2

	LDA !151C,x		;load sprite address used for flags
	AND #$04		;check if bit is set (block downwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$0C		;mask up and down buttons - clear all other bits
	CMP #$0C		;check if both buttons are pressed at the same time
	BEQ .zero		;if they are, then zero speed. Done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	STA !AA,x		;store to sprite's Y speed.

	; Move player Down
	LDA !CameraSpdD
	STA $7D

.ret
	RTS			;return.

.zero
	STZ !AA,x		;reset sprite Y speed.
	RTS			;return.

Left:
	LDA !151C,x		;load sprite address used for flags
	AND #$02		;check if bit is set (block leftwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1
	AND #$02		;check if left button is pressed
	BEQ .ret		;if not pressed, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$01		;check if right is pressed
	BNE .zero		;if it is pressed, then zero speed. done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	EOR #$FF		;flip all bits
	INC A			;increment A value by one
	STA !B6,x		;store to sprite's X speed.

	; Move player Left
	LDA !CameraSpdL
	STA $7B

.ret
	RTS			;return.

.zero
	STZ !B6,x		;reset sprite X speed.
	RTS			;return.

Right:
	LDA !151C,x		;load sprite address used for flags
	AND #$01		;check if bit is set (block rightwards)
	BNE .ret		;if yes, return.

	LDA $15			;load controller data 1
	AND #$01		;check if right button is pressed
	BEQ .ret		;if not pressed, return.

	LDA $15			;load controller data 1 again (double-checking)
	AND #$02		;check if left is pressed
	BNE .zero		;if it is pressed, then zero speed. done to avoid unintended behavior.

	LDA #!CursorSpd		;load speed value
	STA !B6,x		;store to sprite's X speed.

	; Move player Right
	LDA !CameraSpdR
	STA $7B

.ret
	RTS			;return.

.zero
	STZ !B6,x		;reset sprite X speed.
	RTS			;return.

Click:
	LDA !15AC,x		;load click decrementer
	BNE .ret		;if not zero, return.

	LDA $00
	CMP #$FF
	BEQ .hovered

.ret
	RTS			;return.

.hovered
	

	LDA #!CursorTimer	;load amount of frames
	STA !15AC,x		;store to decrementer.

	LDA !ControllerData	;load user-defined controller data address.
	AND #!ClickButton	;check input
	BNE .clicked		;if pressed, branch.

	RTS

.clicked
	;LDA #!CursorTimer	;load amount of frames
	;STA !15AC,x		;store to decrementer.

	LDA #$10			;load sound effect
	STA $1DF9|!Base2	;store to address to play it.

	PHX
	LDA $01
	TAX

	;set player to this clone's position
	LDA !E4,x
	STA $D1
	LDA !14E0,x
	STA $D2
	LDA !D8,x
	SEC : SBC #$20
	STA $D3
	LDA !14D4,x
	STA $D4

	;replace this clone by removing it
	STZ !14C8,x

	PLX

	LDA #$FF	;flag for clicked
	STA $02

	RTS
	


Hover:
	LDY #!SprSize-1		;loop count (loop though all sprite number slots)

.Loop
	PHX
	LDA !14C8,y		;load sprite status
	BEQ .LoopSprSpr		;if non-existant, keep looping.
	;CMP #$04		;check if spinjumped
	;BEQ .LoopSprSpr		;if equal, keep looping.

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
	CMP #!CloneIndex ;compare with clone index
	BNE .LoopSprSpr 	;if not clone, keep looping.
	PLX			;restore sprite index.

	JSL $03B6E5|!BankB	;get sprite A clipping (this sprite)
	PHX			;preserve sprite index
	TYX			;transfer Y to X
	JSL $03B69F|!BankB	;get sprite B clipping (interacted sprite)
	JSL $03B72B|!BankB	;check for contact
	BCC .LoopSprSpr		;if carry is set, there's contact, so branch.

	;LDA #$04		;load sprite state (spinjumped)
	;STA !14C8,x		;store to sprite state table.
	;LDA #$1F		;load value
	;STA !1540,x		;store to spinjumped sprite timer.

	;JSL $07FC3B|!BankB	;display spinjump stars
	;LDA #$10		;load sound effect
	;STA $1DF9|!Base2	;store to address to play it.
	LDA #$29
	STA $1DFC|!Base2
	
	; for use in Click
	LDA #$FF
	STA $00	;hovered flag

	TXA
	STA $01 ;clone selected index

	
	
	PLX			;restore sprite index
	RTS			;return.

.LoopSprSpr
	PLX			;restore sprite index
	DEY			;decrement loop count by one
	BPL .Loop		;and loop while not negative.
	RTS			;end? return.




;Sprite XY coordinates relative to screen calc subroutine + border detection
;This one you might find interesting! Feel free to rip lol

ScreenDetect:
JSR HorzDetect		;oh yeah
JSR VertDetect		;moar subroutines
RTS			;return.

HorzDetect:
LDA !14E0,x		;load sprite x-pos within level, high byte
XBA			;flip high/low bytes of A
LDA !E4,x		;load sprite x-pos within level, low byte (hooray we got the 16-bit coordinate in A now)
REP #$20		;16-bit A
SEC			;set carry
SBC $1A			;subtract layer 1 x-pos (A now holds sprite x-pos within the screen)

CMP #$0010		;compare A to value
BCC .blockleft		;if lower or equal, set flag to disable going left any further.
CMP #$00EF		;else compare again
BCC .resetbits		;if lower or equal, reset both bits. else it's higher, so we'll set flag to disable going right.

SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$01		;set bit to block going right
BRA .storebits		;branch ahead.

.blockleft
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$02		;set bit to block going left
BRA .storebits		;branch ahead.

.resetbits
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
AND #$FC		;mask bits - clear block left and block right bits
.storebits
STA !151C,x		;store result back.

LDA !B6,x		;load sprite X speed
BEQ .ret		;if equal zero, return.

STZ !B6,x		;reset sprite X speed.
.ret
RTS			;return.

VertDetect:
LDA !14D4,x		;load sprite y-pos within level, high byte
XBA			;flip high/low bytes of A
LDA !D8,x		;load sprite y-pos within level, low byte (hooray we got the 16-bit coordinate in A now)
REP #$20		;16-bit A
SEC			;set carry
SBC $1C			;subtract layer 1 y-pos (A now holds sprite y-pos within the screen)

CMP #$0010		;compare A to value
BCC .blockleft		;if lower or equal, set flag to disable going left any further.
CMP #$00CF		;else compare again
BCC .resetbits		;if lower or equal, reset both bits. else it's higher, so we'll set flag to disable going right.

SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$04		;set bit to block going down
BRA .storebits		;branch ahead.

.blockleft
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
ORA #$08		;set bit to block going up
BRA .storebits		;branch ahead.

.resetbits
SEP #$20		;8-bit A
LDA !151C,x		;load sprite address used for flags
AND #$F3		;mask bits - clear block up and block down bits
.storebits
STA !151C,x		;store result back.

LDA !AA,x		;load sprite Y speed
BEQ .ret		;if equal zero, return.

STZ !AA,x		;reset sprite Y speed.
.ret
RTS			;return.

;;;;;;;;;;;;;;;;;;;;;;;;
;Graphics routine below.
;;;;;;;;;;;;;;;;;;;;;;;;

DrawGraphics:
!XDisp = $02		;tile X displacement.
!YDisp = $02		;tile Y displacement.

%GetDrawInfo()

LDA $00			;get sprite X-pos from scratch RAM
CLC			;clear carry
ADC #!XDisp		;add X displacement
STA $0200|!Base2,y	;store to OAM.

LDA $01			;get sprite Y-pos from scratch RAM
CLC			;clear carry
ADC #!YDisp		;add Y displacement
STA $0201|!Base2,y	;store to OAM.

LDA !15AC,x		;load click timer
BNE +			;if not zero, branch.

LDA #!CursorTile	;load tile value (normal cursor)
BRA ++			;and branch ahead.
+

LDA #!CursorPress	;load tile value (pressed cursor)
++
STA $0202|!Base2,y	;store to OAM.

LDA !15F6,x		;load palette/properties from CFG
ORA $64			;set priority bits from level
STA $0203|!Base2,y	;store to OAM.

PHY			;preserve Y
TYA			;transfer Y to A
LSR #2			;divide by 2 twice
TAY			;transfer A to Y
LDA #$02		;load value (tile is set to 16x16)
ORA !15A0,x		;horizontal offscreen flag
STA $0420|!Base2,y	;store to OAM (new Y index).
PLY			;restore Y
RTS			;return.

;mind these OAM values and codes - they have the highest priority, so tiles will appear in front of other sprites and Mario as well.










;SpawnClone:
;	LDA !CloneSpawned	; if #$00, don't need clone spawned.
;	BEQ .ret
;
;	LDA #$FA		;load X offset
;	STA $00			;store to scratch RAM.
;	LDA #$F3		;load Y offset
;	STA $01			;store to scratch RAM.
;	;STZ $02 : STZ $03	;no XY speed
;	; dummy retains player's speed
;	LDA $7B
;	STA $02
;	LDA $7D
;	STA $03
;	;LDA !7FAB9E,x		;load this sprite's number
;	LDA #!CloneIndex	;load clone sprite's number (idx)
;	SEC				;set carry - spawn custom sprite
;	%SpawnSprite()
;	CPY #$FF		;check if sprite wasn't spawned
;	BEQ .ret		;if value is equal, return.
;
;	PHX			;preserve sprite index
;	TYX			;transfer index of generated sprite
;	LDA #$04		;load amount of frames to keep sprite alive
;	STA !15AC,x		;store to sprite decrementer.
;	LDA #$05		;load extension value
;	STA !7FAB40,x		;store to first extension byte.
;	PLX			;restore X
;
;	LDA #$00		; set to 0 to show clone was spawned
;	STA !CloneSpawned
;
;.ret
;	RTS			;return.








SpawnClone:
	LDA !CloneSpawned	; if #$00, don't need clone spawned.
	BEQ .ret

	LDA #$FC		;load X offset
	STA $00			;store to scratch RAM.
	LDA #$14		;load Y offset
	STA $01			;store to scratch RAM.
	;STZ $02
	;STZ $03	;no XY speed
	LDA !PlayerSpeedX
	STA $02
	LDA !PlayerSpeedY
	STA $03

	LDA !7FAB40,x		;load first extension bit
	CMP #$01		;compare to value
	BEQ normal		;if equal, spawn normal sprite.

	LDA #!CloneIndex	;load custom sprite number
	SEC			;set carry - spawn custom sprite
	%SpawnSprite()
	CPY #$FF		;check if sprite wasn't spawned
	BEQ .ret		;if value is equal, return.

	;LDA !7FAB40,x		;load first extension bit
	;CMP #$03		;compare to value
	;BNE .ret		;if not equal, don't set extra bit for it.

	PHX			;preserve sprite index
	TYX			;transfer index of generated sprite

	TXA
	STA !DummyIndex

	;LDA.w !7FAB10,x		;load extra bits of spawned sprite
	;ORA #$04		;set first extra bit

	;LDA !extra_byte_1,x
	;STA $00
	;LDA !extra_byte_2,x
	;STA $01
	;LDA !extra_byte_3,x
	;STA $02
;
	;LDY #$07
	;LDA #$87
	;STA [$00],y


	PLX			;restore X

	LDA #$00		; set to 0 to show clone was spawned
	STA !CloneSpawned

.ret
	RTS			;return.

normal:
	LDA #!NormalSprite	;load normal sprite number
	CLC			;set carry - spawn custom sprite
	%SpawnSprite()

TeleportBack:
	
	JSR SetTeleportingXSpeed                ; \  move the player to the other pipe
	JSR SetTeleportingYSpeed                ; /

	LDA $7B                                 ; \
	ORA $7D                                 ;  | if the player doesn't need to move anymore
	ORA $17BC|!Base2                        ;  | and the screen has caught up with them too,
	ORA $17BD|!Base2                        ;  | we're done teleporting
	BNE .return

	;stop teleporting
	LDA #$00
	STA !Teleporting
	
.return
	;keepTeleporting
	RTS

; determines where to move the player horizontally when teleporting

SetTeleportingXSpeed:

	LDA !PlayerPosXHigh                      ; \
	XBA                                     ;  | calculate the distance
	LDA.w !PlayerPosXLow                    ;  | between the player and the sprite
	REP #$20                                ;  |
	SEC : SBC $D1                           ;  |
	STA $00                                 ; /

	BPL + : EOR #$FFFF : INC : +            ; \
	CMP #$0008                              ;  |
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
+   STA $7B                                 ;  |
.return                                         ;  |
	RTS                                     ; /




; determines where to move the player vertically when teleporting

SetTeleportingYSpeed:

	LDA !PlayerPosYHigh
	XBA
	LDA !PlayerPosYLow
	REP #$20
	SEC : SBC $D3
	STA $00

	BPL + : EOR #$FFFF : INC : +
	
	CMP #$0008
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
+   STA $7D
.return
	RTS

HidePlayer:
; hide mario
	LDA #$FF
	STA $78

; disable interaction w objects
	LDA #$01
	STA $185C|!Base2

; move mario behind sprites, objects
	LDA #$02
	STA $13F9|!Base2

; pause sprites, animations
	LDA #$FF
	STA $9D

	RTS