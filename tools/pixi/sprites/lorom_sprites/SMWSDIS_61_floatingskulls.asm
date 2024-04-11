;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite 61 - Floating skulls
; adapted for Romi's Spritetool and commented by yoshicookiezeus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


			!RAM_FrameCounter	= $13
			!RAM_FrameCounterB	= $14
			!RAM_IsFlying		= $72
			!RAM_MarioObjStatus	= $77
			!RAM_MarioSpeedX	= $7B
			!RAM_MarioSpeedY	= $7D
			!RAM_MarioXPos		= $94
			!RAM_MarioXPosHi	= $95
			!RAM_MarioYPos		= $96
			!RAM_MarioYPosHi	= $97
			!RAM_SpritesLocked	= $9D
			!RAM_SpriteNum		= !9E
			!RAM_SpriteSpeedY	= !AA
			!RAM_SpriteSpeedX	= !B6
			!RAM_SpriteState	= !C2
			!RAM_SpriteYLo		= !D8
			!RAM_SpriteXLo		= !E4
			!OAM_DispX		= $0300|!Base2
			!OAM_DispY		= $0301|!Base2
			!OAM_Tile		= $0302|!Base2
			!OAM_Prop		= $0303|!Base2
			!OAM_TileSize		= $0460|!Base2
			!RAM_SpriteYHi		= !14D4
			!RAM_SpriteXHi		= !14E0
			!RAM_SpriteDir		= !157C
			!RAM_SprObjStatus	= !1588
			!RAM_OffscreenHorz	= !15A0
			!RAM_SprOAMIndex	= !15EA
			!RAM_SpritePal		= !15F6
			!RAM_OffscreenVert	= !186C
			!RAM_OnYoshi		= $187A|!Base2

!Freeram = $1864|!addr
!FrontSkullIndex = $7FA02B

Tilemap:		db $E0,$E2
!Number_Of_Skulls	= $02					; Don't set this to higher than 08


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_Offset:		db $10,$20,$30,$40,$50,$60,$70

			print "INIT ",pc
			PHB
			PHK
			PLB
			STZ $18BC|!Base2				; clear sprite trigger
			INC !RAM_SpriteState,x
			LDA #!Number_Of_Skulls			;\ setup loop
			DEC A					; |
			DEC A					; |
			BMI No_Spawn				; |
			STA $00					;/
CODE_02ED93:		JSL $02A9E4				;\ search for a free sprite slot
			BMI CODE_02EDCB				;/ if no free sprite slots, branch
			LDA #$08				;\ set sprite status
			STA !14C8,y				;/
			LDA !7FAB9E,x				;\ set sprite number
			PHX       				; |
			TYX					; |
			STA !7FAB9E,x				; |
			PLX					;/
			LDA !RAM_SpriteYLo,x			;\ set sprite y position
			STA !D8,y				; |
			LDA !RAM_SpriteYHi,x			; |
			STA !RAM_SpriteYHi,y			;/
			LDX $00					;\ use loop counter to determine x offset
			LDA X_Offset,x				;/
			LDX $15E9|!Base2				; load sprite index
			CLC					;\ set sprite x position
			ADC !RAM_SpriteXLo,x			; |
			STA !E4,y				; |
			LDA !RAM_SpriteXHi,x			; |
			ADC #$00				; |
			STA !RAM_SpriteXHi,y			;/
			LDA $00
			PHA
			PHX
			PHY
			TYX
			JSL $07F7D2				; clear out old sprite table values
			JSL $0187A7				; get table values for custom sprite
			LDA #$88				;\ set extra bit
			STA !7FAB10,x				;/
			PLY
			PLX
			PLA
			STA $00
			CMP #!Number_Of_Skulls-2
			BNE CODE_02EDCB

			PHA
			TYA
			STA !FrontSkullIndex
			PLA

CODE_02EDCB:		DEC $00					; decrease loop counter
			BPL CODE_02ED93				; if still skulls left to spawn, go to start of loop
No_Spawn:		PLB
			RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			print "MAIN ",pc
			PHB
			PHK
			PLB
			JSR Sprite_Code_Start
			PLB
			RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sprite_Code_Start:	LDA !RAM_SpriteState,x			;\ if sprite wasn't INITed and thus isn't the main sprite,
			BEQ CODE_02EDF6				;/ branch
			LDA #$00
            %SubOffScreen()
			LDA !14C8,x				;\ if sprite not inexistant,
			BNE CODE_02EDF6				;/ branch
			LDY #$09				; setup loop
CODE_02EDE6:		PHX
			TYX
			LDA !7FAB9E,x				;\ if sprite being checked isn't skull,
			PLX					; |
			CMP !7FAB9E,x				; |
			BNE CODE_02EDF2				;/ branch
			LDA #$00				;\ else, erase sprite
			STA !14C8,y				;/
CODE_02EDF2:		DEY					; decrease loop counter
			BPL CODE_02EDE6				; if still sprites left to check, go to start of loop
Return02EDF5:		RTS					; return

CODE_02EDF6:		JSR Sprite_Graphics
			LDA !RAM_SpritesLocked			;\ if sprites locked,
			BNE Return02EDF5			;/ return
			STZ $00
			LDY #$09				; setup loop
CODE_02EE21:		LDA !14C8,y				;\ if sprite being checked is inexistant,
			BEQ CODE_02EE36				;/ branch
			PHX
			TYX
			LDA !7FAB9E,x				;\ if sprite being checked isn't skull,
			PLX					; |
			CMP !7FAB9E,x				; |
			BNE CODE_02EE36				;/ branch
			LDA !RAM_SprObjStatus,y			;\ if sprite being checked isn't touching an object,
			AND #$0F				; |
			BEQ CODE_02EE36				;/ branch
			STA $00					; $00 = sprite object status
CODE_02EE36:		DEY					; decrease loop counter
			BPL CODE_02EE21				; if still sprites left to check, go to start of loop
			LDA $18BC|!Base2				; use sprite trigger to determin x speed
			;BEQ .notTriggered

			;CLC : ADC #$10

.notTriggered
			STA !RAM_SpriteSpeedX,x			;
			LDA !RAM_SpriteSpeedY,x			;\ if sprite y speed is less than 0x20,
			CMP #$20				; |
			BMI CODE_02EE48				;/ branch
			LDA #$20				;\ else, set sprite y speed to 0x20
			STA !RAM_SpriteSpeedY,x			;/ to prevent sprite from falling too fast
CODE_02EE48:		JSL $01802A				; update sprite position
			LDA !RAM_SprObjStatus,x			;\ if sprite not on ground,
			AND #$04				; | 
			BEQ CODE_02EE57				;/ branch
			LDA #$10				;\ else, set sprite y speed to 0x10
			STA !RAM_SpriteSpeedY,x			;/
CODE_02EE57:		JSL $01A7DC				;\ if Mario not touching sprite,
			BCC Return02EEA8			;/ return
			LDA !RAM_MarioSpeedY			;\ if Mario moving upwards,
			BMI Return02EEA8			;/ return
			LDA #$0C				;\ set sprite trigger
			STA $18BC|!Base2				;/
			LDA !RAM_SprOAMIndex,x			;\ make sprite graphics sink slightly
			TAX					; |
			INC !OAM_DispY,x			;/
			LDX $15E9|!Base2				; load sprite index
			LDA #$01				;\ set platform type 
			STA $1471|!Base2				;/
			STZ !RAM_IsFlying			; clear flying flag
			LDA #$1C				;\ set Mario y position according to Yoshi status
			LDY !RAM_OnYoshi			; |
			BEQ CODE_02EE80				; |
			LDA #$2C				; |
CODE_02EE80:		STA $01					; |
			LDA !RAM_SpriteYLo,x			; |
			SEC					; |
			SBC $01					; |
			STA !RAM_MarioYPos			; |
			LDA !RAM_SpriteYHi,x			; |
			SBC #$00				; |
			STA !RAM_MarioYPosHi			;/
			LDA !RAM_MarioObjStatus			;\ if Mario blocked to the right,
			AND #$01				; |
			BNE Return02EEA8		;/ return
			LDA $14
			CMP !Freeram
			BEQ Return02EEA8
			STA !Freeram
			LDY #$00				;\ make Mario match the sprite's horizontal movement
			LDA $1491|!Base2		; |
			BPL CODE_02EE9E				; |
			DEY					; |
CODE_02EE9E:		CLC					; |
			ADC !RAM_MarioXPos			; |
			STA !RAM_MarioXPos			; |
			TYA					; |
			ADC !RAM_MarioXPosHi			; |
			STA !RAM_MarioXPosHi			;/
Return02EEA8:		RTS					; return


Sprite_Graphics:	%GetDrawInfo()

			PHX
			LDA !RAM_FrameCounterB
			LSR
			LSR
			LSR
			AND #$01
			TAX
			LDA Tilemap,x
			PLX

			WDM #$01
			PHA
			TXA
			CMP !FrontSkullIndex
			BNE +

			PLA
			CLC : ADC #$04
			BRA ++

+			PLA
++			STA !OAM_Tile,y
			LDA $00
			STA !OAM_DispX,y
			LDA $01
			CMP #$F0
			BCS No_Move_Y
			CLC
			ADC #$03
No_Move_Y:		STA !OAM_DispY,y
			LDA !15F6,x
			ORA $64
			STA !OAM_Prop,y

			LDY #$02		; \ 460 = 2 (all 16x16 tiles)
			LDA #$00		;  | A = (number of tiles drawn - 1)
			JSL $01B7B3		; / don't draw if offscreen
			RTS			; return
            
            
            