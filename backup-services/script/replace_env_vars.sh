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

# ---------- LOAD CONFIGURATION ----------
load_config() {
    local config_file="${1:-config.env}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file '$config_file' not found!"
        log_error "Please create it or specify path: $0 <config_file>"
        exit 1
    fi
    
    log_info "Loading configuration from '$config_file'..."
    
    # shellcheck source=/dev/null
    if source "$config_file"; then
        log_info "✅ Configuration loaded successfully!"
        return 0
    else
        log_error "❌ Failed to load configuration!"
        exit 1
    fi
}

# ---------- VALIDATE CONFIGURATION ----------
validate_config() {
    local required_vars=(
        "ENV_DEST_FOLDER"
        "EMUDECK_COPY_ROMS_FILE_NAME"
        "EDEN_BACKUP_FILE_NAME"
        "RETROARCH_BACKUP_FILE_NAME"
        "RYUJINX_BACKUP_FILE_NAME"
        "YUZU_BACKUP_FILE_NAME"
        "EMUDECK_COPY_ROMS_CWD"
        "EMUDECK_COPY_ROMS_MAIN"
        "EMUDECK_COPY_ROMS_ARGS"
        "BSF"
        "BDF"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required variables in config:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        exit 1
    fi
    
    log_info "✅ Configuration validation passed!"
}


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
    
    # Load config
    local config_file="${1:-config.env}"
    load_config "$config_file"
    
    # Validate config
    validate_config


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