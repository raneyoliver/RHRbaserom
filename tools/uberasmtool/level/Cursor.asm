
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

!SprSize = $16
!FreezeMiscTables				= 1		; If set, the miscellaneous sprite tables which control various sprite behaviours will also be frozen.
							; This can prevent jank with certain sprites and enables freezing for sprites not controlled by their X/Y speeds and positions.
							; However, it uses a lot more freeRAM than if disabled (see below). It also isn't guaranteed to behave nicely with custom sprites.
!MarioSpriteNumber				= $14	; in pixi_list.txt
!StartRAM						= $41B900		; FreeRAM start address to backup the sprites.


macro SetSpriteStatus(status, index)
    LDA <status>
	STA !14C8,<index>
endmacro

macro SprToRAM(addr, offset)
LDA <addr>,x
STA !StartRAM+(!sprite_slots*<offset>),x
endmacro

macro RAMToSpr(addr, offset)
LDA !StartRAM+(!sprite_slots*<offset>),x
STA <addr>,x
endmacro

init:
	RTL

main:
	LDA $15
	AND #$C0
	BEQ .return

	JSR screenext

.return
	RTL

end:
	PHX
	JSR FreezeAllSprites
	PLX
	RTL

screenext:
	LDA #$06	;teleport to screen exit
	STA $71
	STZ $88
	STZ $89
	RTS

;;;;;;;;; SPRITE FREEZING ;;;;;;;;;

FreezeAllSprites:
LDX #!sprite_slots-1
.loop
LDA !7FAB10,x
AND #$08
BNE .isCustom

LDA !9E,x
.checkBulletBill
CMP #$1C
BEQ +

.checkGoalTape
CMP #$7B								;| Don't freeze the goal tape.
BNE +
JMP Next

.isCustom
.checkMarioSprite
LDA !7FAB9E,x
CMP #!MarioSpriteNumber					;| Don't freeze the MarioSprite.
BNE +									;|
JMP Next
+

;LDA $9D
;BEQ .restoreSpriteTablesBridge	; As soon as done teleporting, unfreeze all sprites

if !FreezeMiscTables
CMP !StartRAM+(!sprite_slots*28),x		; If the sprite number changed last frame (e.g. Parakoopa to Koopa when jumped on), backup the sprite tables instead.
BNE +

CMP #$98					;/
BNE .NotPitchChuck			;|
LDA !1540,x					;|
AND #$1F					;|
CMP #$06					;|
BEQ +						;|
BRA .DontCheckChange		;|
.NotPitchChuck				;|
CMP #$9B					;|
BNE .NotHammerBro			;| Pitchin' Chuck, Flyin' Hammer Bro and Dry Bones need a check for their timer that controls when they throw.
LDA !1540,x					;| Otherwise, freezing them on the same frame they throw will cause them to keep throwing every frame until the extended sprite slots are full.
BNE +						;|
BRA .DontCheckChange		;|
.NotHammerBro				;|
CMP #$30					;|
BNE .NotDryBones			;|
LDA !1540,x					;|
CMP #$01					;|
BEQ +						;|
BRA .DontCheckChange		;|
.NotDryBones				;\

CMP #$3E								;/
BEQ .CheckPChange						;|
CMP #$9C								;|
BEQ .CheckC2Change						;|
CMP #$AB								;|
BEQ .CheckC2Change						;|
CMP #$C8								;|
BEQ .CheckC2Change						;| Various sprites which require a check for a state change.
CMP #$83								;|
BEQ .CheckC2Change						;|
CMP #$84								;|
BEQ .CheckC2Change						;|
CMP #$B9								;|
BNE .DontCheckChange					;\
.CheckC2Change
LDA !C2,x								;/
CMP !StartRAM+(!sprite_slots*7),x		;| If C2 changed last frame for the Flying Grey Platform, Rex, the Light Switch Block, the Message Box or the Flying ?-blocks,
BEQ .DontCheckChange					;\ backup the sprite tables.
+
-
JSR SprRAMTransfer
JMP Next

.restoreSpriteTablesBridge
BRA .restoreSpriteTables

.CheckPChange
LDA !163E,x				;/
BNE -					;\ Backup the sprite tables if it's a pressed P-switch.
.DontCheckChange
endif

LDA !14C8,x				;/
CMP #$0B				;| Backup the tables if the sprite is carried or a goal coin (but actually only carried since the code immediately returns if $1493 is set).
BCC +					;\
-
JSR SprRAMTransfer
JMP Next
+
CMP #$08								; If the sprite isn't alive (or empty/init), backup the tables.
BCC -
CMP !StartRAM+(!sprite_slots*6),x		; If the sprite status changed last frame, backup the tables. Ensures the sprite's tables are initialized properly before freezing.
BNE -

TXA									;/
INC									;|
CMP $18E2|!addr						;|
BNE +								;|
LDA $187A|!addr						;|
BNE -								;| If Mario is riding Yoshi or the ride flag changed last frame, backup Yoshi's tables. Prevents jank with mounting/dismounting.
if !FreezeMiscTables				;|
CMP !StartRAM+(!sprite_slots*29)	;|
else								;|
CMP !StartRAM+(!sprite_slots*7)		;|
endif								;|
BNE -								;\
+

.restoreSpriteTables
%RAMToSpr(!E4, 0)					; Moves all the RAM backups to the sprite tables every frame, freezing them.
%RAMToSpr(!14E0, 1)					; If !FreezeMiscTables is disabled then only the sprite position, speed, and fraction bits are backed up.
%RAMToSpr(!D8, 2)
%RAMToSpr(!14D4, 3)
%RAMToSpr(!AA, 4)
%RAMToSpr(!B6, 5)
if !FreezeMiscTables
LDA !9E,x							;/
CMP #$35							;|
BEQ +								;| Don't ever change C2 for Yoshi.
%RAMToSpr(!C2, 7)					;|
+									;\
%RAMToSpr(!1504, 8)
%RAMToSpr(!1510, 9)
%RAMToSpr(!151C, 10)
%RAMToSpr(!1528, 11)
%RAMToSpr(!1534, 12)
LDA !9E,x							;/
CMP #$2F                            ; added by SJC
BEQ +
; CMP #$04							;|
; BCC .NotKoopa						;|
; CMP #$08							;|
; BCC +								;| Don't ever change 1540 for the normal Koopas (prevents spawn jank with the sliding koopa when a normal Koopa is bounced on).
; .NotKoopa							;|
%RAMToSpr(!1540, 13)				;|
+									;\


LDA !7FAB10,x
AND #$08
BEQ .vanilla ; if EQ, is vanilla

LDA !7FAB9E,x
CMP #$1B
BEQ ++					; leave 154C (contact disabled flag) alone for 1B: sprites/KoopaShell.asm

.vanilla
%RAMToSpr(!154C, 14)
++
%RAMToSpr(!1558, 15)
%RAMToSpr(!1564, 16)
%RAMToSpr(!1570, 17)
%RAMToSpr(!157C, 18)
%RAMToSpr(!1594, 19)
%RAMToSpr(!15AC, 20)
%RAMToSpr(!15D0, 21)
%RAMToSpr(!15F6, 22)
%RAMToSpr(!1602, 23)
%RAMToSpr(!160E, 24)
%RAMToSpr(!1626, 25)
%RAMToSpr(!163E, 26)
%RAMToSpr(!187B, 27)
endif
STZ !14EC,x							;/
STZ !14F8,x							;\ Zero the fraction bits to prevent jittering.

Next:
DEX
BMI +
JMP FreezeAllSprites_loop
+
LDA $187A|!addr						;/
if !FreezeMiscTables				;|
STA !StartRAM+(!sprite_slots*29)	;| Backup the riding Yoshi flag.
else								;|
STA !StartRAM+(!sprite_slots*7)		;\
endif
RTS;RTL

; --------------------

BackupAllSpriteProperties:					; Pretty much the same stuff but for backing up the sprite tables in freeRAM when not frozen.
LDX #!sprite_slots-1
.loop
LDA !7FAB10,x
AND #$08
BNE .isCustom

LDA !9E,x
.checkBulletBill
CMP #$1C
BEQ +

CMP #$7B
BEQ .next

BRA .checkStatus

.isCustom
.checkMarioSprite
LDA !7FAB9E,x
CMP #!MarioSpriteNumber
BEQ .next

.checkStatus
LDA !14C8,x
BEQ .next
CMP #$01
BEQ +
CMP #$0B
BCS .next
+

JSR SprRAMTransfer

.next
DEX
BPL .loop
LDA $187A|!addr
if !FreezeMiscTables
STA !StartRAM+(!sprite_slots*29)
else
STA !StartRAM+(!sprite_slots*7)
endif
RTS;RTL

SprRAMTransfer:		; This is in a subroutine since it also needs to be accessed by some sprites in the loop when the freeze is active.

%SprToRAM(!E4, 0)
%SprToRAM(!14E0, 1)
%SprToRAM(!D8, 2)
%SprToRAM(!14D4, 3)
%SprToRAM(!AA, 4)
%SprToRAM(!B6, 5)
%SprToRAM(!14C8, 6)
if !FreezeMiscTables
%SprToRAM(!C2, 7)
%SprToRAM(!1504, 8)
%SprToRAM(!1510, 9)
%SprToRAM(!151C, 10)
%SprToRAM(!1528, 11)
%SprToRAM(!1534, 12)

LDA !7FAB10,x
AND #$08
BNE .customSprite ; if EQ, is vanilla

.vanilla
LDA !9E,x
CMP #$2F   ; added by
BEQ +      ; SJC
; CMP #$04
; BCC .NotKoopa
; CMP #$08
; BCC +
; .NotKoopa
%SprToRAM(!1540, 13)
+

%SprToRAM(!9E, 28)		;vanilla sprite number
BRA .toRAM

.customSprite
%SprToRAM(!1540, 13)
%SprToRAM(!7FAB9E, 28)	;custom sprite number

LDA !7FAB9E,x
CMP #$1B
BEQ ++					; leave 154C (contact disabled flag) alone for 1B: sprites/KoopaShell.asm

.toRAM
%SprToRAM(!154C, 14)
++
%SprToRAM(!1558, 15)
%SprToRAM(!1564, 16)
%SprToRAM(!1570, 17)
LDA #$01
STA !157C,x	; force all sprites to face left for spectator mode
%SprToRAM(!157C, 18)
%SprToRAM(!1594, 19)
%SprToRAM(!15AC, 20)
%SprToRAM(!15D0, 21)
%SprToRAM(!15F6, 22)
%SprToRAM(!1602, 23)
%SprToRAM(!160E, 24)
%SprToRAM(!1626, 25)
%SprToRAM(!163E, 26)
%SprToRAM(!187B, 27)

endif

RTS