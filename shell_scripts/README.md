## Install script

Install script was made to simplify installation process for all files. 

1) It copies services and timers into `~/.config/system/user/`
2) Copies environment files into `~/.steamdeck-helpers/env/`
3) Creates backups for old files if necessary
4) Reloads systemd daemon.

## replace_env script

This script replaces placeholders in .env files in `~/.steamdeck-helpers/env/` for your values.

Values are read from `config.env` file. So change it there after comment `# ---------- YOUR VARIABLES TO REPLACE TO ----------`