sa1rom

macro define_sprite_table(name, addr_sa1)
    !<name> = <addr_sa1>
endmacro

!CloneIndex				= $41A01A
!CloneCarriedItemIndex  = $41B82E
!addr = $6000

%define_sprite_table("E4", $322C) ; sprite low x
%define_sprite_table("14E0", $326E) ; sprite high x
%define_sprite_table("D8", $3216) ; sprite low y
%define_sprite_table("14D4", $3258) ; sprite high y

; sprite low y position
org $00ABFC
JSL low_y

low_y:
    CPX !CloneIndex ; if setting position for clone, try to attach its carried item
    BNE .return

.check_if_carrying_item
    PHA ; save low y
    LDA !CloneCarriedItemIndex
    CMP #$FF
    BEQ .pull_and_return

.set_item_position ; clone is carrying an item
    PHX
    LDX !CloneIndex
    PLA ; restore low y
    STA !D8,x ; set sprite low y

.pull_and_return
    PLA
.return
    RTL