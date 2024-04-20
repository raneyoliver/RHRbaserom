
if read1($00FFD5) == $23		; check if the rom is sa-1
	sa1rom
	!SA1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000
	!bankA = $400000
else
	lorom
	!SA1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!bankA = $7E0000
endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Based on Flying Disco Shell by RussianMan in place of a disassembly
;This shell acts like normal except for requiring
;a spin jump to bounce off of
;
;Uses the spiny graphics for the top half of the shell by default
;(SP4 02)
;
;by dtothefourth
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;!Init =             !1626,x ;flag if INIT was run

!Frozen =           $41A021 ;from npc2.asm
!WasFrozen =        !1510,x

!SpeedXY =          !1504,x
!State =            !1534,x
!CloneSpinning =        $41A00C ;free ram for !Spinning in npc2.asm
!CloneIndex =       !1FD6,x

!CloneSpriteNumber =    $14

; X speed when kicked sideways by Mario.
!KickXSpeed         = $2E
!KickNoInteractTime = $10

; SFX that plays when kicking the sprite.
!KickedSFX          = $03
!KickedSFXAddr      = $1DF9|!addr

!MaxRightSpeed = $20
!MaxLeftSpeed = $E0

WallBumpSpeed:
db !MaxLeftSpeed,!MaxRightSpeed

TilemapUL:
db $40,$46,$44,$42
    ;db $80,$82,$80,$82

TilemapDL:
db $50,$56,$54,$52
    ;db $9E,$9A,$9C,$9A

Print "INIT ",pc
LDA #$09
STA !14C8,x
STA !State

LDA #$00
STA !WasFrozen

;LDA #$69
;STA !Init

RTL

Print "MAIN ",pc
PHB
PHK
PLB
JSR Code
PLB
RTL

Code:
;LDA !Init
;CMP #$69
;BEQ +

; disable interaction for a few frames if init wasn't called (i.e. this sprite was spawned from SpawnCarryableSprite.asm)
;LDA #$69
;STA !Init

;LDA #$08
;STA !154C,x

;LDA #$00
;STA !WasFrozen

;+
JSR GFX				;show graphics

;LDA !14C8,x
;CMP #$0B
;BNE .skipCarried

.carried
;JSL $07F7D2							; set up tweaker bytes
;LDA !sprite_tweaker_1686,x			; \ set "don't interact with other sprites" flag
;ORA #$08							; |
;STA !sprite_tweaker_1686,x			; /

.skipCarried
LDA !14C8,x			;if dead
BEQ .Re		;

LDA $9D				;or frozen in time and space
BNE .Re				;return

LDA !Frozen
BNE .Freeze

;LDA !154C,x
;CMP #$08        ; if just spawned by SpawnCarryableSprite.asm, don't try to unfreeze
;BEQ .continue

LDA !WasFrozen
BEQ .continue

.Unfreeze
JSR RestoreSpriteSpeedAndState

LDA #$00
STA !WasFrozen

.continue
%SubOffScreen()			;erase offscreen

%SubHorzPos()			;face player. always.
TYA				;
STA !157C,x			;

LDA !154C,x             ;\ If contact is disabled, skip interaction.
BNE +

;LDA !14C8,x	            ; if shell isn't kicked, skip interaction.
;CMP #$0A
;BNE +

; if not kicked or carryable/stationary, don't run clone contact code
 LDA !14C8,x
 CMP #$0A
 BEQ .clone

 LDA !14C8,x
 CMP #$09
 BEQ .clone

BRA .player

.clone
JSR SetCloneContact

.player
LDA !14C8,x
CMP #$0B
BEQ +       ; if carried, don't interact w/ player

LDA !154C,x             ;\ If contact is disabled, skip interaction.
BNE +

JSL $01803A|!BankB		;interact with player and sprites
+

.Re
LDA #$00            ;looks like after interaction is checked, it messes with offscreen situation in some way
%SubOffScreen()            ;it looks like it marks sprite as "process offscreen" but also as "respawn when nearby", which can lead to duplication. odd.
RTS

 .Freeze
 LDA !WasFrozen
 BNE .dontSave

JSR SaveSpriteSpeedAndState

.dontSave
LDA #$01
STA !WasFrozen

LDA #$00
%SubOffScreen()
STZ !AA,x
STZ !B6,x
RTS

GetCloneAboveShell:
    LDA !14D4,y
    XBA
    LDA !D8,y
    REP #$20
    STA $00
    SEP #$20

    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    CLC : SBC $00
    SEP #$20

    RTS

RestoreSpriteSpeedAndState:
REP #$20
LDA !SpeedXY
SEP #$20
STA !AA,x
XBA
STA !B6,x

LDA !State
STA !14C8,x
RTS

SaveSpriteSpeedAndState:
LDA !B6,x   ;xspeed
XBA
LDA.w !AA,x ;yspeed
REP #$20
STA !SpeedXY
SEP #$20

LDA !14C8,x
STA !State
RTS

;not so interesting tables stored away

XDisp:
db $04,$00,$FC,$00

YDisp:
db $F1,$00,$F0,$00

XFlip:
    db $00,$00,$00,$00
    ;db $00,$00,$00,$40		;only last byte is flip for one of shell's frames

GFX:
%GetDrawInfo()

LDA !14C8,x			;
;EOR #$08			;
STA $03				;set scratch ram to contains information on wether sprite's in normal status.

LDA $00				;
STA $0300|!Base2,y		;shell tile X-pos
STA $0308|!Base2,y		;shell tile X-pos
CLC
ADC #$08
STA $0304|!Base2,y		;shell tile X-pos
STA $030C|!Base2,y		;shell tile X-pos

LDA $01				;
STA $0301|!Base2,y		;shell tile Y-pos
STA $0305|!Base2,y		;shell tile Y-pos
CLC
ADC #$08
STA $0309|!Base2,y		;shell tile Y-pos
STA $030D|!Base2,y		;shell tile Y-pos

PHY				;
LDA $03				;if dead, don't animate shell
CMP #$0A
BNE .NoAnim			;

LDA $14				;animate with frame counter and all
.NoAnim
LSR #2				;
AND #$03			;fetch correct tile and flip info
TAY				;
LDA XFlip,y			;
STA $02				;
LDA TilemapUL,y			;
PLY				;
STA $0302|!Base2,y		;
INC
STA $0306|!Base2,y		;

PHY
LDA $03				;if dead, don't animate shell
CMP #$0A
BNE .NoAnim2			;

LDA $14				;animate with frame counter and all
.NoAnim2
LSR #2				;
AND #$03			;fetch correct tile and flip info
TAY				;
LDA TilemapDL,y			;
PLY				;
STA $030A|!Base2,y		;
INC
STA $030E|!Base2,y		;


LDA $02				;flip info
BEQ +
LDA $0302|!Base2,y		;
PHA
LDA $0306|!Base2,y		;
STA $0302|!Base2,y		;
PLA
STA $0306|!Base2,y		;

LDA $030A|!Base2,y		;
PHA
LDA $030E|!Base2,y		;
STA $030A|!Base2,y		;
PLA
STA $030E|!Base2,y		;
LDA $02
+

ORA !15F6,x			;+cfg setting which is useless because we set it afterwards
ORA $64				;and priority
STA $0303|!Base2,y		;store as tile property
STA $0307|!Base2,y		;store as tile property
AND #$FF;#$FE
STA $030B|!Base2,y		;store as tile property
STA $030F|!Base2,y		;store as tile property

LDX $15E9|!Base2		;restore sprite slot

LDA #$03			;4 tiles
LDY #$00			;8x8
JSL $01B7B3|!BankB		;
RTS				;

WallHit:
LDA #$01			;hit sound effect
STA $1DF9|!Base2		;

LDA !15A0,x			;if offscreen, don't trigger bounce sprite
BNE .NoBlockHit			;

LDA !E4,x			;
SEC : SBC $1A			;
CLC : ADC #$14			;
CMP #$1C			;
BCC .NoBlockHit			;

LDA !1588,x			;
AND #$40			;
ASL #2				;
ROL				;
AND #$01			;
STA $1933|!Base2		;

LDY #$00			;
LDA $18A7|!Base2		;
JSL $00F160|!BankB		;

LDA #$05			;
STA !1FE2,x			;

.NoBlockHit
RTS				;

SetCloneContact:
	LDY #!SprSize-1		;loop count (loop though all sprite number slots)
.Loop
	PHX
	LDA !14C8,y		;load sprite status
	BEQ .loopSprSprBridge	;if non-existant, keep looping.

	LDA !7FAB9E,x		;load this sprite's number
	STA $07			;store to scratch RAM.
	TXA			;transfer X to A (sprite index)
	STA $08			;store it to scratch RAM.
	TYA			;transfer Y to A
	CMP $08			;compare with sprite index
	BEQ .loopSprSprBridge		;if equal, keep looping.

    STA !CloneIndex

	TYX			;transfer Y to X
	LDA !7FAB9E,x		;load sprite number according to index
	CMP $07			;compare with cursor's number from scratch RAM
	BEQ .loopSprSprBridge		;if equal, keep looping.

	CMP #!CloneSpriteNumber            ;compare with clone index
	BNE .LoopSprSpr 	;if not clone, keep looping.

	PLX     			;restore sprite index.
	JSL $03B6E5|!BankB	;get sprite A clipping (this sprite)
	PHX			;preserve sprite index
	TYX			;transfer Y to X
	JSL $03B69F|!BankB	;get sprite B clipping (interacted sprite)
	JSL $03B72B|!BankB	;check for contact
	BCC .LoopSprSpr		;if carry is set, there's no contact, so branch.

	PLX			;restore sprite index

    LDA !CloneIndex
    TAY

    BRA .actions

.loopBridge
    BRA .Loop

.loopSprSprBridge
    BRA .LoopSprSpr

.actions
    LDA !14C8,x
    CMP #$0B    ;carried -> ignore?
    BEQ .done

    CMP #$09
    BEQ .kick   ;stationary -> kick

.kicked
    JSR GetCloneAboveShell
    BMI ..kill

    CMP #$04
    BCC ..kill

    LDA !CloneSpinning
    BEQ ..kill

    BRA .done   ; if spinning and above shell, let clone bounce

..kill
    LDA #$02
    STA !14C8,y

    BRA .done

.kick
    JSR KickShell

    BRA .done

.LoopSprSpr
    PLX			        ; restore sprite index
    DEY			        ; decrement loop count by one
	BPL .loopBridge		; and loop while not negative.

.done
	RTS			; end? return.

KickShell:
    jsr GivePoints          ; Give points
    lda #!KickedSFX         ;\ Play SFX.
    sta !KickedSFXAddr      ;/
    lda !1540,x             ;\ Probably useless.
    sta !C2,x               ;/
    lda #$0A                ;\ Set kicked state.
    sta !14C8,x             ;/
    lda #!KickNoInteractTime;\ Briefly disable interaction with Mario.
    sta !154C,x             ;/

    ; if KickShell is being called, it's guaranteed to be a clone interaction
.cloneKick
    JSR GetCloneRightOfShell
    BPL ..right
..left
    LDY #$00
    BRA .store

..right
    LDY #$01
.store
    lda KickXSpeeds,y       ;| Set X speed based on throw direction.
    sta !B6,x               ;/
    rts

GivePoints:
    lda $1697|!addr         ;\
    clc                     ;|
    adc !1626,x             ;|
    inc $1697|!addr         ;|
    tay                     ;| Play bounce SFX when $1697+$1626,x < #$08
    iny                     ;| (if >= @$08, it spawns a 1up score sprite which plays the SFX)
    cpy #$08                ;|
    bcs +                   ;|
    lda .SFX-1,y            ;|
    sta $1DF9|!addr         ;/
+   tya                     ;\
    cmp #$08                ;|
    bcc +                   ;| Give points accordingly (input capped to $08 = 1up)
    lda #$08                ;|
+   jsl $02ACE5|!bank       ;/
    rts

.SFX:
    db $13,$14,$15,$16,$17,$18,$19

KickXSpeeds:
    db -!KickXSpeed,!KickXSpeed,$CC,$34

GetCloneRightOfShell:
    LDA !CloneIndex
    TAY

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