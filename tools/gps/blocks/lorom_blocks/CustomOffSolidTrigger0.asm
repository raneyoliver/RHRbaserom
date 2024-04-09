;This Block will be solid if a certain custom trigger is NOT activated.
;Change the !Number defined below.
;Act Like 25
;-----------------------
;by Decimating DJ
;edited by JackTheSpades

!Number = 0	;which trigger to use. Valid numbers are 0-F

print "Passable if custom trigger !Number is enabled"

db $42
JMP Code : JMP Code : JMP Code : JMP Code : JMP Code : JMP Code : JMP Code
JMP Code : JMP Code : JMP Code

if $!Number > $7
	!Add = $1
	!Number #= $!Number-$8
else
	!Add = $0
endif

Code:
	LDA $7FC0FC+!Add
	AND #$01<<$!Number
	BNE Jump
	LDY #$01
	LDA #$30
	STA $1693
Jump:
	RTL