#!/bin/bash
# ============================================
# Library for file processing functions
# Provides file operations: replace, copy, template processing
# ============================================

# Load dependencies
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# ============================================
# REPLACE FUNCTIONS
# ============================================

# ============================================
# Function: replace_in_file
# ============================================
# Replaces all occurrences of a pattern with a replacement string in a file.
#
# @param {string} dest      - Directory containing the file
# @param {string} file_name - Name of the file to modify
# @param {string} from      - Pattern to search for (supports sed special chars)
# @param {string} to        - Replacement string (supports sed special chars)
#
# @returns {number} 0 - replacement successful, 1 - error
#
# @example
#   replace_in_file "/home/user/.config" "app.conf" "_USER_" "john"
#   # Replaces all _USER_ with john in app.conf
#
# @example
#   replace_in_file "/home/user" ".bashrc" "/old/path" "/new/path"
#   # Replaces all /old/path with /new/path in .bashrc
#
# @note Special characters in patterns are automatically escaped for sed
# @note Set SKIP_FILE_CHECK=true to skip file existence validation
# ============================================
replace_in_file() {
    local dest="$1"
    local file_name="$2"
    local from="$3"
    local to="$4"
    local full_path="${dest}${file_name}"
    
    # Check empty from and to
    if is_empty "$from" || is_empty "$to"; then
        log_error "Empty replacement pattern in '$file_name'!"
        return 1
    fi
    
    # Check if file exists unless disabled
    if [[ "${SKIP_FILE_CHECK:-false}" != "true" ]]; then
        if ! check_file_exists "$full_path"; then
            log_error "File '$full_path' not found for replacement!"
            return 1
        fi
    fi
    
    local escaped_from
    local escaped_to
    escaped_from=$(escape_sed_pattern "$from")
    escaped_to=$(escape_sed_pattern "$to")
    
    if sed -i "s/${escaped_from}/${escaped_to}/g" "$full_path" 2>/dev/null; then
        log_info "Replacement successful in '$file_name': '$from' -> '$to'"
        return 0
    else
        log_error "Failed to replace in '$file_name'"
        return 1
    fi
}

# ============================================
# Function: replace_multiple_in_file
# ============================================
# Performs multiple search-and-replace operations on a single file.
#
# @param {string} file_path    - Full path to the file
# @param {string[]} replacements - Array of [from, to, from, to, ...] pairs
#
# @returns {number} 0 - all replacements successful, 1 - some failed
#
# @example
#   replace_multiple_in_file "/home/user/.env" \
#       "_USER_" "john" \
#       "_HOME_" "/home/john" \
#       "_SHELL_" "/bin/bash"
#   # Replaces all three patterns in .env file
# ============================================
replace_multiple_in_file() {
    local file_path="$1"
    shift
    local replacements=("$@")
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File '$file_path' not found!"
        return 1
    fi
    
    log_info "Processing file: $file_path"
    
    local has_errors=false
    for ((i=0; i<${#replacements[@]}; i+=2)); do
        local from="${replacements[i]}"
        local to="${replacements[i+1]}"
        
        replace_in_file "$(dirname "$file_path")/" "$(basename "$file_path")" "$from" "$to" || has_errors=true
    done
    
    if $has_errors; then
        log_error "Some replacements failed!"
        return 1
    else
        log_info "All replacements completed!"
        return 0
    fi
}

# ============================================
# COPY FUNCTIONS
# ============================================

# ============================================
# Function: copy_files
# ============================================
# Copies specified files from source to destination directory.
#
# @param {string} src           - Source directory
# @param {string} dest          - Destination directory
# @param {string[]} files_array - Reference to array of filenames to copy
#
# @returns {number} 0 - all files copied successfully, 1 - errors occurred
#
# @example
#   local files=("file1.txt" "file2.conf" "script.sh")
#   copy_files "/home/user/source" "/home/user/dest" files
#   # Copies all three files if they exist in source
#
# @note Only existing files from the array are copied
# @note Uses cp -v for verbose output
# ============================================
copy_files() {
    local src="$1"
    local dest="$2"
    local -n files_array="$3"
    
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
    
    # Check which files exist for copying
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
    
    # Copy only specified files
    log_info "Copying ${#files_to_copy[@]} file(s) from '$src' to '$dest'..."
    
    local copy_success=true
    for file in "${files_to_copy[@]}"; do
        if cp -v "${src}${file}" "${dest}" 2>/dev/null; then
            log_info "  Copied: $file"
        else
            log_error "  Failed to copy: $file"
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

# ============================================
# TEMPLATE FUNCTIONS
# ============================================

# ============================================
# Function: process_template
# ============================================
# Processes a template file by replacing variables and creates a new file.
#
# @param {string} template_file - Path to template file
# @param {string} output_file   - Path where processed file will be saved
# @param {string[]} vars_array  - Array of [var_name, var_value, ...] pairs
#
# @returns {number} 0 - processing successful, 1 - error
#
# @example
#   local vars=("_USER_" "john" "_HOME_" "/home/john")
#   process_template "/path/to/template.conf" "/path/to/output.conf" vars
#   # Creates output.conf from template with variables replaced
#
# @note Template file is copied before replacements
# @warning Output file will be overwritten if it exists
# ============================================
process_template() {
    local template_file="$1"
    local output_file="$2"
    local -n vars_array="$3"
    
    if ! check_file_exists "$template_file"; then
        log_error "Template file '$template_file' not found!"
        return 1
    fi
    
    log_info "Processing template '$template_file' -> '$output_file'"
    
    # Copy template
    cp "$template_file" "$output_file"
    
    # Replace variables
    local has_errors=false
    for ((i=0; i<${#vars_array[@]}; i+=2)); do
        local var_name="${vars_array[i]}"
        local var_value="${vars_array[i+1]}"
        
        replace_in_file "$(dirname "$output_file")/" "$(basename "$output_file")" "$var_name" "$var_value" || has_errors=true
    done
    
    if $has_errors; then
        log_error "Failed to process template!"
        return 1
    else
        log_info "Template processed successfully!"
        return 0
    fi
}