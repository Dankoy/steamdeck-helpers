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
# shellcheck source=/dev/null
source "${LIB_DIR}/getops_utils.sh"


# ----------- DEFAULT VALUES ----------
ENV_DEST_FOLDER="$HOME/.steamdeck_helpers/env/"
CONFIG_FILE="config.env"
VERBOSE=false
FORCE=false

# ---------- HELP FUNCTION ----------
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [CONFIG_FILE]

Replace placeholders in .env files using configuration.

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -f, --force             Force operation (skip confirmations)
    -d, --dest-dir DIR      Environment destination directory (default: $ENV_DEST_FOLDER)
    -c, --config FILE       Configuration file (default: config.env)

ARGUMENTS:
    CONFIG_FILE             Path to configuration file (optional, default: config.env)

EXAMPLES:
    $0                      Use config.env with default settings
    $0 my-config.env        Use my-config.env as configuration
    $0 -v -f                Verbose mode, force operation
    $0 -d /custom/path/     Use custom destination directory
    $0 -c my-config.env -v  Use custom config with verbose output
    $0 --help               Show this help

EOF
    exit 0
}

# ---------- PARSE OPTIONS ----------
parse_replace_options() {
    local optstring="hvfd:c:"
    
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
    
    if is_option_set "d"; then
        ENV_DEST_FOLDER=$(get_option_value "d" "$ENV_DEST_FOLDER")
    fi
    
    if is_option_set "c"; then
        CONFIG_FILE=$(get_option_value "c" "$CONFIG_FILE")
    fi
    
    # Get remaining arguments (positional)
    local remaining_args
    remaining_args=$(get_remaining_args)
    
    # If there's a remaining argument, use it as config file (overrides -c)
    if [[ -n "$remaining_args" ]]; then
        # Get first argument (config file path)
        local first_arg
        first_arg=$(echo "$remaining_args" | awk '{print $1}')
        if [[ -n "$first_arg" ]]; then
            CONFIG_FILE="$first_arg"
            log_debug "Using positional argument as config file: $CONFIG_FILE"
        fi
    fi
    
    # Now log the configuration (after parsing is complete)
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Verbose mode enabled"
    fi
    
    if [[ "$FORCE" == "true" ]]; then
        log_info "Force mode enabled"
    fi
    
    log_debug "Config file: $CONFIG_FILE"
    log_debug "Destination directory: $ENV_DEST_FOLDER"
}

# ---------- CONFIRM OPERATION ----------
confirm_operation() {
    if [[ "$FORCE" == "true" ]]; then
        log_info "Force mode enabled. Skipping confirmation."
        return 0
    fi
    
    echo ""
    log_warn "=== REPLACE ENV CONFIGURATION ==="
    echo "Config file:         $CONFIG_FILE"
    echo "Destination dir:     $ENV_DEST_FOLDER"
    echo "Verbose mode:        $VERBOSE"
    echo "Force mode:          $FORCE"
    echo ""
    
    read -p "Proceed with replacement? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled."
        exit 0
    fi
}

# ---------- MAIN ----------
main() {
    # Parse command line options FIRST
    parse_replace_options "$@"
    
    log_info "=== REPLACE ENV START ==="
    
    USER=$(whoami)
    log_debug "Running as user: $USER"
    
    # Show configuration and confirm
    confirm_operation

    local has_errors=false
    
    # Load config
    log_info "Loading configuration from '$CONFIG_FILE'..."
    if ! load_config "$CONFIG_FILE"; then
        log_error "Failed to load configuration file '$CONFIG_FILE'!"
        exit 1
    fi
    log_info "Configuration loaded successfully."
    
    # Check required variables
    local required_vars=(
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
    
    # Also check that the required source variables exist (with their values)
    local required_source_vars=(
        "EDEN_BACKUP_source_folder"
        "EDEN_BACKUP_destination_folder"
        "RETROARCH_BACKUP_source_folder"
        "RETROARCH_BACKUP_destination_folder"
        "RYUJINX_BACKUP_source_folder"
        "RYUJINX_BACKUP_destination_folder"
        "YUZU_BACKUP_source_folder"
        "YUZU_BACKUP_destination_folder"
    )
    
    # Validate all required variables
    local all_required=("${required_vars[@]}" "${required_source_vars[@]}")
    
    if ! validate_required_vars "${all_required[@]}"; then
        log_error "Missing required variables in configuration!"
        exit 1
    fi
    
    log_debug "All required variables validated."

    # Check destination folder
    if ! check_folder_exists "$ENV_DEST_FOLDER"; then
        log_error "Destination directory '$ENV_DEST_FOLDER' not found!"
        log_error "Please ensure the directory exists or run install.sh first."
        exit 1
    fi
    
    log_debug "Destination directory: $ENV_DEST_FOLDER"

    # emudeck copy roms
    log_info "Processing emudeck copy roms..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$EMUDECK_COPY_ROMS_FILE_NAME"; then
        log_debug "Processing replacements in $EMUDECK_COPY_ROMS_FILE_NAME"
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
        log_debug "Processing replacements in $EDEN_BACKUP_FILE_NAME"
        replace_in_file "$ENV_DEST_FOLDER" "$EDEN_BACKUP_FILE_NAME" "$BSF" "$EDEN_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$EDEN_BACKUP_FILE_NAME" "$BDF" "$EDEN_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$EDEN_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # retroarch backup
    log_info "Processing retroarch backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$RETROARCH_BACKUP_FILE_NAME"; then
        log_debug "Processing replacements in $RETROARCH_BACKUP_FILE_NAME"
        replace_in_file "$ENV_DEST_FOLDER" "$RETROARCH_BACKUP_FILE_NAME" "$BSF" "$RETROARCH_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$RETROARCH_BACKUP_FILE_NAME" "$BDF" "$RETROARCH_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$RETROARCH_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # ryujinx backup
    log_info "Processing ryujinx backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$RYUJINX_BACKUP_FILE_NAME"; then
        log_debug "Processing replacements in $RYUJINX_BACKUP_FILE_NAME"
        replace_in_file "$ENV_DEST_FOLDER" "$RYUJINX_BACKUP_FILE_NAME" "$BSF" "$RYUJINX_BACKUP_source_folder" || has_errors=true
        replace_in_file "$ENV_DEST_FOLDER" "$RYUJINX_BACKUP_FILE_NAME" "$BDF" "$RYUJINX_BACKUP_destination_folder" || has_errors=true
    else
        log_error "File '$RYUJINX_BACKUP_FILE_NAME' was not processed!"
        has_errors=true
    fi

    # yuzu backup
    log_info "Processing yuzu backup..."
    if check_file_exist_in_folder "$ENV_DEST_FOLDER" "$YUZU_BACKUP_FILE_NAME"; then
        log_debug "Processing replacements in $YUZU_BACKUP_FILE_NAME"
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