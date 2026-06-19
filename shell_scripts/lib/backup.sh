#!/bin/bash
# ============================================
# Library of backup functions
# ============================================

# Load dependencies
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# ============================================
# Function: create_backup
# ============================================
# Creates a tar.gz backup archive of specified files from a directory.
#
# @param {string} dest          - Target directory containing files to backup
# @param {string} backup_name   - Prefix for the backup filename (used in archive name)
# @param {string[]} files       - Array of filenames to backup (passed after backup_name)
#
# @returns {number} 0 - success, 1 - error
#
# @example
#   create_backup "/home/user/.config" "app" ".bashrc" ".profile"
#   # Creates: /home/user/.config/app_backup_2024-01-15_12-30-45.tar.gz
#
# @example
#   local files=(".env" ".env.local")
#   create_backup "/home/user/project" "env" "${files[@]}"
#
# @note Files with .tar.gz extension are automatically excluded from backup
# @note Only existing files from the provided list are included in the backup
# ============================================
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

# ============================================
# Function: cleanup_old_backups
# ============================================
# Removes backups older than the specified number of days.
#
# @param {string} dest           - Directory containing backups
# @param {string} backup_pattern - Prefix of backup filename (without _backup_*)
# @param {number} retention_days - Number of days to keep backups (default: 14)
#
# @returns {number} 0 - success, 1 - error
#
# @example
#   cleanup_old_backups "/home/user/.config" "app" 30
#   # Removes backups older than 30 days
#
# @example
#   cleanup_old_backups "/home/user/.config" "app"
#   # Removes backups older than 14 days (default)
#
# @note Uses find with -mtime to determine file age
# @note Uses find -delete for optimal performance
# ============================================
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

# ============================================
# Function: restore_from_backup
# ============================================
# Restores files from the specified backup archive to the target directory.
#
# @param {string} backup_file - Full path to the backup file (.tar.gz)
# @param {string} dest        - Directory to restore files to
#
# @returns {number} 0 - success, 1 - error
#
# @example
#   restore_from_backup "/home/user/.config/app_backup_2024-01-15_12-30-45.tar.gz" "/home/user/.config"
#   # Restores files from backup to /home/user/.config
#
# @warning Restoration overwrites existing files in the destination directory
# @warning It's recommended to create a backup of current state before restoring
# @note Archive extracts preserving directory structure
# ============================================
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

# ============================================
# Function: list_backups
# ============================================
# Lists all backups in the specified directory.
#
# @param {string} dest           - Directory to search for backups
# @param {string} backup_pattern - Prefix of backup filename (optional)
#
# @returns {number} 0 - success, 1 - error
#
# @example
#   list_backups "/home/user/.config" "app"
#   # Lists all app backups in /home/user/.config
#
# @example
#   list_backups "/home/user/.config" ""
#   # Lists all backups in /home/user/.config
#
# @output List of backups in format: full file path
# @note Sorted from newest to oldest (reverse chronological)
# ============================================
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