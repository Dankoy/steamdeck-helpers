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

ENV_SRC_FOLDER="../env/"
SERVICES_SRC_FOLDER="../service/"

ENV_DEST_FOLDER="$HOME/.steamdeck_helpers/env/"
SERVICES_DEST_FOLDER="$HOME/.config/systemd/user/"

BACKUP_RETENTION_COUNT=5
TIMESTAMP=$(date +%Y%m%d_%H%M%S)


ENV_FILES=(
        "eden-backup.env"
        "retroarch-backup.env"
        "ryujinx-backup.env"
        "yuzu-backup.env"
    )


SERVICE_FILES=(
        "emudeck-copy-roms.service"
        "retroarch-backups.service"
        "retroarch-backups.timer"
        "yuzu-backups.service"
        "yuzu-backups.timer"
        "ryujinx-backups.service"
        "ryujinx-backups.timer"
    )

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


# ---------- BACKUP FUNCTIONS ------------
create_backup() {
    local dest="$1"
    local backup_name="$2"
    
    local backup_file="${dest}${backup_name}_backup_${TIMESTAMP}.tar.gz"
    
    log_info "Creating backup to '$backup_file'..."
    
    # Создаём бэкап, исключая уже существующие .tar.gz файлы
    if tar -czf "$backup_file" --exclude='*.tar.gz' -C "$dest" . 2>/dev/null; then
        log_info "✅ Backup created successfully: $(basename "$backup_file")"
        return 0
    else
        log_error "❌ Failed to create backup!"
        return 1
    fi
}

cleanup_old_backups() {
    local dest="$1"
    local backup_pattern="$2"
    
    log_info "Cleaning up old backups in '$dest' (keeping last $BACKUP_RETENTION_COUNT)..."
    
    if [[ ! -d "$dest" ]]; then
        log_info "Directory '$dest' doesn't exist. Nothing to clean."
        return 0
    fi
    
    # Находим все бэкапы для данного типа в целевой директории
    local backup_files
    backup_files=$(find "$dest" -maxdepth 1 -name "${backup_pattern}_backup_*.tar.gz" -type f | sort)
    
    if [[ -z "$backup_files" ]]; then
        log_info "No backups found for pattern '$backup_pattern' in '$dest'."
        return 0
    fi
    
    # Подсчитываем количество файлов
    local total_count
    total_count=$(echo "$backup_files" | wc -l)
    
    log_info "Found $total_count backup(s) for '$backup_pattern'."
    
    # Если количество файлов превышает лимит, удаляем самые старые
    if [[ $total_count -gt $BACKUP_RETENTION_COUNT ]]; then
        local files_to_delete=$((total_count - BACKUP_RETENTION_COUNT))
        log_warn "Keeping last $BACKUP_RETENTION_COUNT backups. Removing $files_to_delete old backup(s)..."
        
        # Удаляем первые N файлов (самые старые)
        echo "$backup_files" | head -n "$files_to_delete" | while read -r file; do
            if rm -f "$file"; then
                log_info "Removed old backup: $(basename "$file")"
            else
                log_warn "Failed to remove: $(basename "$file")"
            fi
        done
        
        log_info "✅ Cleanup completed for '$backup_pattern' in '$dest'."
    else
        log_info "No cleanup needed. Current count ($total_count) is within limit ($BACKUP_RETENTION_COUNT)."
    fi
    
    return 0
}


# ---------- COPY FILES ------------
copy_files() {
    local src="$1"
    local dest="$2"


    # Check source folder

    if ! check_folder_exists "$src"; then
        log_error "Source directory '$src' does not exist!"
        return 1
    fi

    if check_folder_empty "$src"; then
        log_info "Source directory '$src' is empty. Nothing to copy."
        return 0
    fi

    # Check destination folder

    if ! check_folder_exists "$dest"; then
        log_error "Destination directory '$dest' does not exist!"
        return 1
    fi

    if cp -v "$src"* "$dest" 2>/dev/null; then
        log_info "Copy successfull into '$dest'"
        return 0
    else
        log_error "Copy failed into '$dest'"
        return 1
    fi

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

# -------- CHECK FILES IN FOLDER ---------
check_folder_empty() {
    local dir="$1"

    if ! check_folder_exists "$dir"; then
        log_info "Directory '$dir' does not exist!"
        return 0 # Empty
    fi

    if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
        log_info "Directory '$dir' is empty."
        return 0 # Empty
    else 
        log_info "Directory '$dir' is not empty."
        return 1 # Not empty
    fi

}

# -------- CHECK IF DIRECTORY HAS FILES (excluding backups) ---------
check_folder_empty_for_backups() {
    local dir="$1"
    
    if ! check_folder_exists "$dir"; then
        log_info "Directory '$dir' doesn't exist. Considered as empty."
        return 1 # Нет файлов
    fi
    
    # Проверяем, есть ли файлы, исключая .tar.gz бэкапы
    local files_list
    files_list=$(find "$dir" -maxdepth 1 -type f ! -name "*.tar.gz" 2>/dev/null)
    
    if [[ -n "$files_list" ]]; then
        log_info "Directory '$dir' has files (excluding backups)."
        return 0 # Есть файлы
    else
        log_info "Directory '$dir' has no files (excluding backups)."
        return 1 # Нет файлов
    fi
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
    local backup_files="$4"

    log_info "Upsert operation for '$src' -> '$dest'"

    if check_folder_empty_for_backups "$dest"; then
        
        log_warn "Destination directory '$dest' has files. Creating backup before update..."
        
        cleanup_old_backups "$dest" "$backup_name" "$backup_files"

        if ! create_backup "$dest" "$backup_name" "$backup_files"; then
            log_error "Backup failed! Aborting copy to prevent data loss."
            return 1
        fi

        copy_files "$src" "$dest"
    else
        log_info "Directory '$dest' is empty. Initial install."
        copy_files "$src" "$dest"
    fi

}

# ---------- MAIN FUNCTION ----------
main() {
    log_info "=== INSTALL START ==="
    
    # 1. Check source directories
    log_info "Checking source directories..."
    
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
    log_info "Step 1: Processing environment files..."
    
    if prepare_directory "$ENV_SRC_FOLDER" "$ENV_DEST_FOLDER" "environment files"; then
        log_info "Environment directory prepared successfully."
        upsert "$ENV_SRC_FOLDER" "$ENV_DEST_FOLDER" "env" "${ENV_FILES[@]}"
    else
        log_error "Failed to prepare environment directory!"
        exit 1
    fi

    # 3. Prepare and process service files
    log_info "Step 2: Processing service files..."
    
    if prepare_directory "$SERVICES_SRC_FOLDER" "$SERVICES_DEST_FOLDER" "service files"; then
        log_info "Service directory prepared successfully."
        upsert "$SERVICES_SRC_FOLDER" "$SERVICES_DEST_FOLDER" "services" "${SERVICE_FILES[@]}"
    else
        log_error "Failed to prepare service directory!"
        exit 1
    fi

    # 4. Reload systemd
    log_info "Reload systemd user daemon..."

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
