#!/bin/bash

# ---------- COLORS ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---------- LOGs ----------
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}


# ----------- VARIABLES -----------------

set -euo pipefail  # Fail on error

USER=$(whoami)
log_info "Запуск от пользователя: $USER"

ENV_DEST_FOLDER="$HOME/.steamdeck_helpers/env/"

EMUDECK_COPY_ROMS_FILE_NAME="emudeck-copy-roms.env"
EDEN_BACKUP_FILE_NAME="eden-backup.env"
RETROARCH_BACKUP_FILE_NAME="retroarch-backup.env"
RYUJINX_BACKUP_FILE_NAME="ryujinx-backup.env"
YUZU_BACKUP_FILE_NAME="yuzu-backup.env"

# ------ VARS TO REPLACE --------

EMUDECK_COPY_ROMS_CWD="_CWD_"
EMUDECK_COPY_ROMS_MAIN="_MAIN_"
EMUDECK_COPY_ROMS_ARGS="_ARGS_"

BSF="_SOURCE_FOLDER_"
BDF="_DESTINATION_FOLDER_"

# ------ DEFAULT VARS FOR SED ------------

EMUDECK_COPY_ROMS_cwd="/home/deck/Documents/git/steamdeck-helpers/copir-py"
EMUDECK_COPY_ROMS_main="main.py"
EMUDECK_COPY_ROMS_args="-d asis symlink"

EDEN_BACKUP_source_folder="/home/deck/.var/app/org.libretro.RetroArch/config/retroarch/"
EDEN_BACKUP_destination_folder="/home/deck/Documents/eden_backup/"

RETROARCH_BACKUP_source_folder="/home/deck/.var/app/org.libretro.RetroArch/config/retroarch/"
RETROARCH_BACKUP_destination_folder="/home/deck/Documents/retroarch_backup/"

RYUJINX_BACKUP_source_folder="/run/media/deck/0f782a07-7903-4d80-9796-2356c3659f5e/Emulation/saves/ryujinx/"
RYUJINX_BACKUP_destination_folder="/home/deck/Documents/backups/ryujinx_backup/"

YUZU_BACKUP_source_folder="/home/deck/.var/app/org.libretro.RetroArch/config/retroarch/"
YUZU_BACKUP_destination_folder="/home/deck/Documents/yuzu_backup/"

# ---------- CHECK FOLDERS ----------
check_folder_exists() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        log_warn "Directory '$dir' doesn't exist!"
        return 1
    fi
    
    return 0
}

# -------- CHECK IF DIRECTORY HAS SPECIFIC FILES ---------
check_file_exist_in_folder() {

    local dest="$1"
    local file_name="$2"
    local full_path="${dest}${file_name}"
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist. Considered as empty."
        return 1 # No files
    fi
    
    if [ ! -f "${full_path}" ]; then
        log_error "File '${full_path}' not found!"
        return 1
    else 
        log_info "File '${full_path}' found!"
        return 0
    fi

}

# ----------- REPLACE FUNCTION --------------
replace_in_file() {

    local dest="$1"
    local file_name="$2"
    local from="$3"
    local to="$4"
    local full_path="${dest}${file_name}"

    # Check empty from and to
    if [[ -z "$from" ]] || [[ -z "$to" ]]; then
        log_error "Empty replacement pattern in '$file_name'!"
        return 1
    fi

    local escaped_from
    local escaped_to
    escaped_from=$(echo "$from" | sed 's/[\/&]/\\&/g')
    escaped_to=$(echo "$to" | sed 's/[\/&]/\\&/g')

    if sed -i "s/${escaped_from}/${escaped_to}/g" "$full_path" 2> /dev/null; then
        log_info "Replacement successful in '$file_name': '$from' -> '$to'"
        return 0
    else
        log_error "Failed to replace in '$file_name'"
        return 1
    fi

}



# ----------- MAIN ----------
main() {

    local has_errors=false
    
    # emudeck copy roms
    log_info "Processing emudeck copy roms..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$EMUDECK_COPY_ROMS_FILE_NAME"; then
        replace_in_file "$ENV_DEST_FOLDER" "$EMUDECK_COPY_ROMS_FILE_NAME" "$EMUDECK_COPY_ROMS_CWD" "$EMUDECK_COPY_ROMS_cwd" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$EMUDECK_COPY_ROMS_FILE_NAME" "$EMUDECK_COPY_ROMS_MAIN" "$EMUDECK_COPY_ROMS_main" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$EMUDECK_COPY_ROMS_FILE_NAME" "$EMUDECK_COPY_ROMS_ARGS" "$EMUDECK_COPY_ROMS_args" || has_errors=true
    else
        log_error "File '$EMUDECK_COPY_ROMS_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # eden backup
    log_info "Processing eden backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$EDEN_BACKUP_FILE_NAME"; then
        replace_in_file "$ENV_DEST_FOLDER" "$EDEN_BACKUP_FILE_NAME" "$BSF" "$EDEN_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$EDEN_BACKUP_FILE_NAME" "$BDF" "$EDEN_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$EDEN_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # retroarch backup
    log_info "Processing retroarch backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$RETROARCH_BACKUP_FILE_NAME"; then
        replace_in_file "$ENV_DEST_FOLDER" "$RETROARCH_BACKUP_FILE_NAME" "$BSF" "$RETROARCH_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$RETROARCH_BACKUP_FILE_NAME" "$BDF" "$RETROARCH_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$RETROARCH_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # ryujinx backup
    log_info "Processing ryujinx backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$RYUJINX_BACKUP_FILE_NAME"; then
        replace_in_file "$ENV_DEST_FOLDER" "$RYUJINX_BACKUP_FILE_NAME" "$BSF" "$RYUJINX_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$RYUJINX_BACKUP_FILE_NAME" "$BDF" "$RYUJINX_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$RYUJINX_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # yuzu backup
    log_info "Processing yuzu backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$YUZU_BACKUP_FILE_NAME"; then
        replace_in_file "$ENV_DEST_FOLDER" "$YUZU_BACKUP_FILE_NAME" "$BSF" "$YUZU_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$YUZU_BACKUP_FILE_NAME" "$BDF" "$YUZU_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$YUZU_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    if $has_errors; then
        log_error "Operation completed with errors!"
        exit 1
    else
        log_info "Operation completed successfully!"
        return 0
    fi
}


main