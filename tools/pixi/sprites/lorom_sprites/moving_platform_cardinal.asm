;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Brown Moving Platform, by imamelia
;;
;; This platform will move back and forth in a specified range,
;; either vertically or horizontally.
;;
;; Uses first extra bit: YES
;;
;; If the first extra bit is set, the platform will move vertically.
;; If not, the platform will move horizontally.
;;
;; Based on the following sprite:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Brown Platform that falls, by Mirumo
;;  A brown platform from SMB3 that falls when stepped.
;;
;;  Extra Bit: YES
;;  Clear: it will not move.
;;  Set	:  it will always move to the left.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Updated by RussianMan, following changes:
;;
;;  -PIXI compatible (gb trasm).
;;  -Deleted some unecessary leftover code.
;;  (Seriously? Who uses %SubHorzPos and after that STZ Sprite direction? And why STZ is needed?)
;;  -Optimized a little bit.
;;
;;  Credititng me for that is unecessary.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!RAM_CustSprClip = $7FAB70		; 12 bytes of free RAM used for the custom sprite clipping value
!RAM_SprClipXDisp = $7FABAA		; 12 bytes of free RAM used for the X displacement of a custom sprite clipping field
!RAM_SprClipYDisp = $7FABB6		; 12 bytes of free RAM used for the Y displacement of a custom sprite clipping field
!RAM_SprClipWidth = $7FABC2		; 12 bytes of free RAM used for the width of a custom sprite clipping field
!RAM_SprClipHeight = $7FABCE		; 12 bytes of free RAM used for the height of a custom sprite clipping field

X_Speeds: db $0C,$F4
Y_Speeds: db $0C,$F4

!TimerValue = $5F
!TurnTimer = !1540				;Better to use sprite table that decrease itself, right?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                    print "INIT ",pc
			    		LDA #!TimerValue
	            		STA !TurnTimer,x		; set turn timer

						LDA #$00
						STA !RAM_CustSprClip,x
                    RTL                 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                    print "MAIN ",pc                                    
                    PHB                     ; \
                    PHK                     ;  | main sprite function, just calls local subroutine
                    PLB                     ;  |
                    JSR SPRITE_CODE_START   ;  |
                    PLB                     ;  |
                    RTL                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETURN:
RTS
SPRITE_CODE_START:
LDA #$00
STA !RAM_CustSprClip,x

JSR SPRITE_GRAPHICS     ; graphics routine

LDA !14C8,x
EOR #$08
ORA $9D
BNE RETURN

LDY #$00
%SubOffScreen()	        ; handle off screen situation

JSL $01B44F		; invisible solid block routine

LDA !7FAB10,x		;
AND #$04		; if the extra bit is set...
BNE Vertical		; move vertically

Horizontal:
LDY !157C,x		;
LDA X_Speeds,y		; set X speed based on direction
STA !B6,x

JSL $018022             ; Update X position without gravity

STA !1528,x             ; prevent Mario from sliding horizontally
BRA FlipOrNot         	; update X position
RTS

Vertical:
LDY !151C,x		;
LDA Y_Speeds,y		; set Y speed based on direction
STA !AA,x

JSL $01801A             ; Update Y position without gravity

FlipOrNot:
;LDA !TurnTimer,x	; if the turn timer is 00...
;BNE RETURN		
BRA RETURN
FlipDirection:		; flip the sprite's direction

LDA !157C,x
EOR #$01		; flip horizontal direction
STA !157C,x

LDA !151C,x
EOR #$01		; flip vertical direction
STA !151C,x

LDA #!TimerValue
STA !TurnTimer,x	; reset turn timer

RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


FallingPlatDispX:                 db $00,$10,$20,$30

FallingPlatTiles:                 db $60,$60,$60,$62

SPRITE_GRAPHICS:    %GetDrawInfo()
		    PHX                       
	            LDX #$03                
CODE_038498:  	    LDA $00                   
		    CLC                       
		    ADC FallingPlatDispX,X  
		    STA $0300|!Base2,y         
		    LDA $01                   
		    STA $0301|!Base2,y         
		    LDA FallingPlatTiles,X  
		    STA $0302|!Base2,y          
		    LDA #$01             ;Sprite PAL/GFX Page                
		    ORA $64                   
		    STA $0303|!Base2,y          
		    INY #4                      
	            DEX                       
	            BPL CODE_038498           
		    PLX                       
		    LDY.B #$02                
		    LDA.B #$03                
		    JSL $01B7B3     
		    RTS                       ; Return 