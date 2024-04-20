
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

;===============================================
; SJC fix: once the platform was falling, if you hit the on/off switch again,
; the GFX wouldn't disappear but rather freeze in place,
; though now any interaction was gone. I removed this.
;
; Grey Platform, ON/OFF Controlled
; By Erik, mods by SJC
;
; Description: This grey platform will only
; appear depending on the status of the ON/OFF
; switch.
;
; Uses extra bit: YES
; By default, if the extra bit's clear, platform will be OFF,
; and will only appear when on/off is hit.
; Set the extra bit to start with the platform visible.
; Extra bytes:
; - Extra byte 1: if anything other than 0, it
;   will rise. Else, it'll fall.
;===============================================

!active = !187B,x

tilemap_inactive:
        db $C0,$C1,$C1,$C2
tilemap_active:
        db $E0,$E1,$E1,$E2

print "MAIN ",pc
        PHB
        PHK
        PLB
        JSR grey_rising_platform
        PLB
print "INIT ",pc
        RTL

grey_rising_platform:
        LDA !7FAB10,x
        AND #$04
        CMP #$04
        BNE .invertedOnOffBehavior

.regularOnOffBehavior
        WDM #$01
        LDA $14AF|!addr       ; #$00 is ON
        BNE PlatformInactive      ; if off, platform is off
        BRA .platformCode

.invertedOnOffBehavior
        LDA $14AF|!addr
        BEQ PlatformInactive      ; if on, platform is off
.platformCode
        SEC
        JSR draw_sprite
        LDA $9D
        BNE return

        %SubOffScreen()

        LDA !AA,x
        BEQ .no_speed_update ; goes to JSL $01B44F
        LDA !1540,x
        BNE .update_speed
        LDA !7FAB40,x
        BNE .rise

        LDA !AA,x
        CMP #$40
        BPL .update_speed
        CLC
        ADC #$02
        BRA .store_aa

.rise
        LDA !AA,x
        CMP #$C0
        BMI .update_speed
        SEC
        SBC #$02
.store_aa
        STA !AA,x
.update_speed
        JSL $01801A|!BankB
.no_speed_update
        JSL $01B44F|!BankB  ; solid sprite routine
        BCC return
        LDA !AA,x
        BNE return
        LDY #$FD
        LDA !7FAB40,x
        BNE +
        LDY #$03
+       TYA
        STA !AA,x
        LDA #$18
        STA !1540,x
return:
        RTS

PlatformInactive:
        CLC
        JSR draw_sprite
        RTS
;================
; Graphics
;================
x_disp:
        db $00,$10,$20,$30

draw_sprite:
        BCC .inactive_gfx
.active_gfx
        LDA #$01
        STA !active
        BRA .gfx
.inactive_gfx
        LDA #$00
        STA !active
.gfx
        %GetDrawInfo()
;         LDA !AA,x
;         BNE .draw
;         LDY #$00
;         LDA $14AF|!Base2
;         BEQ +
;         LDY #$04
; +       STY $02
;         LDA !7FAB10,x
;         AND #$04
;         CMP $02
;         BEQ .return_gfx ; SJC changed from
        LDY !15EA,x

.draw
        LDA !15F6,x
        STA $03
        LDX #$03
.loop
        LDA $00
        CLC
        ADC x_disp,x
        STA $0300|!Base2,y
        LDA $01
        STA $0301|!Base2,y
        PHX
        LDX $15E9|!addr
        LDA !active
        BEQ .inactive

.active
        PLX
        LDA tilemap_active,x
        BRA +
.inactive
        PLX
        LDA tilemap_inactive,x
        
+       STA $0302|!Base2,y
        LDA $03
        ORA $64
        STA $0303|!Base2,y
        INY #4
        DEX
        BPL .loop
        LDX $15E9|!Base2
        LDY #$02
        LDA #$03
        JSL $01B7B3|!BankB
.return_gfx
        RTS

