#!/bin/bash
# ============================================
# Install script
# ============================================

set -euo pipefail

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


# ----------- VARIABLES -----------------

set -euo pipefail  # Fail on error

USER=$(whoami)
log_info "Запуск от пользователя: $USER"

ENV_SRC_FOLDER="../backup-services/env/"
SERVICES_SRC_FOLDER="../backup-services/service/"

ENV_DEST_FOLDER="$HOME/.steamdeck_helpers/env/"
SERVICES_DEST_FOLDER="$HOME/.config/systemd/user/"

BACKUP_RETENTION_COUNT=5

# ---------- SYSTEMD RELOAD ------------
systemd_reload() {
    if systemctl --user daemon-reload; then
        log_info "systemd daemon reloaded"
        return 0
    else
        log_error "systemd daemon reload failed"
        exit 1
    fi
}

# -------- GET FILES FROM SOURCE DIRECTORY ---------
get_files_from_source() {
    local src="$1"
    local -n result_array="$2"
    
    if ! check_folder_exists "$src"; then
        log_error "Source directory '$src' not found!"
        return 1
    fi
    
    # Get files from directory (no folders)
    result_array=()
    while IFS= read -r file; do
        if [[ -f "${src}${file}" ]]; then
            result_array+=("$file")
        fi
    done < <(ls -A "$src" 2>/dev/null)
    
    if [[ ${#result_array[@]} -eq 0 ]]; then
        log_warn "No files found in source directory '$src'."
        return 1
    fi
    
    log_info "Found ${#result_array[@]} file(s) in source directory: ${result_array[*]}"
    return 0
}

# ------------ PREPARE DIRECTORY ---------
prepare_directory() {
    local src="$1"
    local dest="$2"
    local description="$3"

    log_info "Working on $description..."

    # Check source directory
    if check_folder_exists "$src"; then 
        log_info "Source directory '$src' exists."
    else
        log_error "Source directory '$src' not found! Cannot continue."
        return 1
    fi

    # Check destination directory
    if check_folder_exists "$dest"; then
        log_warn "Destination directory '$dest' already exists. Skip folder creation."
        return 0
    else
        log_info "Destination directory '$dest' doesn't exist. Create it."

        if mkdir -p "$dest" 2>/dev/null; then
            log_info "Destination directory '$dest' created successfully."
            return 0
        else
            log_error "Failed to create destination directory '$dest'!"
            return 1
        fi
    fi
}

upsert() {
    local src="$1"
    local dest="$2"
    local backup_name="$3"
    shift 3
    local files_to_manage=("$@")
    
    log_info "Upsert operation for '$src' -> '$dest'"
    log_info "Managing ${#files_to_manage[@]} file(s): ${files_to_manage[*]}"
    
    # Check if there are files to upsert from source
    if [[ ${#files_to_manage[@]} -eq 0 ]]; then
        log_error "No files specified for upsert!"
        return 1
    fi
    
    # CHeck if files from source already exist in destination folder
    if check_files_exist_in_dest "$dest" "${files_to_manage[@]}"; then
        log_warn "Destination directory '$dest' has files that need backup..."
        
        # Create backup for files in array
        if ! create_backup "$dest" "$backup_name" "${files_to_manage[@]}"; then
            log_error "Backup failed! Aborting update to prevent data loss."
            return 1
        fi
        
        # Clean backup
        cleanup_old_backups "$dest" "$backup_name" "$BACKUP_RETENTION_COUNT"
        
        # Copy files
        copy_files "$src" "$dest" files_to_manage
    else
        log_info "Directory '$dest' has no files to backup. Initial install."
        copy_files "$src" "$dest" files_to_manage
    fi
}

# ---------- MAIN FUNCTION ----------
main() {
    log_info "=== INSTALL START ==="
    
    # 1. Check source directories
    log_info "=========== Checking source directories...\n"
    
    if check_folder_exists "$ENV_SRC_FOLDER"; then
        log_info "Environment source directory exists."
    else
        log_error "Environment source directory not found! Exiting."
        exit 1
    fi
    
    if check_folder_exists "$SERVICES_SRC_FOLDER"; then
        log_info "Services source directory exists."
    else
        log_error "Services source directory not found! Exiting."
        exit 1
    fi

    # 2. Prepare and process environment files
    log_info "=========== Step 1: Processing environment files...\n"
    
    # Get list of files from source
    local env_files=()
    if get_files_from_source "$ENV_SRC_FOLDER" env_files; then
        if prepare_directory "$ENV_SRC_FOLDER" "$ENV_DEST_FOLDER" "environment files"; then
            log_info "Environment directory prepared successfully."
            upsert "$ENV_SRC_FOLDER" "$ENV_DEST_FOLDER" "env" "${env_files[@]}"
        else
            log_error "Failed to prepare environment directory!"
            exit 1
        fi
    else
        log_warn "No environment files to process."
    fi

    # 3. Prepare and process service files
    log_info "=========== Step 2: Processing service files...\n"
    
    # Get list of files from source
    local service_files=()
    if get_files_from_source "$SERVICES_SRC_FOLDER" service_files; then
        if prepare_directory "$SERVICES_SRC_FOLDER" "$SERVICES_DEST_FOLDER" "service files"; then
            log_info "Service directory prepared successfully."
            upsert "$SERVICES_SRC_FOLDER" "$SERVICES_DEST_FOLDER" "services" "${service_files[@]}"
        else
            log_error "Failed to prepare service directory!"
            exit 1
        fi
    else
        log_warn "No service files to process."
    fi

    # 4. Reload systemd
    log_info "=========== Reload systemd user daemon...\n"

    if systemd_reload; then
        log_info "Systemd reloaded successfully."
    else
        log_error "Systemd reload failed!"
        exit 1
    fi
    
    log_info "=== INSTALL FINISHED CORRECTLY ==="
}

# ---------- RUN ----------
main