#!/usr/bin/env bash

# Global Logging Variables
LOG_FILE=""

# Usage: setup_logging
setup_logging() {
    local log_dir="$(dirname "$0")/logs"
    mkdir -p "$log_dir"
    
    LOG_FILE="$log_dir/log_$(date +"%Y%m%d_%H%M%S_%3N").log"
    
    # Save original stdout and stderr to FDs 3 and 4
    exec 3>&1
    exec 4>&2
    
    # Redirect stdout and stderr to tee with ANSI strip filter
    exec > >(tee >(sed -u -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> "$LOG_FILE")) 2>&1
    
    echo "---------------------------------------------------"
    echo "Log Session Started: $(date)"
    echo "Log File: $LOG_FILE"
    echo "System: $(uname -a)"
    echo "---------------------------------------------------"
}

# Usage: pause_logging
# Temporarily bypasses the log file and redirects output back to the original terminal FDs
pause_logging() {
    exec >&3 2>&4
}

# Usage: resume_logging
# Restores the filtered redirection to the log file
resume_logging() {
    if [ -n "$LOG_FILE" ]; then
        exec > >(tee >(sed -u -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> "$LOG_FILE")) 2>&1
    fi
}

# Usage: cleanup_logging
cleanup_logging() {
    echo "---------------------------------------------------"
    echo "Log Session Ended: $(date)"
    echo "---------------------------------------------------"
    
    # Give tee and sed a moment to finish writing
    sleep 1
    
    # Check if we are in a terminal (not piped) to ask for deletion
    if [ -t 0 ]; then
        # We need to make sure we are writing to the actual terminal for the prompt
        # even if logging is active.
        read -p "Would you like to delete the log file? ($LOG_FILE) [y/N]: " delete_log < /dev/tty
        if [[ "$delete_log" == "y" || "$delete_log" == "Y" ]]; then
            rm -f "$LOG_FILE"
            echo "Log file deleted."
        else
            echo "Log file preserved at: $LOG_FILE"
        fi
    fi
    
    # Close original FDs
    exec 3>&-
    exec 4>&-
}

# Usage: install_package <os_family> <package_name1> [package_name2 ...]
install_package() {
    local family=$1
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    case "$family" in
        "arch" )
            if ! ${AUR_HELPER:-sudo pacman} -S --noconfirm "${packages[@]}"; then
                echo -e "\e[1;31mError: Failed to install packages [ ${packages[*]} ] using ${AUR_HELPER:-sudo pacman}.\e[0m"
                return 1
            fi
            ;;
        "debian" )
            if ! sudo apt-get install -y "${packages[@]}"; then
                echo -e "\e[1;31mError: Failed to install packages [ ${packages[*]} ] using apt-get.\e[0m"
                return 1
            fi
            ;;
        "fedora" )
            if ! sudo dnf install -y "${packages[@]}"; then
                echo -e "\e[1;31mError: Failed to install packages [ ${packages[*]} ] using dnf.\e[0m"
                return 1
            fi
            ;;
        * )
            echo "Cannot automatically install [ ${packages[*]} ]. Unsupported OS family: $family"
            return 1
            ;;
    esac
    return 0
}

# Usage: remove_package <os_family> <package_name1> [package_name2 ...]
remove_package() {
    local family=$1
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    case "$family" in
        "arch" )
            if ! ${AUR_HELPER:-sudo pacman} -Rns --noconfirm "${packages[@]}"; then
                echo -e "\e[1;31mError: Failed to remove packages [ ${packages[*]} ] using ${AUR_HELPER:-sudo pacman}.\e[0m"
                return 1
            fi
            ;;
        "debian" )
            if ! sudo apt-get autoremove --purge -y "${packages[@]}"; then
                echo -e "\e[1;31mError: Failed to remove packages [ ${packages[*]} ] using apt-get.\e[0m"
                return 1
            fi
            ;;
        "fedora" )
            if ! sudo dnf autoremove -y "${packages[@]}"; then
                echo -e "\e[1;31mError: Failed to remove packages [ ${packages[*]} ] using dnf.\e[0m"
                return 1
            fi
            ;;
        * )
            echo "Cannot automatically remove [ ${packages[*]} ]. Unsupported OS family: $family"
            return 1
            ;;
    esac
    return 0
}

# Usage: manage_package <action> <os_family> <package_name1> [package_name2 ...]
manage_package() {
    local action=$1
    local family=$2
    shift 2

    if [ "$action" = "uninstall" ]; then
        remove_package "$family" "$@"
    else
        install_package "$family" "$@"
    fi
}
