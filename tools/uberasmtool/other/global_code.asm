
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

; Note that since global code is a single file, all code below should return with RTS.

!controller_read_optimization = 0 ; set to 0 to uninstall

load:
	rts
init:
    jsl mario_exgfx_init
	rts
;nmi:
;	 rts
main:
    jsl mario_exgfx_main

; .NoOverworld
; 	LDA $0100|!addr
; 	CMP #$10
; 	BNE +
; 	JSL NoOverworld_PreLoadLevel ; this happens at gamemode 10 (init)
; +
; 	CMP #$14
; 	BNE +
; 	JSL NoOverworld_DuringLevel ; this happens at gamemode 14 (main)
; +
; 	CMP #$0C
; 	BNE +
; 	JSL NoOverworld_SkipOW ; this happens at gamemode 0C (init)
; +
; .NoOverworld_end
    ; you can add other code here

pushpc
org $008650|!bank
ControllerUpdate:

if !controller_read_optimization
org $008243|!bank
BRA $01
org $0082F4|!bank
BRA $01
org $0086C6|!bank
RTL
pullpc
JSL ControllerUpdate|!bank

else
org $008243|!bank
JSR ControllerUpdate
org $0082F4|!bank
JSR ControllerUpdate
org $0086C6|!bank
RTS
pullpc
endif
!sa1 ?= -1
assert !sa1 != -1, "Read the comments for how to install"
assert read1($0086C1|!bank) != $5C, "Incompatible with optimized block change patch"
	rts
