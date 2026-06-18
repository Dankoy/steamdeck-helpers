#!/bin/bash
# ============================================
# Library for file processing functions
# ============================================

# Загружаем зависимости
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# ---------- REPLACE FUNCTIONS ----------
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
    
    # Проверяем существование файла только если не отключена проверка
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

# ---------- COPY FUNCTIONS ----------
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

# ---------- TEMPLATE FUNCTIONS ----------
process_template() {
    local template_file="$1"
    local output_file="$2"
    local -n vars_array="$3"
    
    if ! check_file_exists "$template_file"; then
        log_error "Template file '$template_file' not found!"
        return 1
    fi
    
    log_info "Processing template '$template_file' -> '$output_file'"
    
    # Копируем шаблон
    cp "$template_file" "$output_file"
    
    # Заменяем переменные
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

# -------- CHECK IF DIRECTORY HAS SPECIFIC FILES ---------
check_files_exist_in_dest() {
    local dest="$1"
    shift
    local files_to_check=("$@")
    
    if ! check_folder_exists "$dest"; then
        log_info "Directory '$dest' doesn't exist. Considered as empty."
        return 1 # No files
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