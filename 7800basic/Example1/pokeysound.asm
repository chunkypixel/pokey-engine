;-------------------------------------------------------------------------------
; POKEY ENGINE for 7800basic
; v1.03 (18 Feb 2021)
;
; Welcome to the 7800 pokey engine for music and sound effects playback on the Atari 
; 7800 Console. This engine was initially developed (based on the disassembly and 
; reverse engineering of Ms. Pac-man by Atari) by Perry Thuente (tep392) and 
; Bob DeCrescenzo (pacmanplus) for the purpose of providing pokey sound playback 
; for the Pac-man collection. The engine has since been enhanced and is now also being 
; used for other homebrew titles such as Millie & Molly 7800 (Matthew Smith), 
; Popeye (Darryl Guenther) and Danger Zone (Lewis Hill) thanks to the awesome music 
; abilities of Bobby Clark.
; 
; The 7800 pokey engine has been kindly open-sourced by the contributors and is
; freely available to the AtariAge community for use within any project.
; 
; The source is currently maintained by Matthew Smith (mksmith).
;-------------------------------------------------------------------------------
; CONTRIBUTORS:
; - Perry Thuente (tep392), Bob DeCrescenzo (pacmanplus), Bobby Clark (sythnpopalooza)
;   Mike Saarna (reveng), Matthew Smith (mksmith), Paul Lay (playsoft)
; ADDITIONAL CODING:
; - 7800basic POKEY base pokeysound.asm code (reveng)
; - Original 7800basic integration (mksmith)
; ADDITIONAL TESTING:
; - Robert Tuccitto (trebor)
;-------------------------------------------------------------------------------
; CHANGELOG:
; v1.03 - re-implemented CHANNLSKCTLS lookup (mksmith) 
; v1.02 - renamed SKIPCHECKFORPOKEY to SKIPINITFORCONCERTO and verified changes work (mksmith, trebor)
; v1.01 - updated SKIPCHECKFORPOKEY process to better handle $450 detection (playsoft)
; v1.00 - open sourced to Github (mksmith)
; v0.11 - added queue scheduling (playsoft) and SKIPCHECKFORPOKEY flag (Concerto issue)
;       - added RESETPOLYON and CHANNLRESETON table flags (mksmith)
; v0.10 - removed number of channels (not required) and added a tune-by-tune reset table (mksmith)
; v0.9  - removed SKCTL set and added ability to set number of channels to activate (mksmith)
; v0.8  - added MUTEMASKRESTFLG const so rest value can be customised (mksmith)
; v0.7  - re-implemented MUTEMASK change (reveng)
; v0.6  - fix 16-bit mode, SKCTL, or any mode requiring one channel be silenced and stops popping noises (sythnpopalooza) 
; v0.5  - 7800basic Pause Support (mksmith)
; v0.4  - 7800basic PAL Support (mksmith) [suggestion on how to implement by reveng]
; v0.3  - Reset poly support (sythnpopalooza)
; v0.2  - Added PLAYPOKEYSFX enhancements, STOPPOKEYSFX (mksmith)
; v0.1  - Initial version provided by pacmanplus and sythnpopalooza
; -------------------------------------------------------------------------------
; HOW TO USE:
; - copy this file into the base root folder. 7800basic will automagically
;   replace the base pokeysound.asm file in 7800basic during compilation
; - inline pokeyconfig.asm into your game source (this should be the end 
;   of the last shared bank so it can be accessed at all times)
; - inline your musicxxx.asm file(s) into your game source. There can be one 
;   of more of these files spread across multiple banks depending on how you game is 
;   structured but in reality as with bank sharing the tune data MUST be available 
;   to be currently active bank.
; - refer to example.78b for how you can fully implement this process
; ADDTIONAL NOTES:
; - tunes can be moved into RAM and played from there as required
; COMPILING FOR THE CONCERTO BETA
; - enable the SKIPINITFORCONCERTO flag
; -------------------------------------------------------------------------------
; 7800basic:
;
; 1. Add the following vars into your 7800basic source:
; dim POKEYADR = $450   ;$450 (modern homebrew) or $4000
; dim TUNEAREA = $2200  ;range $2200-$2246             
; dim SOUNDZP =  y.z    ;all pointers must be located in zeropage
; Note: The TUNEAREA location or SOUNDZP vars can be changed to suit your requirements.
;
; 2. Include the following (topscreenroutine) to service the player each frame:
;topscreenroutine
;  rem call the pokey servicing routine
;  asm
;    jsr SERVICEPOKEYSFX
;end
; return
; --------------------------------------------------------------------------

 ifnconst pokeysupport 
; wrappers for any used features when pokeysupport is disabled
PLAYPOKEYSFX
STOPPOKEYSFX
.PausePokeySfx
STOPTUN
.RestartPokeySfx
STARTTUN
SERVICEPOKEYSFX
    RTS
 else
pokeysoundmodulestart

;    RAM VARIABLES
TUNESOFF        EQU TUNEAREA+$0000          ;1 BYTE  - FLAG FOR ALL TUNES OFF
TUNNUM          EQU TUNEAREA+$0001          ;1 BYTE  - CURRENT TUNE NUMBER BEING PROCESSED
TUNCHANNEL      EQU TUNEAREA+$0002          ;1 BYTE  - CONVERTED FOR INDEX INTO POKEY CHANNEL REGISTERS
TUNCTL          EQU TUNEAREA+$0003          ;1 BYTE  - TUNE AUDCTL VALUE
TUNLP           EQU TUNEAREA+$0004          ;1 BYTE  - TUNE HAS LOOPED (ONE FRAME ONLY)
PALCNT          EQU TUNEAREA+$0005          ;1 BYTE  - FOR PAL WE NEED TO PLAY EXTRA LOOP EVERY 5TH FRAME
TUNON           EQU TUNEAREA+$0006          ;4 BYTES - FLAG FOR TUNE PLAYING BY CHANNEL
NOTELO          EQU TUNEAREA+$000A          ;4 BYTES - INDEX INTO NOTE TABLE LOW
NOTEHI          EQU TUNEAREA+$000E          ;4 BYTES - INDEX INTO NOTE TABLE HI
CTLVOL          EQU TUNEAREA+$0012          ;4 BYTES - CONTROL / VOLUME VALUE BY CHANNEL
TUNINDEX        EQU TUNEAREA+$0016          ;4 BYTES - TUNE NUMBER BY CHANNEL
TUNFRM          EQU TUNEAREA+$001A          ;4 BYTES - NUMBER OF FRAMES (DURATION COUNT)
TUNPRIOR        EQU TUNEAREA+$001E          ;4 BYTES - TUNE PRIORITY BY CHANNEL
DURNLO          EQU TUNEAREA+$0022          ;4 BYTES - INDEX INTO DURATION TABLE LOW
DURNHI          EQU TUNEAREA+$0026          ;4 BYTES - INDEX INTO DURATION TABLE HI
DCYSTOR         EQU TUNEAREA+$002A          ;4 BYTES - FOR NOTE DECAY BY CHANNEL
FREQCNT         EQU TUNEAREA+$002E          ;4 BYTES - FOR NOTE DECAY BY CHANNEL
CTLSAV          EQU TUNEAREA+$0032          ;4 BYTES - TO SAVE THE CONTROL VALUE
MUTEMASK        EQU TUNEAREA+$0036          ;4 BYTES - FLAG FOR MUTEMASK
SKCTLSSAV       EQU TUNEAREA+$003A          ;1 BYTE  - TO SAVE SKCTLS VALUE

REQUEST_QUEUE   EQU SKCTLSSAV+1             ;8 BYTES - POKEY sfx queue
IN_INDEX        EQU REQUEST_QUEUE+8         ;1 BYTE
OUT_INDEX       EQU IN_INDEX+1              ;1 BYTE

POKEY_TEMP1     EQU OUT_INDEX+1             ;1 BYTE (do not use global temps in an ISR)
POKEY_TEMP2     EQU POKEY_TEMP1+1           ;1 BYTE

;    COMPILE FLAGS
; REM out to exclude
;SKIPINITFORCONCERTO = 1                     ;Skip 7800basic CheckForPokey process (Concerto beta)
MUTEMASKON = 1                              ;Use the advanced MUTEMASK state
RESETPOLYON = 1                             ;Use the advanced RESETPOLY state
CHANNLRESETON = 1                           ;Use the CHANNLRESET table to identify whether a tune resets all channels on playback
                                            ;This works well when you have sfx overlaying background tunes
; mutemask flag value
MUTEMASKRESTFLG = 0                         ;Determines tune value to activate MUTEMASK rest

;    INTERNAL REFERENCES
POAUDF0         EQU POKEYADR+$00
POAUDC0         EQU POKEYADR+$01
POAUDF1         EQU POKEYADR+$02
POAUDC1         EQU POKEYADR+$03
POAUDF2         EQU POKEYADR+$04
POAUDC2         EQU POKEYADR+$05
POAUDF3         EQU POKEYADR+$06
POAUDC3         EQU POKEYADR+$07
POAUDCTL        EQU POKEYADR+$08            ; Audio Control
STIMER          EQU POKEYADR+$09
RANDOM          EQU POKEYADR+$0A            ; Random number (read-only)
SKCTLS          EQU POKEYADR+$0F            ; Serial Port control

;   USER FEATURE
PLAYPOKEYSFX
    LDY IN_INDEX                            ; add it to the sfx request queue
    STA REQUEST_QUEUE,Y
    INY
    TYA
    AND #$07
    STA IN_INDEX
    RTS

;   what PLAYPOKEYSFX used to do...
;   now called in the initial part of SERVICEPOKEYSFX to avoid reentrancy issues
PROCESSPOKEYSFXREQUEST
    STA POKEY_TEMP2                         ; store (to set channel mode)
    ASL                                     ; take number in accumulator (provided from 7800basic when called temp1 = PLAYPOKEYSFX(value))
    ASL                                     ; and multiply number by 4
    STA POKEY_TEMP1                         ; then store
    LDY POKEY_TEMP2                         ; load y to lookup tables

INITPROCESSPOKEYSFXREQUEST
 ifconst CHANNLRESETON
    LDA CHANNLRESET,Y                       ; reset requested?
    CMP #00
    BEQ SKIPPROCESSPOKEYSFXREQUEST
 endif
    JSR STOPPOKEYSFX                        ; stop anything currently playing
    LDA CHANNLMDETBL,Y                      ; 16-bit mode on channels 0 and 1
    STA TUNCTL                              ; store (to use in resetpoly)
    STA POAUDCTL
    LDA CHANNLSKCTLS,Y                      ; two-tone mode
    STA SKCTLSSAV                           ; save for later use
    STA SKCTLS
    LDA #$06                                ; reset pal repeat counter
    STA PALCNT
SKIPPROCESSPOKEYSFXREQUEST
    LDA POKEY_TEMP1                         ; CH1
    JSR DOTUNE
    INC POKEY_TEMP1                         ; CH2
    LDA POKEY_TEMP1
    JSR DOTUNE  
    INC POKEY_TEMP1                         ; CH3
    LDA POKEY_TEMP1
    JSR DOTUNE  
    INC POKEY_TEMP1                         ; CH4
    LDA POKEY_TEMP1
    JSR DOTUNE
EXITPLAYPOKEYSFX
    RTS

;   USER FEATURE
STOPPOKEYSFX 
    LDA #$00
    JSR KILLTUNE
    LDA #$01
    JSR KILLTUNE
    LDA #$02
    JSR KILLTUNE
    LDA #$03
    JSR KILLTUNE
    JSR CLEARTUN
    JSR STOPTUN
    JMP STARTTUN

;   TUNES - THESE ROUTINES HANDLE ALL OF THE SOUNDS

;   TURN OFF ALL SOUNDS
.PausePokeySfx
STOPTUN
    LDA #$00
    STA POAUDC0
    STA POAUDC1
    STA POAUDC2
    STA POAUDC3
    LDA #$01
    STA TUNESOFF
    RTS

;   TURN ON ALL SOUNDS
.RestartPokeySfx
STARTTUN
    LDA #$00
    STA TUNESOFF
    RTS

;   THIS ROUTINE ERASES ALL TUNES
;   X AND Y ARE PRESERVED
CLEARTUN
    TXA                                     ;STACK REGISTERS
    PHA
    TYA
    PHA
    LDX #$03
CTLOOP
    JSR ENDTUNE                             ;ERASE CURRENT TUNE
    DEX
    BPL CTLOOP
    PLA                                     ;UNSTACK REGISTERS
    TAY
    PLA
    TAX
    RTS

;   ROUTINE TO KILL A PARTICULAR TUNE - IF IT IS RUNNING
;   INPUT: TUNE NUMBER IN A
;   X AND Y ARE PRESERVED
KILLTUNE
    STA TUNNUM                              ;SAVE IT
    TXA                                     ;STACK REGISTERS
    PHA
    TYA
    PHA
    LDX #$03                                ;CHECK ALL CHANNELS
KTLOOP
    LDA TUNON,X                             ;SEE IF CHANNEL ON
    BEQ KTNEXT
    LDA TUNINDEX,X                          ;SEE IF HAS TUNE TO BE KILLED
    CMP TUNNUM
    BNE KTNEXT
    JSR ENDTUNE                             ;ERASE IT
KTNEXT
    DEX
    BPL KTLOOP
    PLA                                     ;UNSTACK REGISTERS
    TAY
    PLA
    TAX
    RTS

;   THIS ROUTINE CLEARS OUT A TUNE CHANNEL
;   INPUT: X IS CHANNEL
ENDTUNE
    LDA #$00
    STA TUNON,X                             ;INDICATE CHANNEL CLEAR
    STA TUNINDEX,X                          ;CLEAR TUNE INDEX
    STA DCYSTOR,X
    STA FREQCNT,X
    RTS

;   THIS ROUTINE ENTERS A TUNE INTO ONE OF THE SOUND CHANNELS IF IT CAN
;   INPUT:  TUNE NUMBER IN A
;   X AND Y ARE PRESERVED
DOTUNE
    STA TUNNUM                              ;SAVE IT
    ;LDA AUTOPLAY                           ;IF IN AUTOPLAY - NO SOUND
    ;BEQ DTCONT
    ;RTS
DTCONT
    TXA                                     ;STACK REGISTERS
    PHA
    TYA
    PHA
    LDY TUNNUM                              ;SEE IF WE CAN PUT IT IN
    LDX CHANNLTBL,Y                         ;GET WHAT CHANNEL TO TRY TO PUT IT IN
    LDA TUNON,X                             ;SEE IF CHANNEL OPEN
    BEQ DTDOIT
    LDA PRIRTYTBL,Y                         ;SEE IF WE CAN BUMP CHANNEL
    CMP TUNPRIOR,X
    BMI DTOUT
DTDOIT
    LDA TUNNUM
    TAY                                     ;PUT TUNE IN Y
    STA TUNINDEX,X                          ;SET THE TUNE INDEX
    LDA #$00                                ;TURN TUNE OFF WHILE CHANGING IT
    STA TUNON,X
    LDA CNTVOLTBL,Y                         ;GET TUNE CONTROL / VOLUME
    STA CTLVOL,X
    STA CTLSAV,X                            ;USED TO RESTORE AFTER DECAY
    LDA NOTETBLLO,Y                         ;GET TUNE FREQUENCY LOW ADDRESS
    STA NOTELO,X
    LDA NOTETBLHI,Y                         ;GET TUNE FREQUENCY HIGH ADDRESS
    STA NOTEHI,X
    LDA DURNTBLLO,Y                         ;GET TUNE DURATION LOW ADDRESS
    STA DURNLO,X
    LDA DURNTBLHI,Y                         ;GET TUNE DURATION HIGH ADDRESS
    STA DURNHI,X
    LDA PRIRTYTBL,Y                         ;SET PRIORITY
    STA TUNPRIOR,X
    LDA #$01                                ;SET FREQ, CTL, AND VOL TO BE SET
    STA TUNFRM,X
    STA TUNON,X                             ;AND TURN THE TUNE ON!
DTOUT
    PLA                                     ;UNSTACK REGISTERS
    TAY
    PLA
    TAX
    RTS

;   THIS ROUTINE IS CALLED EVERY VBLANK TO TAKE CARE OF TUNES
;   REGISTERS ARE NOT SAVED
;   USER FEATURE
SERVICEPOKEYSFX
    LDY OUT_INDEX                           ;Read through the sfx request queue
    CPY IN_INDEX
    BEQ ALLSFXREQUESTSPROCESSED

READSFXREQUEST
    LDA REQUEST_QUEUE,Y
    JSR PROCESSPOKEYSFXREQUEST              ;Process the sfx request
    LDY OUT_INDEX
    INY
    TYA
    AND #$07
    TAY
    STY OUT_INDEX
    CPY IN_INDEX
    BNE READSFXREQUEST

ALLSFXREQUESTSPROCESSED
    LDA pausestate                          ;CONSOLE PAUSED?
    BEQ SKIPPAUSE
    RTS
SKIPPAUSE 
    LDA #$00                                ;RESET TUNLP FLAG
    STA TUNLP
    LDX #$03                                ;FOUR TUNES CHANNELS, START WITH LAST
    LDA TUNESOFF
    BEQ TUNLOOP
    RTS
TUNLOOP
    TXA
    ASL
    STA TUNCHANNEL                          ;CHANNELS ARE OFFSET 0, 2, 4, 6 IN THE POKEY
    TAY
    LDA TUNON,X
    BNE TUNBODY

 ifconst MUTEMASKON
    AND MUTEMASK,X                          ;+ MUTEMASK KLUDGE
 endif

    STA POAUDC0,Y                           ;CHANNEL OFF - MAKE SURE VOLUME OFF
    JMP TUNNEXT
TUNBODY
    DEC TUNFRM,X                            ;SEE IF WE'RE DONE WITH THIS SOUND
    BEQ TUNFRMFRQ                           ;YES - GET NEXT NOTE / DURATION
    DEC FREQCNT,X                           ;REDUCE THE NUMBER OF FRAMES UNTIL NEXT DECAY
    BEQ DEC_VOLUME
    JMP TUNNEXT                             ;IF WE AREN'T AT ZERO YET, DON'T DECAY
DEC_VOLUME
    LDA DCYSTOR,X                           ;RESET THE DECAY FOR THE NEXT COUNT
    STA FREQCNT,X
    LDA CTLVOL,X                            ;IF VOLUME ALREADY 0 DO NOT DECREMENT
    AND #$0F
    BEQ TUNNEXT
    DEC CTLVOL,X                            ;DECREMENT THE VOLUME
    LDA CTLVOL,X
    LDY TUNCHANNEL

 ifconst MUTEMASKON
    AND MUTEMASK,X                          ;+ MUTEMASK KLUDGE
 endif

    STA POAUDC0,Y
    JMP TUNNEXT                             ;GO TO NEXT CHANNEL 
TUNFRMFRQ
    LDA DURNLO,X                            ;GET THE CURRENT DURATION
    STA SOUNDZP
    LDA DURNHI,X
    STA SOUNDZP+1
    LDY #$00
    LDA (SOUNDZP),Y
    BEQ TUNEND                              ;$00 IN DURATION MEANS TUNE IS OVER
    STA TUNFRM,X
    TAY
    LDA DECAYTBL,Y                          ;GET THE CURRENT DECAY VALUE INDEXED BY NOTE
    STA DCYSTOR,X                           ;STORE IT HERE TO REFRESH THE COUNTER FOR THE NEXT DECAY
    STA FREQCNT,X                           ;ALSO STORE IT HERE FOR TUNER
    LDY TUNCHANNEL
    LDA CTLSAV,X
    STA CTLVOL,X                            ;RESTORE THE ORIGINAL CONTROL AND VOLUME FOR NEXT NOTE
    AND #$0f                                ;REVENG - STATIC REMOVAL - ensure 0 write is skipped
    BEQ SKIPWRITEZERO
    LDA CTLSAV,X

 ifconst MUTEMASKON
    ;;AND MUTEMASK,X                            ;+ MUTEMASK KLUDGE (MAY NOT WORK)
 endif

    STA POAUDC0,Y
SKIPWRITEZERO
    LDA NOTELO,X                            ;GET THE CURRENT FREQUENCY
    STA SOUNDZP
    LDA NOTEHI,X
    STA SOUNDZP+1

 ifconst MUTEMASKON
    LDA #$ff
    STA MUTEMASK,X
 endif

    LDY #$00
    LDA (SOUNDZP),Y
    LDY TUNCHANNEL

 ifconst MUTEMASKON                                 
    CMP #MUTEMASKRESTFLG                    ; MUTEMASK REST indicator (advised by Bobby)
    BNE SKIPFLAGREST                        ;+ MUTEMASK KLUDGE
    LDA #$f0
    STA MUTEMASK,X
    AND CTLSAV,X
    STA POAUDC0,Y
    LDA #$00
SKIPFLAGREST
 endif

    STA POAUDF0,Y
    INC NOTELO,X
    BNE TUNNEXTNOTE
    INC NOTEHI,X
TUNNEXTNOTE
    INC DURNLO,X
    BNE TUNNEXT
    INC DURNHI,X
TUNNEXT
    DEX
    CPX #$00
    BMI TUNEXIT
    JMP TUNLOOP
TUNEXIT
    LDA paldetected                         ;PAL?
    BEQ SKIPPALREPEAT                       ;if not skip
    LDA TUNON                               ;tune playing?
    BEQ SKIPPALREPEAT                       ;if not skip
    DEC PALCNT                              ;dec counter
    BNE SKIPPALREPEAT                       ;reached 0?
    LDA #$06                                ;if so reset
    STA PALCNT                              ;counter and
    JMP SERVICEPOKEYSFX                     ;play a second time this frame
SKIPPALREPEAT
    RTS

TUNEND
    LDA NOTELO,X                            ;SEE IF WE SHOULD REPEAT
    STA SOUNDZP
    LDA NOTEHI,X
    STA SOUNDZP+1
    LDY #$00
    LDA (SOUNDZP),Y
    BMI TUNRESTART
    JSR ENDTUNE
    JMP TUNNEXT
TUNRESTART
    LDA #$01                                ;SET tune loop flag
    STA TUNLP

    LDA TUNINDEX,X                          ;GET TUNE NUMBER
    TAY
    LDA CNTVOLTBL,Y                         ;GET TUNE CONTROL / VOLUME
    STA CTLVOL,X
    STA CTLSAV,X                            ;USED TO RESTORE AFTER DECAY
    LDA NOTETBLLO,Y                         ;GET TUNE FREQUENCY LOW ADDRESS
    STA NOTELO,X
    LDA NOTETBLHI,Y                         ;GET TUNE FREQUENCY HIGH ADDRESS
    STA NOTEHI,X
    LDA DURNTBLLO,Y                         ;GET TUNE DURATION LOW ADDRESS
    STA DURNLO,X
    LDA DURNTBLHI,Y                         ;GET TUNE DURATION HIGH ADDRESS
    STA DURNHI,X
    LDY TUNCHANNEL

    JSR RESETPOLY
    LDA CTLVOL,X

 ifconst MUTEMASKON
    AND MUTEMASK,X                          ;+ MUTEMASK KLUDGE
 endif

    STA POAUDC0,Y                           ;STORE THE CONTROL / VOLUME IN THE CHANNEL
    LDA #$01                                ;SET FREQ, CTL, AND VOL TO BE SET
    STA TUNFRM,X
    JMP TUNNEXT
    
RESETPOLY
 ifconst RESETPOLYON
    ; ---- CURRENT ----
    LDA #$00
    STA SKCTLS
    ; the period of resetting POKEY (SKCTL = 0) should last for
    ; at least 17 cycles to clear the longest 17-bit polycounter
    ; set AUDF2 register with selector value needed to reach desired E6
    ; poly4 element by channel 1
    LDA #$02 ; 2 cycles
    STA POAUDF2 ; 4 cycles
    NOP ; 2 cycles
    STA STIMER ; 4 cycles
    ; finish resetting
    LDA SKCTLSSAV ; 2 cycles
    STA SKCTLS ; 4 cycles
 endif
    RTS

; ---------------------------------------------------------------------------------------------
; 7800basic code - validate for pokey chip
; ---------------------------------------------------------------------------------------------
checkpokeyplaying
schedulepokeysfx
         rts

         ; pokey detection routine. we check for pokey in the XBOARD/XM location,
         ; and the standard $4000 location.
         ; if pokey the pokey is present, this routine will reset it.

detectpokeylocation
         ;XBoard/XM...
         ldx #2
detectpokeyloop
         lda XCTRL1s
         ora #%00010100
         and POKEYXMMASK,x
         sta XCTRL1s
         sta XCTRL1

         lda POKEYCHECKLO,x
         sta pokeybaselo
         lda POKEYCHECKHI,x
         sta pokeybasehi
         jsr checkforpokey
         lda pokeydetected
         beq foundpokeychip
         dex
         bpl detectpokeyloop
foundpokeychip
         eor #$ff ; invert state for 7800basic if...then test
         sta pokeydetected
         rts

POKEYXMMASK
         ;     XM POKEY on    XM POKEY off   XM POKEY off
         .byte %11111111,     %11101111,     %11101111

POKEYCHECKLO
    .byte <$0450, <$0450, <$4000
POKEYCHECKHI
    .byte >$0450, >$0450, >$4000

checkforpokey
         ldy #$0f
         lda #$00
         sta pokeydetected          ; start off by assuming pokey will be detected
 ifconst SKIPINITFORCONCERTO
         cpx #$00                   ; last loop in detectpokeylocation?
         beq manualpokeyinit        ; yes, then detect and init POKEY
         dec pokeydetected          ; otherwise not detected
         rts
manualpokeyinit
         ; CONCERTO beta is currently not initialising correctly using the default 7800basic process
         ; manually initialise
         LDA #$00
         STA POAUDCTL
         STA SKCTLS
         LDA #$03
         STA SKCTLS
 else
         ;DEFAULT check
resetpokeyregistersloop
         sta (pokeybase),y
         dey
         bpl resetpokeyregistersloop

         ldy #PAUDCTL
         sta (pokeybase),y
         ldy #PSKCTL
         sta (pokeybase),y

         ; let the dust settle...
         nop
         nop
         nop

         lda #4
         sta temp9
pokeycheckloop1
         ; we're in reset, so the RANDOM register should read $ff...
         ldy #PRANDOM
         lda (pokeybase),y
         cmp #$ff
         bne nopokeydetected
         dec temp9
         bne pokeycheckloop1

         ; take pokey out of reset...
         ldy #PSKCTL
         lda #3
         sta (pokeybase),y
         ldy #PAUDCTL
         lda #0
         sta (pokeybase),y

         ; let the dust settle again...
         nop
         nop
         nop

         lda #4
         sta temp9 
pokeycheckloop2
         ; we're out of reset, so RANDOM should read non-$ff...
         ldy #PRANDOM
         lda (pokeybase),y
         cmp #$ff
         beq skippokeycheckreturn
         rts
skippokeycheckreturn
         dec temp9
         bne pokeycheckloop2
nopokeydetected
         dec pokeydetected ; pokeydetected=#$ff

 endif
         rts

pokeysoundmoduleend

 echo "  custom pokeysound assembly: ",[(pokeysoundmoduleend-pokeysoundmodulestart)]d," bytes"

 endif
 