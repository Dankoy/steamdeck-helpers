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
    shift 2
    local files_to_backup=("$@")
    
    if [[ ${#files_to_backup[@]} -eq 0 ]]; then
        log_info "No files to backup. Skipping backup creation."
        return 0
    fi
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${dest}${backup_name}_backup_${timestamp}.tar.gz"
    
    log_info "Creating backup of ${#files_to_backup[@]} file(s) to '$backup_file'..."
    
    # Проверяем, существуют ли файлы для бэкапа
    local existing_files=()
    for file in "${files_to_backup[@]}"; do
        if [[ -f "${dest}${file}" ]]; then
            existing_files+=("$file")
        fi
    done
    
    if [[ ${#existing_files[@]} -eq 0 ]]; then
        log_info "None of the specified files exist in '$dest'. No backup needed."
        return 0
    fi
    
    # Создаём бэкап только указанных файлов
    if tar -czf "$backup_file" -C "$dest" --exclude='*.tar.gz' "${existing_files[@]}" 2>/dev/null; then
        log_info "Backup created successfully: $(basename "$backup_file") (${#existing_files[@]} files)"
        return 0
    else
        log_error "Failed to create backup!"
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
        
        log_info "Cleanup completed for '$backup_pattern' in '$dest'."
    else
        log_info "No cleanup needed. Current count ($total_count) is within limit ($BACKUP_RETENTION_COUNT)."
    fi
    
    return 0
}


# ---------- COPY FILES ------------
copy_files() {
    local src="$1"
    local dest="$2"
    local -n files_array="$3"  # Ссылка на массив
    
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
    
    # Проверяем, есть ли файлы для копирования
    local files_to_copy=()
    for file in "${files_array[@]}"; do
        if [[ -f "${src}${file}" ]]; then
            files_to_copy+=("$file")
        else
            log_warn "File '${file}' not found in source, skipping."
        fi
    done
    
    if [[ ${#files_to_copy[@]} -eq 0 ]]; then
        log_warn "No files to copy from '$src'."
        return 0
    fi
    
    # Копируем только указанные файлы
    log_info "Copying ${#files_to_copy[@]} file(s) from '$src' to '$dest'..."
    
    local copy_success=true
    for file in "${files_to_copy[@]}"; do
        if cp -v "${src}${file}" "${dest}" 2>/dev/null; then
            log_info "Copied: $file"
        else
            log_error "Failed to copy: $file"
            copy_success=false
        fi
    done
    
    if $copy_success; then
        log_info "Copy completed successfully into '$dest'"
        return 0
    else
        log_error "Copy completed with errors!"
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
        log_info "Directory '$dir' doesn't exist. Considered as empty."
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

# -------- CHECK IF DIRECTORY HAS SPECIFIC FILES ---------
check_files_exist_in_dest() {
    local dest="$1"
    shift
    local files_to_check=("$@")
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist. Considered as empty."
        return 1 # Нет файлов
    fi
    
    # Проверяем, есть ли указанные файлы в целевой директории
    local found_files=()
    for file in "${files_to_check[@]}"; do
        if [[ -f "${dest}${file}" ]]; then
            found_files+=("$file")
        fi
    done
    
    if [[ ${#found_files[@]} -gt 0 ]]; then
        log_info "Directory '$dest' has ${#found_files[@]} file(s) to backup."
        return 0 # Есть файлы
    else
        log_info "Directory '$dest' has none of the specified files."
        return 1 # Нет файлов
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
    
    # Получаем список файлов (только файлы, не директории)
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
    
    # Проверяем, есть ли файлы для управления
    if [[ ${#files_to_manage[@]} -eq 0 ]]; then
        log_error "No files specified for upsert!"
        return 1
    fi
    
    # Проверяем, есть ли указанные файлы в целевой директории
    if check_files_exist_in_dest "$dest" "${files_to_manage[@]}"; then
        log_warn "Destination directory '$dest' has files that need backup..."
        
        # Создаём бэкап только существующих файлов
        if ! create_backup "$dest" "$backup_name" "${files_to_manage[@]}"; then
            log_error "Backup failed! Aborting update to prevent data loss."
            return 1
        fi
        
        # Очищаем старые бэкапы
        cleanup_old_backups "$dest" "$backup_name"
        
        # Копируем файлы
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
    
    # Получаем список файлов из исходной директории
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
    log_info "Step 2: Processing service files..."
    
    # Получаем список файлов из исходной директории
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