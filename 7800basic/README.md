# 7800 Pokey Engine

The 7800 pokey engine for music and sound effects playback on the Atari 7800 Console. This engine was initially developed (based on the disassembly and reverse engineering of Ms. Pac-man by Atari) by Perry Thuente (tep392) and Bob DeCrescenzo (pacmanplus) for the purpose of providing pokey sound playback for the Pac-man Collection. The engine is also being used for other homebrew title such as Millie & Molly 7800 (Matthew Smith), Popeye (Darryl Guenther) and Danger Zone (Lewis Hill) thanks to the awesome music abilities of Bobby Clark.

The 7800 pokey engine has now been kindly open-sourced by the contributors and is freely available to the AtariAge community for use within any project. 

The source is currently maintained by Matthew Smith (mksmith).

## Contributors
The following people have contributed to the pokey engine:

* Perry Thuente (tep392)
* Bob DeCrescenzo (pacmanplus)
* Bobby Clark (sythnpopalooza)
* Mike Saarna (msaarna)
* Matthew Smith (mksmith) 
* Paul Lay (playsoft)

## 7800basic release
> The 7800basic version contains initialisation and base framework code provide by Mike Saarna from the 7800basic project. 

### v1.00 (19 Jan 2021)
#### CHANGELOG
* v1.00 - open sourced to Github 
* v0.11 - added queue scheduling (playsoft) and SKIPCHECKFORPOKEY flag Concerto issue). Added RESETPOLYON and CHANNLRESETON table flags (mksmith)
* v0.10 - removed number of channels (not required) and added a tune-by-tune reset table (mksmith)
* v0.9  - removed SKCTL set and added ability to set number of channels to activate (mksmith)
* v0.8  - added MUTEMASKRESTFLG const so rest value can be customised (mksmith)
* v0.7  - re-implemented MUTEMASK change (msaarna)
* v0.6  - fix 16-bit mode, SKCTL, or any mode requiring one channel be silenced and stops popping noises (sythnpopalooza) 
* v0.5  - 7800basic Pause Support (mksmith)
* v0.4  - 7800basic PAL Support (mksmith) [suggestion on how to implement by msaarna]
* v0.3  - Reset poly support (sythnpopalooza)
* v0.2  - Added PLAYPOKEYSFX enhancements, STOPPOKEYSFX (mksmith)
* v0.1  - Initial version provided by pacmanplus and sythnpopalooza

### HOW TO USE
* copy this file into the base root folder. 7800basic will automagically replace the base pokeysound.asm in 7800basic with this file during compilation
* inline pokeyconfig.asm into your game source (generally within a shared bank so it can be accessed at all times)
* inline your music.asm file(s) into your game source. These can be within a shared back or within a bank that will be active during playback.
* refer to example.78b for how you can fully implement this process

#### ADDTIONAL NOTES
* tunes can be moved into RAM and played from there as required

## 7800basic changes
The following code is required to be inserted into your 7800basic source:

1. Add the following vars:
~~~~ 
 dim POKEYADR = $450   ;$450 (modern homebrew) or $4000
 dim TUNEAREA = $2200  ;range $2200-$2246             
 dim SOUNDZP = y.z     ;all pointers must be located in zeropage
~~~~ 
> Note: The TUNEAREA location can be changed to suit your requirements.
2. Include the following (topscreenroutine) to service the player each frame:
~~~~ 
topscreenroutine
  rem call the pokey servicing routine
  asm
    jsr SERVICEPOKEYSFX
end
return
~~~~ 

## Examples

* Example1 - basic implementation showing how to integrate the 7800 pokey engine into 7800basic including adding pokeyconfig and pokeymusic assembly files via the inline feature, calling and playing multiple different tunes and sound effects.
