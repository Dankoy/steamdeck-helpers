#!/bin/bash
# ============================================
# Library of common functions
# ============================================

# ============================================
# COLORS
# ============================================
# ANSI color codes for terminal output formatting
# ============================================export RED='\033[0;31m'
# @var {string} RED - Red color code
export RED='\033[0;31m'
# @var {string} GREEN - Green color code
export GREEN='\033[0;32m'
# @var {string} YELLOW - Yellow color code
export YELLOW='\033[1;33m'
# @var {string} NC - No color (reset)
export NC='\033[0m'

# ============================================
# LOGGING FUNCTIONS
# ============================================

# ============================================
# Function: log_info
# ============================================
# Logs an informational message with green color prefix.
#
# @param {string} message - The message to log
#
# @example
#   log_info "Backup completed successfully"
#   # Output: [INFO] Backup completed successfully
# ============================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

# ============================================
# Function: log_warn
# ============================================
# Logs a warning message with yellow color prefix.
#
# @param {string} message - The warning message to log
#
# @example
#   log_warn "Disk space is running low"
#   # Output: [WARN] Disk space is running low
# ============================================
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# ============================================
# Function: log_error
# ============================================
# Logs an error message with red color prefix to stderr.
#
# @param {string} message - The error message to log
#
# @example
#   log_error "Failed to create backup"
#   # Output (stderr): [ERROR] Failed to create backup
# ============================================
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ============================================
# Function: log_debug
# ============================================
# Logs a debug message with yellow color prefix.
# Only outputs when DEBUG environment variable is set to "true".
#
# @param {string} message - The debug message to log
#
# @example
#   DEBUG=true log_debug "Processing file: $file"
#   # Output: [DEBUG] Processing file: /path/to/file
#
# @note Set DEBUG=true to enable debug output
# ============================================
log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${YELLOW}[DEBUG]${NC} $*"
    fi
}

# ============================================
# CHECK FUNCTIONS
# ============================================

# ============================================
# Function: check_folder_exists
# ============================================
# Checks if a directory exists.
#
# @param {string} dir - Path to the directory to check
#
# @returns {number} 0 - directory exists, 1 - directory does not exist or empty path
#
# @example
#   if check_folder_exists "/home/user/.config"; then
#       echo "Directory exists"
#   fi
# ============================================
check_folder_exists() {
    local dir="$1"
    
    # Check empty
    if is_empty "$dir"; then
        log_error "check_folder_exists: directory path is empty '$dir'!"
        return 1
    fi
    
    if [[ ! -d "$dir" ]]; then
        log_warn "Directory '$dir' doesn't exist!"
        return 1
    fi
    
    return 0
}

# ============================================
# Function: check_file_exists
# ============================================
# Checks if a regular file exists.
#
# @param {string} file - Path to the file to check
#
# @returns {number} 0 - file exists, 1 - file does not exist or empty path
#
# @example
#   if check_file_exists "/home/user/.bashrc"; then
#       echo "File exists"
#   fi
# ============================================
check_file_exists() {
    local file="$1"
    
    # Check empty
    if is_empty "$file"; then
        log_error "check_file_exists: ile path is empty '$file'!"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_warn "File '$file' doesn't exist!"
        return 1
    fi
    
    return 0
}

# ============================================
# Function: check_file_exist_in_folder
# ============================================
# Checks if a specific file exists inside a directory.
#
# @param {string} dest      - Directory path
# @param {string} file_name - Name of the file to check
#
# @returns {number} 0 - file exists, 1 - file does not exist or directory missing
#
# @example
#   if check_file_exist_in_folder "/home/user/.config" "settings.conf"; then
#       echo "Settings file found"
#   fi
# ============================================
check_file_exist_in_folder() {
    local dest="$1"
    local file_name="$2"
    local full_path="${dest}${file_name}"
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist. Considered as empty."
        return 1
    fi
    
    if [[ ! -f "${full_path}" ]]; then
        log_error "File '${full_path}' not found!"
        return 1
    else 
        log_info "File '${full_path}' found!"
        return 0
    fi
}

# ============================================
# Function: check_files_exist_in_folder
# ============================================
# Checks if any of the specified files exist in the destination directory.
#
# @param {string} dest      - Directory to check
# @param {string[]} files   - Array of filenames to check for
#
# @returns {number} 0 - at least one file exists, 1 - no files exist or directory missing
#
# @example
#   local files=(".env" ".env.local" "config.yml")
#   if check_files_exist_in_folder "/home/user/project" "${files[@]}"; then
#       echo "Some config files already exist"
#   fi
#
# @note Useful for determining if backup is needed before updating
# ============================================
check_files_exist_in_folder() {
    local dest="$1"
    shift
    local files_to_check=("$@")
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist. Considered as empty."
        return 1 # No files
    fi
    
    if [[ ${#files_to_check[@]} -eq 0 ]]; then
        log_info "No files to check in '$dest'."
        return 1
    fi

    # Check existane of files from array in destination folder
    local found_files=()
    for file in "${files_to_check[@]}"; do
        if [[ -f "${dest}${file}" ]]; then
            found_files+=("$file")
        fi
    done
    
    if [[ ${#found_files[@]} -gt 0 ]]; then
        log_info "Directory '$dest' has ${#found_files[@]} file(s) to backup."
        return 0 # Files exist
    else
        log_info "Directory '$dest' has none of the specified files."
        return 1 # Files don't exist
    fi
}

# ============================================
# Function: check_folder_empty
# ============================================
# Checks if a directory is empty (contains no files or directories).
#
# @param {string} dir - Directory path to check
#
# @returns {number} 0 - directory is empty or doesn't exist, 1 - directory is not empty
#
# @example
#   if check_folder_empty "/home/user/downloads"; then
#       echo "Downloads folder is empty"
#   fi
#
# @note A non-existent directory is considered empty
# ============================================
check_folder_empty() {
    local dir="$1"
    
    if ! check_folder_exists "$dir"; then
        log_info "Directory '$dir' doesn't exist. Considered as empty."
        return 0
    fi
    
    if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
        log_info "Directory '$dir' is empty."
        return 0
    else 
        log_info "Directory '$dir' is not empty."
        return 1
    fi
}

# ============================================
# CONFIG LOADING FUNCTIONS
# ============================================

# ============================================
# Function: load_config
# ============================================
# Loads environment variables from a configuration file.
#
# @param {string} config_file - Path to the configuration file (default: config.env)
#
# @returns {number} 0 - configuration loaded successfully, 1 - error
#
# @example
#   load_config "my_config.env"
#   # Loads variables from my_config.env
#
# @example
#   load_config
#   # Loads variables from config.env (default)
# ============================================
load_config() {
    local config_file="${1:-config.env}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file '$config_file' not found!"
        log_error "Please create it or specify path: $0 <config_file>"
        return 1
    fi
    
    log_info "Loading configuration from '$config_file'..."
    
    # shellcheck source=/dev/null
    if source "$config_file"; then
        log_info "Configuration loaded successfully!"
        return 0
    else
        log_error "Failed to load configuration!"
        return 1
    fi
}

# ============================================
# Function: validate_required_vars
# ============================================
# Validates that all specified environment variables are set and not empty.
#
# @param {string[]} vars - List of variable names to validate
#
# @returns {number} 0 - all variables are set, 1 - one or more variables are missing
#
# @example
#   validate_required_vars "ENV_DEST_FOLDER" "BACKUP_NAME" "RETENTION_DAYS"
#   # Checks if these three variables are defined
# ============================================
validate_required_vars() {
    local missing_vars=()
    local var
    
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        return 1
    fi
    
    return 0
}

# ============================================
# ARRAY HELPERS
# ============================================

# ============================================
# Function: array_contains
# ============================================
# Checks if an array contains a specific element.
#
# @param {string} element - The element to search for
# @param {string[]} array - The array to search in
#
# @returns {number} 0 - element found, 1 - element not found
#
# @example
#   local fruits=("apple" "banana" "orange")
#   if array_contains "banana" "${fruits[@]}"; then
#       echo "Found banana!"
#   fi
# ============================================
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

# ============================================
# Function: array_join
# ============================================
# Joins array elements into a single string with a separator.
#
# @param {string} separator - The separator string
# @param {string[]} array   - The array to join
#
# @output {string} The joined string
#
# @example
#   local fruits=("apple" "banana" "orange")
#   result=$(array_join ", " "${fruits[@]}")
#   echo "$result"  # Output: apple, banana, orange
# ============================================
array_join() {
    local separator="$1"
    shift
    local array=("$@")
    local result=""
    
    for item in "${array[@]}"; do
        if [[ -z "$result" ]]; then
            result="$item"
        else
            result="${result}${separator}${item}"
        fi
    done
    
    echo "$result"
}

# ============================================
# STRING HELPERS
# ============================================

# ============================================
# Function: escape_sed_pattern
# ============================================
# Escapes special characters in a string for safe use in sed patterns.
# Escapes: /, &, and backslash
#
# @param {string} pattern - The string to escape
#
# @output {string} The escaped string safe for sed
#
# @example
#   escaped=$(escape_sed_pattern "/home/user/path")
#   # Returns: \/home\/user\/path
#
# @note Required when using variables with paths in sed commands
# ============================================
escape_sed_pattern() {
    echo "$1" | sed 's/[\/&]/\\&/g'
}

# ============================================
# Function: is_empty
# ============================================
# Checks if a string is empty or unset.
#
# @param {string} str - The string to check
#
# @returns {number} 0 - string is empty, 1 - string is not empty
#
# @example
#   if is_empty "$variable"; then
#       echo "Variable is empty"
#   fi
# ============================================
is_empty() {
    [[ -z "$1" ]]
}

# ============================================
# Function: is_not_empty
# ============================================
# Checks if a string is not empty.
#
# @param {string} str - The string to check
#
# @returns {number} 0 - string is not empty, 1 - string is empty
#
# @example
#   if is_not_empty "$variable"; then
#       echo "Variable has a value"
#   fi
# ============================================
is_not_empty() {
    [[ -n "$1" ]]
}

# ============================================
# Function: print_string
# ============================================
# Prints a string to stdout. Handles missing arguments gracefully.
#
# @param {string} text - The text to print (optional, defaults to empty)
#
# @returns {number} 0 - success, 1 - error
#
# @example
#   print_string "Hello World"  # Output: Hello World
#   print_string                # Output: (empty line)
# ============================================
print_string() {
    local text="${1:-}" # Default to empty string if no argument
    echo "$text"
}