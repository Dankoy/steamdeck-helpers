#!/bin/bash
# ============================================
# Library of common functions
# ============================================

# ---------- COLORS ----------
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m' # No Color

# ---------- LOGGING ----------
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${YELLOW}[DEBUG]${NC} $*"
    fi
}

# ---------- CHECK FUNCTIONS ----------
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

# ---------- CONFIG LOADING ----------
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

# ---------- ARRAY HELPERS ----------
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

# ---------- STRING HELPERS ----------
escape_sed_pattern() {
    echo "$1" | sed 's/[\/&]/\\&/g'
}

is_empty() {
    [[ -z "$1" ]]
}

is_not_empty() {
    [[ -n "$1" ]]
}