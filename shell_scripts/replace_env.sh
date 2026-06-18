#!/bin/bash
# ============================================
# Replace placeholders in .env files
# ============================================

set -euo pipefail  # Fail on error

# Library path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Load libs
# shellcheck source=/dev/null
source "${LIB_DIR}/utils.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/file_ops.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/backup.sh"


USER=$(whoami)
log_info "Запуск от пользователя: $USER"


# ----------- MAIN ----------
main() {

    log_info "=== REPLACE ENV START ==="

    local has_errors=false
    
    # Load config
    local config_file="${1:-config.env}"
    if ! load_config "$config_file"; then
        exit 1
    fi
    
    # Проверяем обязательные переменные
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
    
    if ! validate_required_vars "${required_vars[@]}"; then
        exit 1
    fi


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


# ---------- RUN ----------
main "$@"