# 7800 Pokey Engine

Welcome to the 7800 pokey engine for music and sound effects playback on the Atari 7800 Console. This engine was initially developed (based on the disassembly and reverse engineering of Ms. Pac-man by Atari) by Perry Thuente (tep392) and Bob DeCrescenzo (pacmanplus) for the purpose of providing pokey sound playback for the Pac-man Collection. The engine has since been enhanced and is now also being used for other homebrew titles such as Millie & Molly 7800 (Matthew Smith), Popeye (Darryl Guenther) and Danger Zone (Lewis Hill) thanks to the awesome music abilities of Bobby Clark.

The 7800 pokey engine has been kindly open-sourced by the contributors and is freely available to the AtariAge community for use within any project. 

The source is currently maintained by Matthew Smith (mksmith).

## Contributors
The following people have contributed to developing the pokey engine:

* Perry Thuente (tep392)
* Bob DeCrescenzo (pacmanplus)
* Bobby Clark (sythnpopalooza)
* Mike Saarna (reveng)
* Matthew Smith (mksmith) 
* Paul Lay (playsoft)

## Addtional testing
The following people have contributed to testing the pokey engine:

* Robert Tuccitto (trebor) 

## 7800basic release
> The 7800basic version contains initialisation and base framework code provide by Mike Saarna from the 7800basic project. 

## Compiling for the Concerto Beta
When compiling builds for use on the Concerto beta there are a couple of things you need to be aware of:
* Enable the SKIPINITFORCONCERTO flag in **pokeysound.asm**
* 144k ROM is the best supported ROM size and should work without additional change
* 128K+RAM ROM will work but the ROM header will need to be manually changed to remove the pokey @ $450 flag
* 128K ROM does not produce any pokey sound

> These notes will be updated as batari makes enhancements and changes to the Concerto firmware.

### v1.02 (30 Jan 2021)
#### Changelog
* v1.02 - renamed SKIPCHECKFORPOKEY to SKIPINITFORCONCERTO and verified changes work (mksmith, trebor)
* v1.01 - updated SKIPCHECKFORPOKEY process to better handle $450 detection (playsoft)
* v1.00 - open sourced to Github (mksmith)
* v0.11 - added queue scheduling (playsoft) and SKIPCHECKFORPOKEY flag Concerto issue). Added RESETPOLYON and CHANNLRESETON table flags (mksmith)
* v0.10 - removed number of channels (not required) and added a tune-by-tune reset table (mksmith)
* v0.9  - removed SKCTL set and added ability to set number of channels to activate (mksmith)
* v0.8  - added MUTEMASKRESTFLG const so rest value can be customised (mksmith)
* v0.7  - re-implemented MUTEMASK change (reveng)
* v0.6  - fix 16-bit mode, SKCTL, or any mode requiring one channel be silenced and stops popping noises (sythnpopalooza) 
* v0.5  - 7800basic Pause Support (mksmith)
* v0.4  - 7800basic PAL Support (mksmith) [suggestion on how to implement by reveng]
* v0.3  - Reset poly support (sythnpopalooza)
* v0.2  - Added PLAYPOKEYSFX enhancements, STOPPOKEYSFX (mksmith)
* v0.1  - Initial version provided by pacmanplus and sythnpopalooza

### Using the pokey engine in 7800basic
The engine itself is reasonably straight forward to integrate into 7800basic and there is detailed examples for how to properly setup and configure your game to use it.  Saying that it can be tricky at the beginning as you will need to determine the required features to be activated and also configure and locate the music itself potentially across various banks.  The basic process is as follows:

* copy file **pokeysound.asm** into the base root folder of your game. 7800basic will automagically replace the base file in 7800basic during compilation
* inline **pokeyconfig.asm** into your game source (this should be the end of the last shared bank so it can be accessed at all times)
* inline your **musicxxx.asm** file(s) into your game source. There can be one of more of these files spread across multiple banks depending on how you game is structured but in reality as with bank sharing the tune data MUST be available to be currently active bank.

### Other changes to your source
The following changes are required to be made to your 7800basic source:

1. Insert the following vars:
~~~~ 
 dim POKEYADR = $450   ;$450 (modern homebrew) or $4000
 dim TUNEAREA = $2200  ;range $2200-$2246 (46 bytes)            
 dim SOUNDZP = y.z     ;all pointers must be located in zeropage
~~~~ 
> Note: The TUNEAREA location or SOUNDZP vars can be changed to suit your requirements.

2. Include the following to service the player each frame (this should be in the last shared bank so it can be accessed at all times):
~~~~ 
topscreenroutine
  rem call the pokey servicing routine
  asm
    jsr SERVICEPOKEYSFX
end
return
~~~~ 

#### Examples
* example1.78b - basic implementation showing how to integrate the 7800 pokey engine into 7800basic including adding pokeyconfig and pokeymusic assembly files via the inline feature, calling and playing multiple different tunes and sound effects.

#### Additional notes
* tunes can be moved into RAM and played from there if required (example coming soon)
