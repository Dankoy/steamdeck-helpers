# steamdeck-helpers

Contains projects for different purposes to automate some tedious tasks

## Usage

1) git pull repo
2) Go to scripts folder in repo `cd ~/git/steamdeck-helpers/shell_scripts`
3) Run install script `./install.sh`. This script add env files for systemd services, and add user managed systemd services and timers.
4) Change source and destination directories in `config.env` file for your own directories. Default are steamdeck folders.
5) Run replace script `./replace_env_vars.sh`. This script will change placeholders in env files for systemd services to your desired values.

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
3) Backup eden saves
4) Backup ryujinx saves
5) Copy roms from custom folders to flat folder used by [EmuDeck](https://www.emudeck.com/) using
   [copir-py](copir-py) project

# shell_scripts [link](shell_scripts)

Contains scripts to easily populate necessary files for backup services and also service for copir-py.