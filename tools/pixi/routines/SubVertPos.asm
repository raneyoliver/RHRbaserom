;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $B829 - vertical mario/sprite position check - shared
; Y = 1 if mario below sprite??
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                    ;org $03B829 

?main:
    LDY #$00
    LDA $97
    XBA
    LDA $96
    REP #$20
    STA $0F ; mario Y
    SEP #$20
    
    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    SEC : SBC $0F
    SEP #$20
    BPL ?+
    INY
?+
    RTL



