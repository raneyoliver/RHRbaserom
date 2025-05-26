;===============================================================
; Sprite Freezing Utility
;===============================================================
; A general utility for freezing sprite states and properties
; 
; Usage:
;   JSR BackupAllSpriteProperties  ; Call once to store current state
;   JSR FreezeAllSprites          ; Call each frame to maintain frozen state
;
; To use in your sprite:
;   1. Include this file: incsrc "../routines/SpriteFreezing.asm"
;   2. Define !StartRAM with your chosen freeram address
;   3. Define !FreezeMiscTables if you want to freeze additional tables
;===============================================================

; Macro definitions
macro SprToRAM(addr, offset)
    LDA <addr>,x
    STA !StartRAM+(!sprite_slots*<offset>),x
endmacro

macro RAMToSpr(addr, offset) 
    LDA !StartRAM+(!sprite_slots*<offset>),x
    STA <addr>,x
endmacro

!sprite_slots ?= $16        ; Default to $16 slots if not defined
!FreezeMiscTables ?= 1      ; Default to freezing misc tables if not defined

; Freezes all sprites except:
; - Goal tape
; - Bullet Bills  
; - The sprite that called this routine
FreezeAllSprites:
    LDX #!sprite_slots-1
.loop
    ; Skip if sprite slot empty
    LDA !14C8,x
    BEQ .next
    
    ; Skip certain sprites
    LDA !7FAB10,x          ; Check if custom sprite
    AND #$08
    BNE .checkCustom
    
    ; Check vanilla sprites to skip
    LDA !9E,x
    CMP #$7B              ; Goal tape
    BEQ .next
    CMP #$1C              ; Bullet Bill
    BEQ .next
    BRA .doFreeze

.checkCustom
    ; Skip the calling sprite
    CPX $15E9|!addr
    BEQ .next

.doFreeze
    JSR FreezeSpriteSlot
    
.next
    DEX
    BPL .loop
    RTS

;===============================================================
; Backs up sprite states to RAM
;===============================================================
BackupAllSpriteProperties:
    LDX #!sprite_slots-1
.loop
    LDA !14C8,x            ; Skip empty slots
    BEQ .next
    
    JSR BackupSpriteSlot
    
.next
    DEX
    BPL .loop
    RTS

;===============================================================
; Freezes an individual sprite slot
;===============================================================
FreezeSpriteSlot:
    ; Always freeze position and speed
    %RAMToSpr(!E4, 0)      ; X position low byte
    %RAMToSpr(!14E0, 1)    ; X position high byte
    %RAMToSpr(!D8, 2)      ; Y position low byte
    %RAMToSpr(!14D4, 3)    ; Y position high byte
    %RAMToSpr(!B6, 4)      ; X speed
    %RAMToSpr(!AA, 5)      ; Y speed
    
if !FreezeMiscTables
    ; Freeze additional sprite tables
    %RAMToSpr(!C2, 6)      ; Sprite state
    %RAMToSpr(!1504, 7)    ; Misc table 1
    %RAMToSpr(!1510, 8)    ; Misc table 2
    %RAMToSpr(!151C, 9)    ; Misc table 3
    %RAMToSpr(!1528, 10)   ; Misc table 4
    %RAMToSpr(!1534, 11)   ; Misc table 5
    %RAMToSpr(!1540, 12)   ; Timer table
    %RAMToSpr(!154C, 13)   ; Timer table 2
    %RAMToSpr(!1558, 14)   ; Timer table 3
    %RAMToSpr(!1564, 15)   ; Timer table 4
    %RAMToSpr(!1570, 16)   ; Timer table 5
    %RAMToSpr(!157C, 17)   ; Direction table
    %RAMToSpr(!1594, 18)   ; Misc table 6
    %RAMToSpr(!15AC, 19)   ; Misc table 7
    %RAMToSpr(!15D0, 20)   ; Misc table 8
    %RAMToSpr(!15F6, 21)   ; Misc table 9
    %RAMToSpr(!1602, 22)   ; Misc table 10
    %RAMToSpr(!160E, 23)   ; Misc table 11
    %RAMToSpr(!1626, 24)   ; Misc table 12
    %RAMToSpr(!163E, 25)   ; Misc table 13
    %RAMToSpr(!187B, 26)   ; Misc table 14
endif
    
    ; Clear fraction bits to prevent jitter
    STZ !14EC,x
    STZ !14F8,x
    RTS

;===============================================================
; Backs up an individual sprite slot
;===============================================================
BackupSpriteSlot:
    %SprToRAM(!E4, 0)
    %SprToRAM(!14E0, 1)
    %SprToRAM(!D8, 2) 
    %SprToRAM(!14D4, 3)
    %SprToRAM(!B6, 4)
    %SprToRAM(!AA, 5)
    
if !FreezeMiscTables
    %SprToRAM(!C2, 6)
    %SprToRAM(!1504, 7)
    %SprToRAM(!1510, 8)
    %SprToRAM(!151C, 9)
    %SprToRAM(!1528, 10)
    %SprToRAM(!1534, 11)
    %SprToRAM(!1540, 12)
    %SprToRAM(!154C, 13)
    %SprToRAM(!1558, 14)
    %SprToRAM(!1564, 15)
    %SprToRAM(!1570, 16)
    %SprToRAM(!157C, 17)
    %SprToRAM(!1594, 18)
    %SprToRAM(!15AC, 19)
    %SprToRAM(!15D0, 20)
    %SprToRAM(!15F6, 21)
    %SprToRAM(!1602, 22)
    %SprToRAM(!160E, 23)
    %SprToRAM(!1626, 24)
    %SprToRAM(!163E, 25)
    %SprToRAM(!187B, 26)
endif
    RTS 