# steamdeck-helpers

Contains projects for different purposes to automate some tedious tasks

# copir [link](copir)

Copy files from one directory, which contains multiple nested directories to one flat folder.    
Mainly code made to automate copy ROMS for emulation to flat folder
of [EmuDeck](https://www.emudeck.com/) for Steam Deck. 

While Steam Deck doesn't support java installation or at least docker installation without shaman
dances, this project is not used at all, and present here as an example, nothing more. 

So python is the only way to run scripts without additional services installation.

# copir-py [link](copir-py)

The same as copir but written on python and can simply run on steamdeck

# backup-services [link](backup-services)

Contains linux services to run scripts and timer necessary for:

1) Backup retroarch saves
2) Backup yuzu saves
3) Copy roms from custom folders to flat folder used by [EmuDeck](https://www.emudeck.com/) using
   [copir-py](copir-py) project