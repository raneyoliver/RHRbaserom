; Base: swooper block by TheBourgyman. 
; Minor modifications by SJandCharlieTheCat
; With help from binavik and spoons

; Note that because this spawns the koopa "smush" sprite after it's hit from above,
; you probably shouldn't just suspend these blocks in midair without
; a solid surface under them - otherwise it'll fall down and look kinda weird.

!fireballcoin = 0		; Set to 1 to have the block spawn a coin when killed by a fireball.

!SpinJumpTinyBounce = $F5 ; default value was $F4
!LowVerticalBounce = $C8 ; default value was $CC
!NumPixelsAboveSpriteRequiredToBounce =     $02
!KoopaNumber = $01 
!CloneSpriteNumber = $14

!CloneLowBounce =           $E6
!CloneHighBounce =          $AA 
!CloneHighSpin =            $FC
!CloneLowSpin =             $FE
!CloneJumpHeld =        $7FA018
!CloneSpinning =        $7FA00C
!CloneContact =         $7FA01C

print "A block that acts like a stationary Swooper."

db $42

JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside

Bounce:
    LDA !CloneContact             ;#$01 if clone bounce (SpriteV)
    BNE .cloneBounce

.marioBounce
    %stomped_points()	; Give points to the player.
    %erase_block()		; Erase block.

    LDA $140D|!addr		; Check if Mario is spin jumping.
    ORA $187A|!addr		; Check if Mario is riding Yoshi.
    BNE Crush			; If he does one of those things, go to crush.
    LDA #!LowVerticalBounce			; Give low vertical up speed to player.
    BIT $15				; Test controller bits.
    BPL +				; Skip ahead if the player is not holding A or B.
    LDA #$A6			; Give high vertical up speed to player.
+
    STA $7D
    BRA .finish

.cloneBounce
    %sprite_block_position()    ;| Update the position
	                            ;| of the block
	                            ;| so it doesn't react to
	                            ;| where the players at

    %stomped_points()	; Give points to the player.
    %erase_block()		; Erase block.

    LDA !CloneSpinning		    ; Check if Clone is spin jumping.
    BNE Crush			; If he is, go to crush.

    LDA !CloneJumpHeld
    BEQ .low				            ; Skip ahead if the player is not holding A or B.

.high
    LDA #!CloneHighBounce			; Give high vertical up speed to player.
    STA !AA,x
    BRA .no_spawn

.low
    LDA #!CloneLowBounce			; Give low vertical up speed to clone.
    STA !AA,x
    BRA .no_spawn

.finish
    LDA #!KoopaNumber
    CLC
    %spawn_sprite()
    BCS .no_spawn
    TAX
    %move_spawn_into_block()

    LDA #$03 ; state, smushed
    STA !14C8,x
    LDA #$20
    STA.w !1540,X
    STZ !B6,x
    STZ !AA,x

    ; need add %create_smoke() after disappear
	
.no_spawn
    LDA !CloneContact
    BNE .no_graphic
    
    JML $01AB99|!bank	; Write the contact graphics for the spin jump.
    RTL
    
.no_graphic
    LDA #$00
    STA !CloneContact
    RTL

Crush:
    LDA !CloneContact
    BNE .cloneCrush

.marioCrush
    LDA $187A|!addr		; Check again if Mario is riding Yoshi.
    BEQ .NoYoshi		; If he's not, go to noYoshi.
	%create_smoke()     ; added by SJC
    LDA #!LowVerticalBounce			; Give low vertical up speed to player.
    BIT $15				; Test controller bits
    BPL +				; Continue if holding A/B
    LDA #$A6			; Give high vertical up speed to player.
+	STA $7D
    BRA .CrushEnd

.cloneCrush
    %create_smoke()     ; added by SJC
    LDA !CloneJumpHeld
    BEQ .low

.high
    LDA #!CloneHighSpin
    STA !AA,x
    BRA .finish
.low
    LDA #!CloneLowSpin
    STA !AA,x

.finish
    LDA #$00
    STA !CloneContact
    BRA .CrushEnd

.NoYoshi
    LDA #!SpinJumpTinyBounce
    STA $7D				; Give very low vertical up speed to player.
.CrushEnd
    %create_smoke()     ; added by SJC
	LDA #$08			; Play sound "Enemy defeated by a spin jump".
	STA $1DF9|!addr
    %sprite_block_position()
	JML $01AB99|!bank	; Write the contact graphics for the spin jump.
    JSL $07FC3B|!bank   ; Crushed stars effect
	
MarioSide:				; Make the block's hitbox similar to how muncher's behave.

    REP #$20			; Make A 16 bit.
    LDA $9A				; Check the collision X position currently being processed.
    AND #$FFF0			; Remove the four lowest bits (00-0F).
    SEC
    SBC #$000E			; Subtract 000E.
    CMP $94				; Compare with the value in $94 (Player's X position within the level)
    BCC +			; If the carry is still set, Return.

    SEP #$20			; Make A 8 bit.
    RTL

+
    CLC					; Clear carry.
    ADC #$001A			; Add 1A.
    CMP $94
    BCS ++			; If the carry is clear, Return.

    SEP #$20			; Make A 8 bit.
    RTL

++
    SEP #$20
    
    LDA $1490|!addr		; Check if Mario has a star.
    ORA $13ED|!addr		; Check if Mario is landing with a cape, or sliding.
    BNE Star2			; If he does, ignore the modified hitbox below.
    
    LDA $72				; Check if Mario is in the air.
    ORA $187A|!addr		; Check if Mario is riding Yoshi.
    BEQ Damage2			; If touching the sides while on the ground and not riding Yoshi, damage.

TopCorner:
MarioAbove:
    LDA $1490|!addr		; Check if Mario has a star.
    ORA $13ED|!addr		; Check if Mario is landing with a cape, or sliding.
    BNE Star			; If he does, destroy block.

    LDA #$00
    STA !CloneContact

    JMP Bounce			; If not, go to bounce.
    
SpriteV:
    LDA !7FAB9E,x
    CMP #!CloneSpriteNumber            ; Check for Clone
    BNE Return

    LDA #$01
    STA !CloneContact

;    JSR CheckIfMarioSpriteOnTop
;    BMI .dontBounce

    JMP Bounce

;.dontBounce
;    JSL KillMarioSpriteAndExit

SpriteH:
    LDA !7FAB9E,x
    CMP #!CloneSpriteNumber            ; Check for Clone
    BNE .normal

    LDA #$01
    STA !CloneContact

;    JSR CheckIfMarioSpriteOnTop
;    BMI .dontBounce

    JMP Bounce

;.dontBounce
;    JSL KillMarioSpriteAndExit

.normal
    LDA !9E,x			; Load the sprite's number.
    CMP #$53			; Check for throw block.
    BEQ +				; Skip ahead if it is.
    CMP #$11			; Check for Koopa, Goomba and Bob-Omb (also keyhole, but that won't have any effect)
    BCS Return			; If not any of them, return.
    LDA !14C8,x			; Check the state of the sprite.
    CMP #$09			; Is it stationary/carryable?
    BCC Return			; If not, return.
+	%sprite_block_position()	; Run routine to check which block to destroy.
    %row_points()		; Give points to the player.
    %erase_block()		; Erase block.
    %create_smoke()		; Create smoke effect.
    LDA !14C8,x			; Check the state of the sprite again.
    CMP #$0B			; Is the sprite currently being carried?
    BNE Return			; If not, return.
    LDA #$02
    STA !14C8,x			; KIll the sprite.
    LDA #$D0
    STA !AA,x			; Give some upward speed to make the sprite bounce after dying.
    LDA $7B
    STA !B6,x			; Give it Mario's X speed after dying.
    RTL
    
Star2:
    BRA Star

Return2:
    BRA Return
    
Damage2:
    BRA Damage

MarioFireball:
    STZ $170B|!addr,x	; Remove fireball making contact.
if !fireballcoin	
    LDA #$21
    CLC
    %spawn_sprite()
	BCS +
    %move_spawn_into_block()
    LDA #$D0
    STA $AA,x
+ 
endif
    
MarioCape:
    %hundred_points()	; Give points to the player.
    BRA Poof
Star:
    %star_points()		; Give points to the player.
Poof:
    %erase_block()		; Erase block.
    %create_smoke()		; Create smoke effect.
    
Return:
    SEP #$20			; Make A 8 bit.
    RTL

HeadInside:
    REP #$20			; Make A 16 bit.
    LDA $9A				; Check the collision X position currently being processed.
    AND #$FFF0			; Remove the four lowest bits (00-0F).
    SEC
    SBC #$000E			; Subtract 000E.
    CMP $94				; Compare with the value in $94 (Player's X position within the level)
    BCS Return			; If the carry is still set, Return.
    CLC	
    ADC #$001A			; Add 1A with carry.
    CMP $94				; Compare with $94.
    BCC Return			; If the carry is clear, Return.
    SEP #$20			; Make A 8 bit.


MarioBelow:
    LDA $187A|!addr		; Check if Mario is riding Yoshi.
    BNE Return			; Return if he does.
    
BodyInside:
    LDA $1490|!addr		; Check if Mario has a star.
    ORA $13ED|!addr		; Check if Mario is landing with a cape, or sliding.
    BNE Star			; If he does, destroy block.
    LDA $1497|!addr		; Check if Mario has i-frames.
    BNE Return			; Return if he does.
    LDA $187A|!addr		; Check if Mario is riding Yoshi.
    BEQ Damage			; Go to Damage if not the case.
    LDX $18DF|!addr		; Get Yoshi's sprite slot plus 1.
    DEX					; Decrement to get the actual slot.
    BEQ Damage			; Return if for some reason, Yoshi is not found.

if !sa1					; Code stolen from Koopster. If Mario rides Yoshi, lose him when touching the block, instead of just dying.
    REP #$20
    TXA					; Koopster: "sa-1 uses pointers in certain sprites rather than the addresses themselves
    CLC					; due to spacing issues. this code stores the y position address to the
    ADC #$3216			; pointer that the code we'll jslrts to uses. due to using jslrts rather
    STA $CC				; than rewriting the routine, this workaround is needed".
    SEP #$20
endif
    
    PEA $01|(PushReturn>>16<<8)	; Push current bank then bank $01.
    PLB					; Pull $01 to data bank register.
    
    PHK
    PEA PushReturn-1
    PEA $80CA-1			; Koopster: "jslrts to yoshi runs away routine to force it to happen".
    JML $01F70E|!bank
    
PushReturn:				; Restore our data bank register.
    PLB
    
Damage:
    PHY
    JSL $00F5B7|!bank	; Hurt subroutine.
    PLY
    RTL
	
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
    RTS

KillMarioSpriteAndExit:
    LDA #$03
    STA !14C8,x
    RTL

	print "Block version of an immobile koopa. Place it on a 1F0 or sprite-only block to give the illusion that it's a sprite. Will also spawn the actual 'smushed' koopa when jumped on from above."