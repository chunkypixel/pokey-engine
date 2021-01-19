
 ; --------------------------------------------------------------------------
 ; Synthpopalooza (music code)
 ; -------------------------------------------------------------------------- 

 ifconst pokeysupport 

; ---------------------------------------------------------------------------------------------
; LOOKUP TABLES
; ---------------------------------------------------------------------------------------------
CHANNLMDETBL:
    .byte #$50                      ;AtariToday
    .byte #$71						;GameComplete (Millie & Molly)
    .byte #$29                      ;Level1 (Popeye)
    .byte #$29                      ;Skull (Popeye)
;   CHANNLRESET TABLE (1-reset channels,0-skip[ie. sfx overlay background tune]) 
CHANNLRESET:
    .byte #$01                      ;AtariToday
    .byte #$01                      ;GameComplete (Millie & Molly)
    .byte #$01                      ;Level1 (Popeye)
    .byte #$00                      ;Skull (Popeye)
;   CNTVOLTBL TABLE
CNTVOLTBL:
    .byte $00,$c7,$a7,$a7           ;AtariToday
    .byte $00,$a4,$24,$a6           ;GameComplete (Millie & Molly)
    .byte $a6,$00,$00,$00           ;Level1 (Popeye)
    .byte $a6,$00,$00,$00           ;Skull (Popeye)
;   PRIORITY TABLE
PRIRTYTBL:
    .byte $02,$02,$02,$02           ;AtariToday
    .byte $02,$02,$02,$02			;GameComplete (Millie & Molly)
    .byte $02,$00,$00,$00           ;Level1 (Popeye)
    .byte $02,$00,$00,$00           ;Skull (Popeye)
;   CHANNEL TABLE ($00 - $03 ARE VALID)
CHANNLTBL:
    .byte $00,$01,$02,$03           ;AtariToday
    .byte $00,$01,$02,$03			;GameComplete (Millie & Molly)
    .byte $00,$00,$00,$00           ;Level1 (Popeye)
    .byte $01,$00,$00,$00           ;Skull (Popeye)
;   DECAY TABLE - DEFINES DECAY COUNT INDEXED BY NOTE DURATION
DECAYTBL:
    .byte $01,$01,$01,$01,$02,$02,$02,$02
    .byte $02,$03,$03,$03,$03,$03,$03,$03
    .byte $04,$04,$04,$04,$04,$04,$04,$04
    .byte $05,$05,$05,$05,$05,$05,$05,$05
    .byte $05,$05,$06,$06,$06,$06,$06,$06
    .byte $06,$06,$06,$06,$07,$07,$07,$07
    .byte $07,$07,$07,$07,$07,$07,$07,$07
    .byte $07,$08,$08,$08,$08,$08,$08,$08

CHANNA:
    .byte 0

;   FREQUENCY TABLE
NOTETBLHI:
	.byte >(TUNE00),>(TUNE01),>(TUNE02),>(TUNE03)	;AtariToday
	.byte >(TUNE04),>(TUNE05),>(TUNE06),>(TUNE07)	;GameComplete (Millie & Molly)
	.byte >(TUNE08),>(CHANNA),>(CHANNA),>(CHANNA)	;Level1 (Popeye)
	.byte >(TUNE09),>(CHANNA),>(CHANNA),>(CHANNA)	;Skull (Popeye)
NOTETBLLO:
	.byte <(TUNE00),<(TUNE01),<(TUNE02),<(TUNE03)	;AtariToday
	.byte <(TUNE04),<(TUNE05),<(TUNE06),<(TUNE07)	;GameComplete (Millie & Molly)
	.byte <(TUNE08),<(CHANNA),<(CHANNA),<(CHANNA)	;Level1 (Popeye)
	.byte <(TUNE09),<(CHANNA),<(CHANNA),<(CHANNA)	;Skull (Popeye)
;   DURATION TABLE
DURNTBLHI:
	.byte >(DURN00),>(DURN01),>(DURN02),>(DURN03)	;AtariToday
	.byte >(DURN04),>(DURN05),>(DURN06),>(DURN07)	;GameComplete (Millie & Molly)
	.byte >(DURN08),>(CHANNA),>(CHANNA),>(CHANNA)	;Level1 (Popeye)
	.byte >(DURN09),>(CHANNA),>(CHANNA),>(CHANNA)	;Skull (Popeye)
DURNTBLLO:
	.byte <(DURN00),<(DURN01),<(DURN02),<(DURN03)	;AtariToday
	.byte <(DURN04),<(DURN05),<(DURN06),<(DURN07)	;GameComplete (Millie & Molly)
	.byte <(DURN08),<(CHANNA),<(CHANNA),<(CHANNA)	;Level1 (Popeye)
	.byte <(DURN09),<(CHANNA),<(CHANNA),<(CHANNA)	;Skull (Popeye)
    
 endif