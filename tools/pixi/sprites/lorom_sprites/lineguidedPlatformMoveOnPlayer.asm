;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; SMW Brown/Checkerboard Line-Guided Platform that (doesn't) move when stood on
;;
;; Should be pretty self explanatory. On extra bit set it won't move when stood on, otherwise it will move ONLY when stood on.
;;
;; Extra property byte 1 sets platform type. Zero - Brown platform, non-zero - checkerboard.
;;
;; By RussianMan, requested by FragOnCrack. Based on disassembly by imamelia.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;!1504 - saved extra bits
;!1602 - checkboard flag (if platform is brown platform or a checkerboard)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if !EXLEVEL
	!LayerLookUp		= $0BF6|!Base2			; 256 bytes of free RAM. Must be on shadow RAM.
	!L1_Lookup_Lo	= !LayerLookUp+96+96		; 32 bytes
	!L2_Lookup_Lo	= !LayerLookUp+96+96+16		; 16 bytes (shared)
	!L1_Lookup_Hi	= !LayerLookUp+96+96+32		; 32 bytes
	!L2_Lookup_Hi	= !LayerLookUp+96+96+32+16	; 16 bytes (shared)
endif

!WoodenTile1 = $60		; the left tile of the wooden platform
!WoodenTile2 = $60		; the middle tile of the wooden platform
!WoodenTile3 = $62		; the right tile of the wooden platform
!CheckerboardTile1 = $EA	; the left tile of the checkerboard platform
!CheckerboardTile2 = $EB	; the middle tile of the checkerboard platform
!CheckerboardTile3 = $EC	; the right tile of the checkerboard platform

XOffsetLo:
db $FC,$04,$FC,$04

XOffsetHi:
db $FF,$00,$FF,$00

YOffsetLo:
db $FC,$FC,$04,$04

YOffsetHi:
db $FF,$FF,$00,$00

BitTable:
db $80,$40,$20,$10,$08,$04,$02,$01

Data1:
db $15,$15,$15,$15,$0C,$10,$10,$10
db $10,$0C,$0C,$10,$10,$10,$10,$0C
db $15,$15,$10,$10,$10,$10,$10,$10
db $10,$10,$10,$10,$10,$10,$15,$15

Data2:
db $00,$00,$00,$00,$00,$00,$01,$02
db $00,$00,$00,$00,$02,$01,$00,$00
db $00,$00,$01,$02,$01,$02,$00,$00
db $00,$00,$02,$02,$00,$00,$00,$00

SpeedTableY1:

db $00,$10,$00,$F0,$F4,$FC,$F0,$10
db $04,$0C,$0C,$00,$10,$F0,$FC,$F4
db $F0,$10,$F0,$10,$F0,$10,$F8,$F8
db $08,$08,$10,$10,$00,$00,$F0,$10
db $10,$00,$F0,$F0,$0C,$04,$10,$F0
db $00,$F4,$F4,$FC,$F0,$10,$00,$0C
db $10,$F0,$10,$00,$10,$F0,$08,$08
db $F8,$F8,$F0,$F0,$00,$00,$10,$F0

SpeedTableX1:
db $10,$00,$10,$00,$0C,$10,$04,$00
db $10,$0C,$0C,$10,$04,$00,$10,$0C
db $10,$10,$08,$08,$08,$08,$10,$10
db $10,$10,$00,$00,$10,$10,$10,$10
db $00,$F0,$00,$F0,$F4,$F0,$00,$FC
db $F0,$F4,$F4,$F0,$00,$FC,$F0,$F4
db $F0,$F0,$F8,$F8,$F8,$F8,$F0,$F0
db $F0,$F0,$00,$00,$F0,$F0,$F0,$F0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
PHB
PHK
PLB
JSR LinePlatform2Init
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinePlatform2Init:
STZ !1504,x

.StandMove
LDA !extra_prop_1,x		;
BEQ .NotChecker			;

INC !1602,x			;flag that decides wether this is a checkerboard platform

.NotChecker
INC !1540,x			;
JSR LinePlatform2Main		;
JSR LinePlatform2Main		;

LDA !extra_bits,x		;
AND #$04			;
STA !1504,x			;
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR LinePlatform2Main
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinePlatform2Main:

; removed sprite number check (starts at $01D9A7)

LDY #$18		;
LDA !1602,x		; offset the sprite by a different amount
BEQ StoreOffset		; depending on which kind of platform it is
LDY #$28		;
StoreOffset:		;
STY $00			;

LDA !E4,x	;
PHA		;
SEC		;
SBC $00		; offset the sprite X position (this was an SBC $00, which is now unnecessary)
STA !E4,x		;        
STA $9A ;xlo
LDA !14E0,x	; right $18 pixels
PHA		;
SBC #$00		;
STA !14E0,x	;
STA $9B ;xhi

LDA !D8,x	;
PHA		;
SEC		;
SBC #$08		; offset the sprite Y position
STA !D8,x	;
STA $98 ;ylo
LDA !14D4,x	;
PHA		;
SBC #$00		; up 8 pixels
STA !14D4,x	;
STA $99 ;yhi

JSR Platform2GFX	; draw the platform

PLA		;
STA !14D4,x	; restore sprite position
PLA		;
STA !D8,x	;
PLA		;
STA !14E0,x	;
PLA		;
STA !E4,x	;

LDA !E4,x	;
PHA		; preserve sprite X position

JSR LineGuideHandlerMainRt

LDA !1504,x		;
STA !1626,x		;

PLA			;
SEC			;
SBC !E4,x		;
LDY !1528,x		; preserve $1528,x, which holds the high byte of the pointer
PHY			; to the line-guide table
EOR #$FF		;
INC			;
STA !1528,x		;

LDY #$18		;
LDA !1602,x	; offset the sprite by a different amount
BEQ StoreOffset2	; depending on which kind of platform it is
LDY #$28		;
StoreOffset2:	;
STY $00		;

LDA !E4,x	;
PHA		;
SEC		;
SBC $00		; offset the sprite X position
STA !E4,x		;        
LDA !14E0,x	;
PHA		;
SBC #$00		;
STA !14E0,x	;

LDA !D8,x	;
PHA		;
SEC		;
SBC #$08		; offset the sprite Y position
STA !D8,x	;
LDA !14D4,x	;
PHA		;
SBC #$00		; up 8 pixels
STA !14D4,x	;

JSL $01B44F|!BankB	; make the sprite solid
BCC NoContact		; if there is contact...

;LDA !1626,x	; and if the stationary flag is not clear already...
;BEQ NoContact	;

JSR InvertFlag

;STZ !1626,x	; clear this flag so that the sprite will move

STZ !1540,x	; and clear...some other timer

NoContact:	;

PLA		;
STA !14D4,x	; restore sprite position
PLA		;
STA !D8,x	;
PLA		;
STA !14E0,x	;
PLA		;
STA !E4,x		;
PLA		;
STA !1528,x	;

Return00:		;
RTS		;

InvertFlag:
LDA !1626,x	;
EOR #$04	;
STA !1626,x	;
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main line-guided sprite routine ($01D74D)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LineGuideHandlerMainRt:

LDA #$01
%SubOffScreen()

LDA !1540,x		; if the move timer is set...
BNE RunStatePtr		; skip the next check

LDA !C2,x		; always run "not on line guide" movement regardless (e.g. falling)
CMP #$02		;
BEQ RunStatePtr_RUN	;

LDA $9D			; if sprites are locked...
ORA !1626,x		; or the stationary flag is set...
BNE Return00		; return

RunStatePtr:		;
;INC !1626,x		; set movement flag so i doesn't move (unless player's standing)

LDA !C2,x		; sprite state

.RUN
JSL $0086DF|!BankB	; 16-bit pointer routine

dw State00		;
dw State01		;
dw State02		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 00
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State00:

LDY #$03		;

TileCheckLoop:	;

STY $1695|!Base2	;

LDA !E4,x	;
CLC		;
ADC XOffsetLo,y	;
STA $02		; set up an X position variable, 4 pixels left or right
LDA !14E0,x	;
ADC XOffsetHi,y	;
STA $03		;

LDA !D8,x	;
CLC		;
ADC YOffsetLo,y	;
STA $00		; set up a Y position variable, 4 pixels up or down
LDA !14D4,x	;
ADC YOffsetHi,y	;
STA $01		;

LDA !1540,x	; if the move timer is set...
BNE GoToPosSet	; skip the next part

LDA $00		;
AND #$F0	; sprite X position with the individual pixel nybble clear
STA $04		;
LDA !D8,x	;
AND #$F0	;
CMP $04		; if the sprite Y position is not the same as the X position...
BNE GoToPosSet	; go directly to the position setup routine

LDA $02		;
AND #$F0	; sprite Y position with the individual pixel nybble clear
STA $05		;
LDA !E4,x	;
AND #$F0	;
CMP $05		; if the sprite X position is not the same as the Y position...
BEQ DecAndLoop	; skip the position setup routine entirely and go to the end of the loop

GoToPosSet:

JSR PositionSetup	;
BNE AltIndex	;

WDM #$01
LDA $1693|!Base2	; check the low byte of the "acts like" setting of the Map16 tile that the sprite is touching
;JSR GetPosition
;JSR GetMap16_ActAs
CMP #$94		;
BEQ OnOffCheck2	; if it is 94 or 95...
CMP #$95		; then it is an on/off line guide slope
BNE Continue1	;

LDA $14AF|!Base2	;
BEQ DecAndLoop	;
BNE Continue1	;

OnOffCheck2:	;

LDA $14AF|!Base2	;
BNE DecAndLoop	;    

Continue1:	;

LDA $1693|!Base2	;
;JSR GetPosition
;JSR GetMap16_ActAs
CMP #$76		; if the tile number is less than 76...
BCC DecAndLoop	;
CMP #$9A	; or greater than 99...
BCC LineGuideTiles	; then it is not a line guide tile

DecAndLoop:

LDY $1695|!Base2	;
DEY		;
BPL TileCheckLoop	; loop 4 times

LDA !C2,x	; if we're running this code in sprite state 02...
CMP #$02		;
BEQ Return01	; terminate the code
LDA #$02		; if not,
STA !C2,x	; set the sprite state to 02

LDY !160E,x	; speed index
LDA !157C,x	; depending on sprite direction
BEQ NoAddToIndex	; if the sprite is moving left...
TYA		;
CLC		;
ADC #$20	; add $20 to the speed index
TAY		;
NoAddToIndex:	;
LDA SpeedTableY1,y;
BPL $01		; if the value is negative...
ASL		; left-shift it
PHY		;
ASL		; left-shift it once more...
STA !AA,x	; and store it to the sprite Y speed
PLY		;
LDA SpeedTableX1,y;
ASL		;
STA !B6,x		; set the sprite X speed
LDA #$10		;
STA !1540,x	; set the time to pause

Return01:		;
RTS		;

LineGuideTiles:

PHA		;
SEC		;
SBC #$76		; subtract 76 from the tile number so that the index begins at 00
TAY		;
PLA		; but we still want the actual tile number in A
CMP #$96		; if the tile is a line-guide end...
BCC NoAltIndex	; 

AltIndex:

LDY !160E,x	; then do this
BRA SkipChangePos	;

NoAltIndex:	;

LDA !D8,x	;
STA $08		; back up sprite position
LDA !14D4,x	;
STA $09		;
LDA !E4,x	;
STA $0A		;
LDA !14E0,x	;
STA $0B		;

LDA $00		; and then set the sprite position
STA !D8,x	;
LDA $01		; to the offset values from before
STA !14D4,x	;
LDA $02		;
STA !E4,x		;
LDA $03		;
STA !14E0,x	;

SkipChangePos:

PHB		; preserve the data bank
LDA #$07		; set the data bank to 07 (or 87)
PHA		;
PLB		;
LDA $FBF3,y	; $07FBF3-$07FC12: low byte of 16-bit pointer to line guide behaviors
STA !151C,x	;
LDA $FC13,y	; $07FC13-$07FC32: high byte of 16-bit pointer to line guide behaviors
STA !1528,x	;
PLB		;

LDA Data1,y	;
STA !1570,x	; not sure what this does

STZ !1534,x	;
TYA		; save the tile index
STA !160E,x	;

LDA !1540,x	; if the wait timer is set...
BNE SetState01	; change the sprite state to 01

STZ !157C,x	; set the sprite direction to right
LDA Data2,y	;
BEQ MoreSetups	;
TAY		;
LDA !D8,x	;
CPY #$01		;
BNE NoEORPixels	;
EOR #$0F		;
NoEORPixels:	;

BRA SkipLoadX	;

MoreSetups:	;

LDA !E4,x	;

SkipLoadX:

AND #$0F	;
CMP #$0A	;
BCC NoLeftDir	;
LDA !C2,x	;
CMP #$02		;
BEQ NoLeftDir	;
INC !157C,x	;
NoLeftDir:	;

LDA !D8,x	;
STA $0C		;
LDA !E4,x	;
STA $0D		;

JSR State01	;

LDA $0C		;
SEC		;
SBC !D8,x	;
CLC		;
ADC #$08	;
CMP #$10		;
BCS RestorePos2	;

LDA $0D		;
SEC		;
SBC !E4,x		;
CLC		;
ADC #$08	;
CMP #$10		;
BCS RestorePos2	;

SetState01:	;

LDA #$01		;
STA !C2,x	;
RTS		;

RestorePos2:

LDA $08		;
STA !D8,x	; set the sprite position
LDA $09		; to the values we stored before
STA !14D4,x	;
LDA $0A		;
STA !E4,x		;
LDA $0B		;
STA !14E0,x	;  

JMP DecAndLoop

PositionSetup:	; Some Map16-checking stuff.  I'm not even going to bother trying to comment this.
    LDA $00                     ;$01D94D    |\ 
    AND.b #$F0                  ;$01D94F    ||
    STA $06                     ;$01D951    ||
    LDA $02                     ;$01D953    ||
    LSR                         ;$01D955    || First push: $0X
    LSR                         ;$01D956    || Second push: $YX
    LSR                         ;$01D957    || (where Y/X are the tile's position)
    LSR                         ;$01D958    ||
    PHA                         ;$01D959    ||
    ORA $06                     ;$01D95A    ||
    PHA                         ;$01D95C    |/
    LDA $5B                     ;$01D95D    |
    AND.b #$01                  ;$01D95F    |
	
    BEQ .horizontal             ;$01D961    |
    PLA                         ;$01D963    |\ 
    LDX $01                     ;$01D964    ||
    CLC                         ;$01D966    ||
    ADC.l $00BA80|!BankB,X      ;$01D967    ||
    STA $05                     ;$01D96B    || Get tile pointer (vertical level).
    LDA.l $00BABC|!BankB,X      ;$01D96D    ||
    ADC $03                     ;$01D971    ||
    STA $06                     ;$01D973    ||
    BRA .getmap16               ;$01D975    |/
.horizontal                     ;           |
    PLA                         ;$01D977    |\ 
    LDX $03                     ;$01D978    ||
    CLC                         ;$01D97A    ||
if !EXLEVEL
	ADC.L !L1_Lookup_Lo,x
else
    ADC.l $00BA60|!BankB,X      ;$01D97B    || Get tile pointer (horizontal level).
endif
    STA $05                     ;$01D97F    ||
if !EXLEVEL
	LDA.L !L1_Lookup_Hi,x
else
    LDA.l $00BA9C|!BankB,X      ;$01D981    ||
endif
    ADC $01                     ;$01D985    ||
    STA $06                     ;$01D987    |/
.getmap16                       ;           |
if !SA1
	LDA #$40		            ; bank byte of pointer to tile low byte = $7E
else
	LDA #$7E		            ; bank byte of pointer to tile low byte = $7E
endif
    STA $07                     ;$01D98B    ||
    LDX.w $15E9|!Base2          ;$01D98D    ||
    LDA [$05]                   ;$01D990    ||
    STA.w $1693|!Base2          ;$01D992    ||
    INC $07                     ;$01D995    ||
    LDA [$05]                   ;$01D997    || Get tile number in $1693, high byte in A?
    PLY                         ;$01D999    ||  Seems to only work in certain X positions...?
    STY $05                     ;$01D99A    ||
    PHA                         ;$01D99C    ||
    LDA $05                     ;$01D99D    ||
    AND.b #$07                  ;$01D99F    ||
    TAY                         ;$01D9A1    ||
    PLA                         ;$01D9A2    ||
    AND.w BitTable,Y            ;$01D9A3    |/
    RTS                         ;$01D9A6    |

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 01
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State01:

LDA $9D		;
BNE Return02	; return if sprites are locked
LDA !157C,x	;
BNE State01Left	; run a slightly different routine if the sprite is facing left

State01Right:

LDY !1534,x	;

JSR MoveSprPos	;

INC !1534,x	;
LDA !187B,x	; if this sprite table is set...
BEQ SkipFrameChk1	;
LDA $13		;
LSR		;
BCC SkipFrameChk1	; then the frame counter increments again every other frame
INC !1534,x	;
SkipFrameChk1:	;

LDA !1534,x	;
CMP !1570,x	; if the first counter equals the second...
BCC Return02	;
STZ !C2,x	; reset the sprite state

Return02:		;
RTS

State01Left:	;

LDY !1570,x	;
DEY		;

JSR MoveSprPos	;

DEC !1570,x	; if this counter has reached 0...
BEQ SetState00	; set the sprite state to 00
LDA !187B,x	;
BEQ Return02	; if this sprite table is set...
LDA $13		;
LSR		;
BCC Return02	; then the counter decrements again every other frame
DEC !1570,x	;
BNE Return02	;

SetState00:	;

STZ !C2,x	;
RTS		;

MoveSprPos:	;

PHB		;
LDA #$07		; once again, the data bank should be 07/87
PHA		;
PLB		;
LDA !151C,x	; low byte of pointer
STA $04		;
LDA !1528,x	; high byte of pointer
STA $05		;

LDA ($04),y	;
AND #$0F	; low byte of the pointed-to address: amount to move the sprite on the X-axis
STA $06		;
LDA ($04),y	;
PLB		;
LSR #4		;
STA $07		;

LDA !D8,x	;
AND #$F0	;
CLC		;
ADC $07		; change the sprite's Y position
STA !D8,x	;

LDA !E4,x	;
AND #$F0	;
CLC		;
ADC $06		; change the sprite's X position
STA !E4,x		;

RTS		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 02
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State02:

LDA $9D		; if spites are locked...
BNE Return03	; return

JSL $01802A|!BankB	; update sprite position

LDA !1540,x	; if the wait timer is set...
BNE Return03	;

LDA !AA,x	;
CMP #$20	; or the sprite speed is less than 20 (actually, between A0 and 1F)...
BMI Return03	;

JMP State00	; return

Return03:	;
RTS		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Platform2GFX:

;not sure if it would've been better as a loop. would save space, but not sure in terms of optimization. regardless it is functional, so...

%GetDrawInfo()		;

LDA !1602,x		;
STA $01

LDA !D8,x		;
SEC			;
SBC $1C			;
STA $0301|!Base2,y		;
STA $0305|!Base2,y		;
STA $0309|!Base2,y		;
LDX $01			; if the sprite is a checkerboard platform...
BEQ Only3Tiles1		; we'll be drawing 5 tiles instead of 3
STA $030D|!Base2,y		;
STA $0311|!Base2,y		;
Only3Tiles1:		;
LDX $15E9|!Base2		;
LDA !E4,x		;
SEC			;
SBC $1A			;
STA $0300|!Base2,y		; set the tile X displacement
CLC			;
ADC #$10		;
STA $0304|!Base2,y		; second tile 16 pixels to the right of the first
CLC			;
ADC #$10		;
STA $0308|!Base2,y		; third tile 16 pixels to the right of the second
LDX $01			;
BEQ Only3Tiles2		; and, if necessary...
CLC			;
ADC #$10		;
STA $030C|!Base2,y		; fourth tile 16 pixels to the right of the third
CLC			;
ADC #$10		;
STA $0310|!Base2,y		; fifth tile 16 pixels to the right of the fourth
Only3Tiles2:		;

LDX $15E9|!Base2		;
LDA $01			; if the sprite is the wooden one...
BEQ WoodenTiles		; draw different tiles

LDA #!CheckerboardTile1	;
STA $0302|!Base2,y		; first tile
LDA #!CheckerboardTile2	;
STA $0306|!Base2,y		; second,
STA $030A|!Base2,y		; third,
STA $030E|!Base2,y		; and fourth tiles
LDA #!CheckerboardTile3		;
STA $0312|!Base2,y		; fifth tile
BRA SetUpTiles		;

WoodenTiles:		;

LDA #!WoodenTile1		;
STA $0302|!Base2,y		; first tile
LDA #!WoodenTile2		;
STA $0306|!Base2,y		; second,
STA $030A|!Base2,y		; third,
STA $030E|!Base2,y		; and fourth tiles...?
LDA #!WoodenTile3			;
STA $0312|!Base2,y		; fifth tile...? Maybe this graphics routine is shared by another sprite?...

SetUpTiles:		;

LDA $64				;
ORA !15F6,x			; no hardcoded palette this time, and the two platforms use the same one
STA $0303|!Base2,y		; properties for the first...
STA $0307|!Base2,y		; second...
STA $030B|!Base2,y		; third...
STA $030F|!Base2,y		; fourth...
STA $0313|!Base2,y		; and fifth tile
    
LDA $01				;
BNE Draw5Tiles			; set the number of tiles to be drawn as 3 or 5
LDA #!WoodenTile3		; if only 3...
STA $030A|!Base2,y		; make the third tile the end of the wooden platform
LDA #$02			; 3 tiles to draw
BRA FinishGFX			;

Draw5Tiles:			;
LDA #$04			; 5 tiles to draw
FinishGFX:		;
LDY #$02			; all tiles are 16x16
JSL $01B7B3		;
RTS			;






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetBlock - SA-1 Hybrid version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this routine will get Map16 value
; If position is invalid range, will return 0xFFFF.
;
; input:
; $98-$99 block position Y
; $9A-$9B block position X
; $1933   layer
;
; output:
; A Map16 lowbyte (or all 16bits in 16bit mode)
; Y Map16 highbyte
;
; by Akaginite
;
; It used to return FF but it also fucked with N and Z lol, that's fixed now
; Slightly modified by Tattletale
;
; Usage:
; jsl GetMap16_Main to get the map16 tile number
; jsl GetMap16_ActAs to get the map16 tile act as number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!EXLEVEL = 0
if (((read1($0FF0B4)-'0')*100)+((read1($0FF0B4+2)-'0')*10)+(read1($0FF0B4+3)-'0')) > 253
    !EXLEVEL = 1
endif

GetMap16_Main:
    PHX
    PHP
    REP #$10
    PHB
    LDY $98
    STY $0E
    LDY $9A
    STY $0C
    SEP #$30
    LDA $5B
    LDX $1933|!addr
    BEQ .layer1
    LSR A
.layer1
    STA $0A
    LSR A
    BCC .horz
    LDA $9B
    LDY $99
    STY $9B
    STA $99
.horz
if !EXLEVEL
    BCS .verticalCheck
    REP #$20
    LDA $98
    CMP $13D7|!addr
    SEP #$20
    BRA .check
endif
.verticalCheck
    LDA $99
    CMP #$02
.check
    BCC .noEnd
    REP #$20        ; \ load return value for call in 16bit mode
    LDA #$FFFF      ; /
    PLB
    PLP
    PLX
    TAY             ; load high byte of return value for 8bit mode and fix N and Z flags
    RTS
    
.noEnd
    LDA $9B
    STA $0B
    ASL A
    ADC $0B
    TAY
    REP #$20
    LDA $98
    AND.w #$FFF0
    STA $08
    AND.w #$00F0
    ASL #2          ; 0000 00YY YY00 0000
    XBA             ; YY00 0000 0000 00YY
    STA $06
    TXA
    SEP #$20
    ASL A
    TAX
    
    LDA $0D
    LSR A
    LDA $0F
    AND #$01        ; 0000 000y
    ROL A           ; 0000 00yx
    ASL #2          ; 0000 yx00
    ORA #$20        ; 0010 yx00
    CPX #$00
    BEQ .noAdd
    ORA #$10        ; 001l yx00
.noAdd
    TSB $06         ; $06 : 001l yxYY
    LDA $9A         ; X LowByte
    AND #$F0        ; XXXX 0000
    LSR #3          ; 000X XXX0
    TSB $07         ; $07 : YY0X XXX0
    LSR A
    TSB $08

    LDA $1925|!addr
    ASL A
    REP #$31
    ADC $00BEA8|!bank,x
    TAX
    TYA
if !sa1
    ADC.l $00,x
    TAX
    LDA $08
    ADC.l $00,x
else
    ADC $00,x
    TAX
    LDA $08
    ADC $00,x
endif
    TAX
    SEP #$20
if !sa1
    LDA $410000,x
    XBA
    LDA $400000,x
else
    LDA $7F0000,x
    XBA
    LDA $7E0000,x
endif
    SEP #$30
    XBA
    TAY
    XBA

    PLB
    PLP
    PLX
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine will return the act as value of the map16 block at the specified position.
;
; Output:
;  - Y: acts as high byte ($FF if block in invalid range)
;  - A: acts as low byte (also stored in $1693)
;
; Taken from worldpeace's line guide acts-like fix.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetMap16_ActAs:
    jsr GetMap16_Main
    sta $1693|!addr
    cpy #$FF
    beq .Return
    tya
-   xba
    lda $1693|!addr
    rep #$20
    asl
    adc.l $06F624
    sta $0D
    sep #$20
    lda.l $06F626
    sta $0F
    rep #$20
    lda [$0D]
    sep #$20
    sta $1693|!addr
    xba
    cmp #$02
    bcs -
    tay
    lda $1693|!addr
.Return
    rts

GetPosition:
    LDA !D8,x   ;ylo
    STA $98
    LDA !14D4,x ;yhi
    STA $99
    LDA !E4,x   ;xlo
    STA $9A
    LDA !14E0,x ;xhi
    STA $9B

	STZ $1933|!addr
	RTS