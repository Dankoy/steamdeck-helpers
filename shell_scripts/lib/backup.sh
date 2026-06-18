#!/bin/bash
# ============================================
# Library of backup functions
# ============================================

# Загружаем зависимости
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# ---------- BACKUP FUNCTIONS ----------
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
    local retention_count="${3:-5}"
    
    log_info "Cleaning up old backups in '$dest' (keeping last $retention_count)..."
    
    if ! check_folder_exists "$dest"; then
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
    if [[ $total_count -gt $retention_count ]]; then
        local files_to_delete=$((total_count - retention_count))
        log_warn "Keeping last $retention_count backups. Removing $files_to_delete old backup(s)..."
        
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
        log_info "No cleanup needed. Current count ($total_count) is within limit ($retention_count)."
    fi
    
    return 0
}

restore_from_backup() {
    local backup_file="$1"
    local dest="$2"
    
    if ! check_file_exists "$backup_file"; then
        log_error "Backup file '$backup_file' not found!"
        return 1
    fi
    
    if ! check_folder_exists "$dest"; then
        log_error "Destination directory '$dest' not found!"
        return 1
    fi
    
    log_info "Restoring from backup '$backup_file' to '$dest'..."
    
    if tar -xzf "$backup_file" -C "$dest" 2>/dev/null; then
        log_info "Restore completed successfully!"
        return 0
    else
        log_error "Failed to restore from backup!"
        return 1
    fi
}

list_backups() {
    local dest="$1"
    local backup_pattern="$2"
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist."
        return 1
    fi
    
    echo "Backups in '$dest' (pattern: $backup_pattern):"
    find "$dest" -maxdepth 1 -name "${backup_pattern}_backup_*.tar.gz" -type f | sort -r
}