;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Horizontal/Sideways Spring                     															      ;
; By DigitalSine																					              ;
;																												  ;
; USES EXTRA BIT: YES                                                                                             ;
;																												  ;
; If extra bit is set the springs wont be affected by gravity and cannot be eaten by yoshi, allowing you to       ; 
; stack the springs.																							  ;
;																												  ;
; Description: 																								      ;
; A spring that bounces Mario & most sprites sideways when hit from below or the sides, if you land on top it is  ;
; is solid. It can be eaten and spat out by yoshi and bounces back off of walls. The ground behaviour rountine    ;
; was lifted from RussianMans key disassembly and adapted from there so thanks to him for creating that and 	  ;
; saving me around 5 years working it out.                                                                        ;
; NOTE:                                                                                                           ;
; Some sprites may not behave exactly how you think but ive left it for potential gimmicks. Although              ; 
; i've tried to make it so the most used sprites would behave as you would expect.                                ;
;																												  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ================ Defines ================ ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!WallHitSound = $01         ; \ Sound when spring contacts a Wall or Celing
!WallHitBank = $1DF9|!Base2 ; /

!SpringSound = $08          ; \ Sound when spring is sprung
!SpringBank = $1DFC|!Base2  ; /

!SideBounceSpeed = $2F      ; \ Horizontal Power - Valid values are $00 - $7F
!UpBounceSpeed = $DF        ; / Vertical Power when being sprung

!ExtraPalette = 1           ; \ Use different palette for extra bit set. 0 = No - 1 = Yes
!ExtraProps = $09           ; | Different pallete to use for extra bit set
!NoExtraProps = $0B         ; / Green Spring uses palette C($0B)

Tilemap:
    db $A8,$AA,$AC,$AA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ================= Init ================== ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

print "INIT ",pc
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ================= Main ================== ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

print "MAIN ",pc
PHB : PHK : PLB
	JSR MainCode
PLB : RTL

MainCode:

    LDA $9D                         ; \
    BEQ +                           ; | Locked?
    RTS                             ; |
+   %SubOffScreen()                 ; / Zero Assured     

    LDA !14C8,x                     ; \ If spring gets eaten..
    CMP #$09                        ; | ..and then spat/kicked..
    BNE .NotEaten                   ; |
    DEC !14C8,x                     ; | ..put him back to normal state..
    STZ !1602,x                     ; / ..and reset animation

    .NotEaten:                      ; \
    LDA $14                         ; | 
    AND #$0A                        ; | Graphics Update Timer
    BNE .NoUpdate                   ; |
    LDA !1602,x                     ; |
    AND #$0F                        ; |
    BEQ .NoUpdate                   ; |
    CMP #$03                        ; |
    BCS +                           ; |
    INC !1602,x                     ; | Update
    JMP .NoUpdate                   ; |
+   STZ !1602,x                     ; | Reset Graphics
    .NoUpdate:                      ; /

    JSR Graphics                    ; \
    JSR Physics                     ; | Ground Physics
    %BES(.Extra)                    ; |
    JSL $01802A|!BankB              ; | Gravity
    LDA !15F6,x                     ; |
    ORA #!NoExtraProps              ; | Store Props to YXPPCCCT Values
    STA !15F6,x                     ; |
    JMP .NoExtra                    ; |
    .Extra:                         ; |
    LDA !1686,x                     ; |
    ORA #$01                        ; | Inedible
    STA !1686,x                     ; | To Yoshi
        if !ExtraPalette            ; |
            LDA !15F6,x             ; |
            ORA #!ExtraProps        ; | Store Props to YXPPCCCT Values
            STA !15F6,x             ; |
        endif                       ; |
    .NoExtra:                       ; /

    JSL $01A7DC|!BankB              ; \ Mario Contact
    BCS CheckMario                  ; |
    JMP CheckSprite                 ; /

        CheckMario: 
            STZ !154C,x             ; \ Always interact
            LDA !D8,x               ; | Make solid on top stuff
            SEC : SBC $96           ; | //// Used $96 instead of $D3
            CLC : ADC #$08          ; |
            LDY $187A|!Base2        ; | On Yoshi?
            BEQ .NoSideBump         ; |
            SEC : SBC #$0F          ; | Lower height offset
            .NoSideBump:            ; |
            CMP #$1F                ; | Not 20 
            BCC .Sides              ; |
            BMI CheckSprite         ; /

            .OnTop: 
            LDA $7D				    ; \ Jump Off Check
            BMI CheckSprite		    ; | 
            STZ $7D			        ; | Stay on spring if not
            STZ $72				    ; | Not in Air
            INC $1471|!Base2        ; | Type of surface
            LDA #$1F                ; | Offset for Mario
            LDY $187A|!Base2	    ; | 
            BEQ .NoYoshi		    ; | If not riding
            LDA #$2F			    ; | Bigger offset for yoshi
            .NoYoshi                ; |
            STA $00				    ; | Use whichever offset..
            LDA !D8,x			    ; |
            SEC : SBC $00		    ; |
            STA $96				    ; | ..to make mario land on top of spring
            LDA !14D4,x			    ; |
            SBC #$00			    ; |
            STA $97				    ; /
            JMP CheckSprite 

            .Sides: 
            %SubHorzPos()           ; \ Spring stuff
            TYA                     ; |
            BEQ .Right              ; |
            .Left:                  ; |
            LDA !1602,x             ; |            
            ORA #$40                ; | Flip graphics
            STA !1602,x             ; |
            LDA $7B                 ; | X Speed
            CLC                     ; |
            ADC #!SideBounceSpeed   ; | Most likely positive this side
            EOR #$FF                ; | Add then invert
            STA $7B                 ; |
            CMP #$BF                ; | L Cap
            BCS .Boing              ; |
            LDA #$C0                ; |
            STA $7B                 ; |
            JMP .Boing              ; |
            .Right:                 ; |
            LDA $0E                 ; | Check SubHorzPos Offset
            CMP #$0F                ; |
            BCS CheckSprite         ; | 
            LDA $7B                 ; | Mostly Likely Negative..
            EOR #$FF                ; | So flip first then add
            CLC                     ; |
            ADC #!SideBounceSpeed   ; |
            STA $7B                 ; |
            CMP #$40                ; | R Cap
            BCC .Boing              ; |
            LDA #$3F                ; |
            STA $7B                 ; |
            .Boing:                 ; |
            LDA #!SpringSound       ; |
            STA !SpringBank         ; | Boing
            LDA #$01                ; | 
            ORA !1602,x             ; |
            STA !1602,x             ; / Update graphics

        CheckSprite: 
            JSR SpriteContact       ; \ Go Check for Contact
            BCC .NoContact          ; | 
            .Contact:               ; |
            LDA !1564,y             ; | Load a timer
            BNE .NoContact          ; | To De-Bounce
            LDA #$08                ; |
            STA !1564,y             ;  \
                                    ;  |
            LDA !7FAB9E,x           ;  | X index currently processed
            TYX                     ;  |
            CMP !7FAB9E,x           ;  | Y index sprite
            BNE .NotSpring          ;  | If not both the same sprite branch    
            LDX $15E9|!Base2        ;  | Restore index
            %BES(.SmallGap)         ;  | Extra bit check                               
            JMP .NotSpring          ;  | Because moving springs should bounce springs
            .SmallGap:              ;  |
            LDA !D8,x               ;  | Bottom sprites Y Pos
            SEC : SBC #$11          ;  | Put it above the bottom sprite + 1
            STA !D8,y               ;  | So its not constantly touching
            .NoContact:             ;  | But if no sprite contact, return.
                RTS                 ;  |
                                    ;  /
            .NotSpring:             ; |
            LDX $15E9|!Base2        ; | Restore index
            LDA !14C8,y             ; |
            CMP #$0B                ; | If being Carried..
            BEQ ReturnSS            ; |
            LDA #!SpringSound       ; | Boing
            STA !SpringBank         ; |
            .Moving:                ; |
            LDA $9E,y               ; |
            CMP #$53                ; | If its a throw Block..
            BEQ .Kickable           ; |
            CMP #$04                ; | ..or if its a koopa..
            BCC .NotKoopa           ; |
            CMP #$08                ; |
            BCC .Kickable           ; |
            CMP #$35                ; | If its the Homie Yosh..
            BNE .NotKoopa           ; |
            LDA $187A|!Base2        ; | ..and Mario is riding, Return..         
            BNE ReturnSS            ; | 
            JMP .NotKoopa           ; | ..If not..
            .Kickable:              ; |
            LDA !14C8,y             ; |
            CMP #$09                ; | ..in its shell..
            BNE .NotKoopa           ; |  
            LDA #$0A                ; |
            STA $00                 ; | ...then kick it.
            JMP .Boing              ; |
            .NotKoopa:              ; |
            LDA !14C8,y             ; | Else..
            STA $00                 ; | Save its state going in
            .Boing:                 ; |
            LDA #$09                ; | Then make it stationary
            STA !14C8,y             ; |
            .Direction:             ; |
            LDA !157C,y             ; | Initial Facing
            BEQ .Left               ; |
            .Right:                 ; |
            LDA #!SideBounceSpeed   ; | 
            STA !B6,y               ; |  
            JMP .Ground             ; |
            .Left:                  ; |
            LDA !1602,x             ; |            
            ORA #$40                ; | Flip spring graphics
            STA !1602,x             ; |        
            LDA #!SideBounceSpeed   ; |
            EOR #$FF                ; |
            STA !B6,y               ; |
            .Ground:                ; |
            LDA !1588,y             ; |
            AND #$04                ; |
            BNE .Up                 ; | If not on the ground..
            LDA !157C,y             ; |
            EOR #$01                ; | Flip facing flag to bounce
            STA !157C,y             ; | back and forth.
            .Up:                    ; |
            LDA #!UpBounceSpeed     ; | Bounce it up a bit
            STA !AA,y               ; |
            LDA $00                 ; | Revert back to old state
            STA !14C8,y             ; |
            LDA #$01                ; | 
            ORA !1602,x             ; |
            STA !1602,x             ; | Update graphics
            ReturnSS:               ; /
            RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ============= GFX Routine =============== ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

Graphics:
	%GetDrawInfo()		            ; \
	LDA $00				            ; |
    STA $0300|!Base2,y              ; | X Position
	LDA $01				            ; |
    STA $0301|!Base2,y              ; | Y Position
	LDA !1602,x			            ; | Graphics index
    AND #$0F                        ; |
    PHX                             ; |
    TAX                             ; |
    LDA Tilemap,x                   ; |
    PLX                             ; |
    STA $0302|!Base2,y              ; | Tile
    LDA !1602,x                     ; | 
    AND #$40                        ; | Flipped check
    ORA #$21			            ; |
    ORA !15F6,x                     ; | YXPPCCCT Values
    STA $0303|!Base2,y              ; |
	LDA #$00			            ; | Tile to draw - 1
	LDY #$02			            ; | 16x16 sprite
	JSL $01B7B3|!BankB              ; /
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ============ Sub-Routines =============== ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

Physics:
    LDA !1588,x                     ; \ Still Act like a spring..
    AND #$03                        ; | ..before acting like a thing
    BEQ .NotAirBounce               ; | Walls?
    LDA !B6,x                       ; |
    BPL .Right                      ; | Filter direction
    SEC : SBC #!SideBounceSpeed     ; |
    JMP .Left                       ; |
    .Right:                         ; | Add spring
    CLC : ADC #!SideBounceSpeed     ; |
    .Left:                          ; |
    EOR #$FF                        ; | Flipped direction
    STA !B6,x                       ; |
    LDA #!SpringSound               ; |
    STA !SpringBank                 ; | Boing
    LDA #$01                        ; | 
    ORA !1602,x                     ; |
    STA !1602,x                     ; / Update graphics

    .NotAirBounce:
    LDA !1588,x			;if it's on ground
    AND #$04			;
    BEQ .NoWallHit			;

    JSR HandleLandingBounce		;do little upward bouncy

    .NoBounce
    LDA !1588,x			;if sprite meets with ceiling
    AND #$08			;and it's like "hello there cutie"
    BEQ .NoWall			;then no

    LDA #$10			;just kidding. ceiling didn't said that. wrong text file.
    STA !AA,x			;ceiling bump gives downward speed

    .NoCeiling
    LDA !1588,x			;check if it hits any wall
    AND #$03			;
    BEQ .NoWallHit			;

    LDA !E4,x			;prepare for block interaction
    CLC : ADC #$08			;
    STA $9A				;

    LDA !14E0,x			;
    ADC #$00			;
    STA $9B				;

    LDA !D8,x			;
    AND #$F0			;
    STA $98				;

    LDA !14D4,x			;
    STA $99				;

    LDA !1588,x			;
    AND #$20			;
    ASL #3				;
    ROL				;
    AND #$01			;
    STA $1933|!Base2		;

    LDY #$00			;
    LDA $1868|!Base2		;
    JSL $00F160|!BankB		;

    LDA #$08			;
    STA !1FE2,x			;

    .NoWall
    LDA !1588,x			;
    AND #$03			;
    BEQ .NoWallHit 			;

    JSR HandleBlockHit		;almost the same as above

    LDA !B6,x			;reverse X-speed
    ASL				;
    PHP				;
    ROR !B6,x			;
    ASL				;
    ROR !B6,x			;
    PLP				;
    ROR !B6,x			;

    .NoWallHit
    RTS

HandleBlockHit:
    LDA #!WallHitSound		;sound effect
    STA !WallHitBank|!Base2	;

    ;JSR .HandleBreak		;checks if it's a throw block. SPOILER! It's not.

    LDA !15A0,x			;prevent sprite from triggering blocks when offscreen
    BNE .Return			;

    LDA !E4,x			;
    SEC : SBC $1A			;
    CLC : ADC #$14			;
    CMP #$1C			;
    BCC .Return			;

    LDA !1588,x			;
    AND #$40			;
    ASL #2				;
    ROR				;
    AND #$01			;
    STA $1933|!Base2		;

    LDY #$00			;
    LDA $18A7|!Base2		;
    JSL $00F160|!BankB		;

    LDA #$05			;
    STA !1FE2,x			;
    
    .Return
    RTS				;

HandleLandingBounce:
    LDA !B6,x			;
    PHP				;
    BPL .SkipInvertion		;

    EOR #$FF			;
    INC				;

    .SkipInvertion
    LSR				;
    PLP				;
    BPL .SkipInvertionx2		;

    EOR #$FF			;
    INC				;

    .SkipInvertionx2
    STA !B6,x			;
    LDA !AA,x			;
    PHA				;

    LDA !1588,x			;
    BMI .Speed2			;
    LDA #$00			;
    LDY !15B8,x			;
    BEQ .Store			;

    .Speed2
    LDA #$18			;

    .Store
    STA !AA,x			;

    PLA				;
    LSR #2				;
    TAY				;

    LDA .BounceSpeeds,y		;
    LDY !1588,x			;
    BMI .Re				;
    STA !AA,x			;

    .Re
    RTS				;

.BounceSpeeds:
db $00,$00,$00,$F8,$F8,$F8,$F8,$F8
db $F8,$F7,$F6,$F5,$F4,$F3,$F2,$E8
db $E8,$E8,$E8,$00,$00,$00,$00,$FE
db $FC,$F8,$EC,$EC,$EC,$E8,$E4,$E0
db $DC,$D8,$D4,$D0,$CC,$C8

SpriteContact:
    JSL	$03B69F             ; \ Get Sprite Clipping A.	
    LDX #!SprSize           ; |
    .Loop:                  ; |
    DEX                     ; |
    BMI .Return		        ; | Counter empty?
    CPX $15E9|!Base2        ; |
    BEQ .Loop               ; | Dont check against self
    LDA !14C8,x             ; |
    CMP #$08                ; | Alive?
    BCC .Loop	            ; |
    JSL $03B6E5             ; | Get Sprite Clipping B.
    STY $1695|!Base2        ; |
    JSL $03B72B             ; | Check for contact.
    TXY                     ; |
    BCC .Loop 	            ;  \ No Contact, go back.
                            ;  |
    LDA $02                 ; /
    LSR                     ; |
    CLC                     ; |
    ADC $00                 ; |
    STA $0C                 ; |
    LDA $08                 ; |
    ADC #$00                ; |
    STA $0D                 ; \
                            ;  |
    LDA $03                 ; /
    STA $0D                 ; |
    LSR                     ; |
    CLC                     ; |
    ADC $01                 ; |
    STA $0E                 ; |
    LDA $09                 ; |
    ADC #$00                ; |
    STA $0F                 ; |
    LDX $15E9|!Base2        ; | Restore index
    SEC                     ; | Set carry if contact
    .Return:                ; |
    LDX $15E9|!Base2        ; / Restore index
    RTS