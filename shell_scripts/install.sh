#!/bin/bash
# ============================================
# Install script with getopts support
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
# shellcheck source=/dev/null
source "${LIB_DIR}/getops_utils.sh"


# ----------- DEFAULT VALUES ----------
USER=$(whoami)

ENV_SRC_FOLDER="../backup-services/env/"
SERVICES_SRC_FOLDER="../backup-services/service/"

ENV_DEST_FOLDER="$HOME/.steamdeck_helpers/env/"
SERVICES_DEST_FOLDER="$HOME/.config/systemd/user/"

BACKUP_FOLDER="$HOME/.steamdeck_helpers/backups/"
BACKUP_RETENTION_DAYS=14

VERBOSE=false
FORCE=false
SKIP_SYSTEMD=false
BACKUP_ENABLED=true
DRY_RUN=false

# ---------- HELP FUNCTION ----------
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install script for SteamDeck helpers.

OPTIONS:
    -h         Show this help message
    -v         Enable verbose output
    -f         Force installation (skip confirmations)
    -s         Skip systemd daemon reload
    -n         Skip backup creation
    -y         Print commands without executing them (dry run)
    -e DIR     Environment source directory (default: $ENV_SRC_FOLDER)
    -S DIR     Service source directory (default: $SERVICES_SRC_FOLDER)
    -d DIR     Environment destination directory (default: $ENV_DEST_FOLDER)
    -D DIR     Service destination directory (default: $SERVICES_DEST_FOLDER)
    -b DIR     Backup directory (default: $BACKUP_FOLDER)
    -r DAYS    Backup retention in days (default: 14)

EXAMPLES:
    $0                      Install with default settings
    $0 -v -f                Verbose mode, force installation
    $0 -s -n                Skip systemd reload and backups
    $0 -y                   Show what would be done (dry run)
    $0 -y -v                Dry run with verbose output
    $0 -e ./custom-env/     Use custom environment directory
    $0 -r 30                Keep backups for 30 days
    $0 --help               Show this help

EOF
    exit 0
}

# ---------- PARSE OPTIONS ----------
parse_install_options() {
    local optstring="hvfsnye:S:d:D:b:r:"
    
    # Call the library function to parse options
    parse_options "$optstring" "show_usage" "$@"
    
    # Now check each option and apply it
    if is_option_set "v"; then
        VERBOSE=true
        export DEBUG=true
    fi
    
    if is_option_set "f"; then
        FORCE=true
    fi
    
    if is_option_set "s"; then
        SKIP_SYSTEMD=true
    fi
    
    if is_option_set "n"; then
        BACKUP_ENABLED=false
    fi
    
    if is_option_set "y"; then
        DRY_RUN=true
    fi
    
    if is_option_set "e"; then
        ENV_SRC_FOLDER=$(get_option_value "e" "$ENV_SRC_FOLDER")
    fi
    
    if is_option_set "S"; then
        SERVICES_SRC_FOLDER=$(get_option_value "S" "$SERVICES_SRC_FOLDER")
    fi
    
    if is_option_set "d"; then
        ENV_DEST_FOLDER=$(get_option_value "d" "$ENV_DEST_FOLDER")
    fi
    
    if is_option_set "D"; then
        SERVICES_DEST_FOLDER=$(get_option_value "D" "$SERVICES_DEST_FOLDER")
    fi
    
    if is_option_set "b"; then
        BACKUP_FOLDER=$(get_option_value "b" "$BACKUP_FOLDER")
    fi
    
    if is_option_set "r"; then
        local retention_value
        retention_value=$(get_option_value "r" "")
        if [[ "$retention_value" =~ ^[0-9]+$ ]]; then
            BACKUP_RETENTION_DAYS="$retention_value"
        else
            log_error "Retention days must be a number!"
            exit 1
        fi
    fi
    
    # Get remaining arguments
    local remaining_args
    remaining_args=$(get_remaining_args)
    if [[ -n "$remaining_args" ]]; then
        log_warn "Unrecognized arguments: $remaining_args"
    fi
    
    # Now log the configuration (after parsing is complete)
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Verbose mode enabled"
    fi
    
    if [[ "$FORCE" == "true" ]]; then
        log_info "Force mode enabled"
    fi
    
    if [[ "$SKIP_SYSTEMD" == "true" ]]; then
        log_info "Skipping systemd reload"
    fi
    
    if [[ "$BACKUP_ENABLED" == "false" ]]; then
        log_info "Backups disabled"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE: Commands will be printed but NOT executed"
    fi
}

# ---------- CONFIRM OPERATION ----------
confirm_operation() {
    if [[ "$FORCE" == "true" ]]; then
        log_info "Force mode enabled. Skipping confirmation."
        return 0
    fi
    
    echo ""
    log_warn "=== INSTALLATION CONFIGURATION ==="
    echo "User:                  $USER"
    echo "Environment source:    $ENV_SRC_FOLDER"
    echo "Environment dest:      $ENV_DEST_FOLDER"
    echo "Services source:       $SERVICES_SRC_FOLDER"
    echo "Services dest:         $SERVICES_DEST_FOLDER"
    echo "Backup directory:      $BACKUP_FOLDER"
    echo "Backup retention:      $BACKUP_RETENTION_DAYS days"
    echo "Backups enabled:       $BACKUP_ENABLED"
    echo "Systemd reload:        $(if [[ "$SKIP_SYSTEMD" == "true" ]]; then echo "SKIPPED"; else echo "ENABLED"; fi)"
    echo "Verbose mode:          $VERBOSE"
    echo "Force mode:            $FORCE"
    echo "Dry run mode:          $DRY_RUN"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE: No changes will be made to the system."
        read -p "Show dry run commands? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Dry run cancelled."
            exit 0
        fi
        return 0
    fi
    
    read -p "Proceed with installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi
}

# ---------- EXECUTE OR PRINT ----------
execute_or_print() {
    local cmd="$1"
    local description="${2:-}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ -n "$description" ]]; then
            echo "  [DRY RUN] $description"
        fi
        echo "  > $cmd"
        return 0
    else
        eval "$cmd"
        return $?
    fi
}

# ---------- SYSTEMD RELOAD ------------
systemd_reload() {
    if [[ "$SKIP_SYSTEMD" == "true" ]]; then
        log_info "Skipping systemd daemon reload (--skip-systemd)"
        return 0
    fi
    
    local cmd="systemctl --user daemon-reload"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would reload systemd user daemon"
        echo "  > $cmd"
        return 0
    fi
    
    if systemctl --user daemon-reload; then
        log_info "systemd daemon reloaded"
        return 0
    else
        log_error "systemd daemon reload failed"
        return 1
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
    
    log_debug "Found ${#result_array[@]} file(s) in source directory: ${result_array[*]}"
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
        log_debug "Source directory '$src' exists."
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

        local cmd="mkdir -p \"$dest\""
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would create directory: $dest"
            echo "  > $cmd"
            return 0
        fi
        
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
    log_debug "Managing ${#files_to_manage[@]} file(s): ${files_to_manage[*]}"
    
    # Check if there are files to upsert from source
    if [[ ${#files_to_manage[@]} -eq 0 ]]; then
        log_error "No files specified for upsert!"
        return 1
    fi
    
    # Check if files from source already exist in destination folder
    if check_files_exist_in_folder "$dest" "${files_to_manage[@]}"; then
        log_warn "Destination directory '$dest' has files that need backup..."
        
        if [[ "$BACKUP_ENABLED" == "true" ]]; then
            # Create backup for files in array
            if ! create_backup_to_dir "$dest" "$BACKUP_FOLDER" "$backup_name" "${files_to_manage[@]}"; then
                log_error "Backup failed! Aborting update to prevent data loss."
                return 1
            fi
            
            # Clean backup
            cleanup_old_backups "$BACKUP_FOLDER" "$backup_name" "$BACKUP_RETENTION_DAYS"
        else
            log_warn "Backups are disabled. Proceeding without backup!"
        fi
        
        # Copy files
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would copy files from '$src' to '$dest'"
            for file in "${files_to_manage[@]}"; do
                echo "  > cp -v \"${src}${file}\" \"${dest}\""
            done
            return 0
        fi
        
        copy_files "$src" "$dest" files_to_manage
    else
        log_info "Directory '$dest' has no files to backup. Initial install."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would copy files from '$src' to '$dest'"
            for file in "${files_to_manage[@]}"; do
                echo "  > cp -v \"${src}${file}\" \"${dest}\""
            done
            return 0
        fi
        
        copy_files "$src" "$dest" files_to_manage
    fi
}

# ---------- MAIN FUNCTION ----------
main() {
    # Parse command line options FIRST
    parse_install_options "$@"
    
    log_info "=== INSTALL START ==="
    log_info "Running as user: $USER"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE ACTIVATED - No changes will be made"
        echo ""
    fi
    
    # Show configuration and confirm
    confirm_operation
    
    # 1. Check source directories
    log_info "=========== Checking source directories..."
    print_string
    
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

    print_string
    log_info "=========== Checking source directories done..."
    print_string

    # 2. Prepare and process environment files
    log_info "=========== Step 1: Processing environment files..."
    print_string
    
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

    print_string
    log_info "=========== Step 1: Done..."
    print_string

    # 3. Prepare and process service files
    log_info "=========== Step 2: Processing service files..."
    print_string
    
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

    print_string
    log_info "=========== Step 2: Done..."
    print_string

    # 4. Reload systemd
    print_string
    log_info "=========== Reload systemd user daemon..."
    print_string

    if systemd_reload; then
        log_info "Systemd reloaded successfully."
    else
        log_error "Systemd reload failed!"
        exit 1
    fi
    
    print_string
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN COMPLETED - No changes were made to the system"
        log_info "Remove -y flag to perform actual installation"
    else
        log_info "=== INSTALL FINISHED CORRECTLY ==="
    fi
}

# ---------- RUN ----------
main "$@"