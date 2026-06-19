# ============================================
# OPTIONS PARSING FUNCTIONS
# ============================================

# ============================================
# Function: parse_options
# ============================================
# Parses command line options using getopts and stores them in global variables.
# This is a wrapper around getopts for consistent option handling.
#
# @param {string} optstring   - getopts option string (e.g., "f:o:vh")
# @param {string[]} args      - Array of arguments to parse (typically "$@")
# @param {string} usage_func  - Name of usage/help function to call on -h or error
#
# @example
#   parse_options "f:o:vh" "$@" "show_usage"
#   # Parses: -f file -o output -v -h
#
# @note Sets global variables with "OPT_" prefix
# ============================================
parse_options() {
    local optstring="$1"
    shift
    local usage_func="$1"
    shift
    local args=("$@")
    
    local opt
    local opt_value
    
    # Reset OPTIND
    OPTIND=1
    
    while getopts "$optstring" opt; do
        case $opt in
            h)
                if [[ -n "$usage_func" ]] && declare -f "$usage_func" >/dev/null; then
                    "$usage_func"
                else
                    echo "Usage: $0 [options]"
                    echo "  -h  Show this help"
                fi
                exit 0
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                if [[ -n "$usage_func" ]] && declare -f "$usage_func" >/dev/null; then
                    "$usage_func"
                fi
                exit 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                if [[ -n "$usage_func" ]] && declare -f "$usage_func" >/dev/null; then
                    "$usage_func"
                fi
                exit 1
                ;;
            *)
                # Store option value in global variable
                local var_name="OPT_${opt}"
                if [[ -n "$OPTARG" ]]; then
                    export "$var_name"="$OPTARG"
                else
                    export "$var_name"=true
                fi
                ;;
        esac
    done
    
    # Remove parsed options from arguments
    shift $((OPTIND - 1))
    
    # Store remaining arguments
    export OPT_ARGS=("$@")
}

# ============================================
# Function: get_option_value
# ============================================
# Gets the value of a parsed option.
#
# @param {string} option_name - Name of the option (without OPT_ prefix)
# @param {string} default     - Default value if option is not set
#
# @output {string} The option value
#
# @example
#   value=$(get_option_value "f" "default.txt")
#   # Returns: value from -f flag or "default.txt"
# ============================================
get_option_value() {
    local option_name="$1"
    local default="${2:-}"
    local var_name="OPT_${option_name}"
    
    if [[ -n "${!var_name:-}" ]]; then
        echo "${!var_name}"
    else
        echo "$default"
    fi
}

# ============================================
# Function: is_option_set
# ============================================
# Checks if an option was set on the command line.
#
# @param {string} option_name - Name of the option (without OPT_ prefix)
#
# @returns {number} 0 - option is set, 1 - option is not set
#
# @example
#   if is_option_set "v"; then
#       echo "Verbose mode enabled"
#   fi
# ============================================
is_option_set() {
    local option_name="$1"
    local var_name="OPT_${option_name}"
    
    [[ -n "${!var_name:-}" ]]
}

# ============================================
# Function: get_remaining_args
# ============================================
# Returns the remaining arguments after parsing options.
#
# @output {string[]} The remaining arguments
#
# @example
#   get_remaining_args
#   # Returns: args after options
# ============================================
get_remaining_args() {
    echo "${OPT_ARGS[@]}"
}