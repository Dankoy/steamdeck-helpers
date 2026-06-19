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
    timestamp=$(date +%Y-%m-%d_%H-%M-%S)
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
    local retention_days="${3:-14}"  # Default 14 days (2 weeks)
    
    log_info "Cleaning up old backups in '$dest' (remove older than $retention_days) days..."
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist. Nothing to clean."
        return 0
    fi
    
    # Find all backups
    local backup_files
    backup_files=$(find "$dest" -maxdepth 1 -name "${backup_pattern}_backup_*.tar.gz" -type f)
    
    if [[ -z "$backup_files" ]]; then
        log_info "No backups found for pattern '$backup_pattern' in '$dest'."
        return 0
    fi
    
    # Count total backups
    local total_count
    total_count=$(echo "$backup_files" | wc -l)
    
    log_info "Found $total_count backup(s) for '$backup_pattern'."
    
    # Find and remove backups older than retention_days
    local deleted_count
    deleted_count=$(find "$dest" -maxdepth 1 -name "${backup_pattern}_backup_*.tar.gz" -type f -mtime "+$retention_days" -delete -print 2>/dev/null | wc -l)

    if [[ $deleted_count -eq 0 ]]; then
        log_info "No backups older than $retention_days days found. All $total_count backups are fresh."
    else
        log_info "Removed $deleted_count backup(s) older than $retention_days days."
        
        # Show remaining
        local remaining_count
        remaining_count=$(find "$dest" -maxdepth 1 -name "${backup_pattern}_backup_*.tar.gz" -type f 2>/dev/null | wc -l)
        log_info "Remaining: $remaining_count backup(s)"
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