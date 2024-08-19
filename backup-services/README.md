# steamdeck-backup-services

Contains backup services for retroarch in steamdeck or other linux os

1) retroarch-backup.service - backup retroarch save files
2) retroarch-backup.timer - timer for backup service
3) emudeck-copy-roms.service - copy roms from custom directories to flat directory for
   emudeck rom folders. Using copir-py script.
4) yuzu-backup.service - backup yuzu save files
5) yuzu-backup.timer - timer for backup service
6) ryujinx-backup.service - backup ryujinx files (read below about tweaks)
7) ryujinx-backup.timer - timer for backup service.

## Description

For retroarch folders beckup is used rsync

The following command copy files which exist in include statements:

`rsync -avzhm --include='saves/*' --include='screenshots/*' --include='states/*' --include='system/*' --include='retroarch.cfg' --include='*/'  --exclude='*'  /home/deck/.var/app/org.libretro.RetroArch/config/retroarch/ /home/deck/Documents/retroarch_backup/`

Also, it is necessary to create timer for backup service
`~/.config/systemd/user/some-service-name.*`

### Examples

1) Retroarch backup    
   `ExecStart=sh -c 'rsync -avzhm --include=\'saves/**\' --include=\'screenshots/*\' --include=\'states/*\' --include=\'system/**\' --include=\'retroarch.cfg\' --include=\'*/\'  --exclude=\'*\'  /home/deck/.var/app/org.libretro.RetroArch/config/retroarch/ /home/deck/Documents/retroarch_backup/'`
2) Ryujinx backup
   `ExecStart=sh -c 'rsync -avzhm /run/media/deck/0f782a07-7903-4d80-9796-2356c3659f5e/Emulation/saves/ryujinx/ /home/deck/Documents/backups/ryujinx_backup/'`

## Ryujinx from EmuDeck saves backup

Emudeck installs ryujinx in it's own folder. Also it creates folder with name 'Emulation' which contains saves and other
staff from many different emulators. For linux emudeck creates symlink folders in path 'Emulation/saves/ryujinx/' to
save and saveMeta folder in actual ryujinx installation folder. For windows emudeck do this the other way around and
creates normal folders in 'Emulation/saves/ryujinx/' and symlink them in ryujinx installation, which is the correct way
to
do staff.

So if you try to backup symlinks then it's pointless. You have to create normal folders in 'Emulation/saves/ryujinx/'
and symlink them in ryujinx installation folder.

!!! After you do that NEVER update emulator configurations in EmuDeck GUI, it will break your saves. !!!

With suck tweaks it's possible to have actual multiplatform without conflicts.

### Useful commands

1) Start service - `systemctl --user start some-service-name`
2) Enable service - `systemctl --user enable --now some-service-name.timer`
3) After each modification in service or timer - `systemctl --user daemon-reload`
4) Read logs - `journalctl --user -u some-service-name`