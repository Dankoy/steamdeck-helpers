# steamdeck-backup-services

Contains backup services for steamdeck or other linux os

## services

1) retroarch-backup.service - backup retroarch save files
3) emudeck-copy-roms.service - copy roms from custom directories to flat directory for emudeck rom folders. Using copir-py script.
4) yuzu-backup.service - backup yuzu save files
6) ryujinx-backup.service - backup ryujinx files (read below about tweaks)

## timers

1) retroarch-backup.timer - timer for backup service
2) yuzu-backup.timer - timer for backup service
3) ryujinx-backup.timer - timer for backup service.

## environment files

1) retroarch-backup.env
2) emudeck-copy-roms.env
3) yuzu-backup.env
4) ryujinx-backup.env
5) eden-backup.env


# Description

For beckup is used rsync

The following command copy files which exist in include statements:

`rsync -avzhm --include='saves/*' --include='screenshots/*' --include='states/*' --include='system/*' --include='retroarch.cfg' --include='*/'  --exclude='*'  /home/deck/.var/app/org.libretro.RetroArch/config/retroarch/ /home/deck/Documents/retroarch_backup/`

Also, it is necessary to create timer for backup service
`~/.config/systemd/user/some-service-name.*`

## Install script

Install script was made to simplify installation process for all files. 

1) It copies services and timers into `~/.config/system/user/`
2) Copies environment files into `~/.steamdeck-helpers/env/`
3) Creates backups for old files if necessary
4) Reloads systemd daemon.

# Usage

1) git pull repo
2) Go to scripts folder in repo `cd ~/git/steamdeck-helpers/backup-services/scripts`
3) Run install script `./install.sh`
4) Change source and destination directories in env files for your own directories. Default are steamdeck folders.

## Using copir

Install script also copies copir service so it can be started with systemd. 
To make it work properly, change env file to comply with your own emudeck installation location for roms.
For more info read [copir docs](../copir-py/README.md)

# Examples

1) Retroarch backup    
   `ExecStart=sh -c 'rsync -avzhm --include=\'saves/**\' --include=\'screenshots/*\' --include=\'states/*\' --include=\'system/**\' --include=\'retroarch.cfg\' --include=\'*/\'  --exclude=\'*\'  /home/deck/.var/app/org.libretro.RetroArch/config/retroarch/ /home/deck/Documents/retroarch_backup/'`
2) Ryujinx backup
   `ExecStart=sh -c 'rsync -avzhm /run/media/deck/0f782a07-7903-4d80-9796-2356c3659f5e/Emulation/saves/ryujinx/ /home/deck/Documents/backups/ryujinx_backup/'`

# Ryujinx from EmuDeck saves backup

Emudeck installs ryujinx in it's own folder. Also it creates folder with name 'Emulation' which contains saves and other
staff from many different emulators. For linux emudeck creates symlink folders in path 'Emulation/saves/ryujinx/' to
save and saveMeta folder in actual ryujinx installation folder. For windows emudeck do this the other way around and
creates normal folders in 'Emulation/saves/ryujinx/' and symlink them in ryujinx installation, which is the correct way
to do staff.

So if you try to backup symlinks then it's pointless. You have to create normal folders in 'Emulation/saves/ryujinx/'
and symlink them in ryujinx installation folder.

!!! After you do that NEVER update emulator configurations in EmuDeck GUI, it will break your saves. !!!

With such tweaks it's possible to have actual multiplatform without conflicts.

# Useful commands

1) Start service - `systemctl --user start some-service-name`
2) Enable service - `systemctl --user enable --now some-service-name.timer`
3) After each modification in service or timer - `systemctl --user daemon-reload`
4) Read logs - `journalctl --user -u some-service-name`
