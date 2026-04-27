#!/usr/bin/env bash

# Global Logging Variables
LOG_FILE=""

# Usage: detect_os
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_LIKE=${ID_LIKE:-$ID}
    else
        echo "Unsupported or unknown distribution."
        return 1
    fi

    if [[ "$DISTRO_LIKE" == *"arch"* || "$DISTRO" == "arch" ]]; then
        OS_FAMILY="arch"
    elif [[ "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* || "$DISTRO" == "debian" ]]; then
        OS_FAMILY="debian"
    elif [[ "$DISTRO_LIKE" == *"fedora"* || "$DISTRO_LIKE" == *"rhel"* || "$DISTRO" == "fedora" ]]; then
        OS_FAMILY="fedora"
    else
        OS_FAMILY=$DISTRO
    fi
    export OS_FAMILY
    export DISTRO
}

# Usage: ensure_jq
ensure_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "\e[1;33m'jq' is required but not installed.\e[0m"
        # We need to make sure we read from tty for the prompt
        read -p "Would you like to install it now? [Y/n]: " install_jq < /dev/tty
        if [[ -z "$install_jq" || "$install_jq" == "y" || "$install_jq" == "Y" ]]; then
            [ -z "$OS_FAMILY" ] && detect_os
            echo "Installing jq..."
            install_package "$OS_FAMILY" jq
        else
            echo -e "\e[1;31mError: 'jq' is required for this script to function. Exiting.\e[0m"
            exit 1
        fi
    fi
}

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
    local mode="$1"
    
    # Only show footer and sleep if we are NOT in delete/silent mode
    if [[ "$mode" != "silent" && "$mode" != "delete" ]]; then
        echo "---------------------------------------------------"
        echo "Log Session Ended: $(date)"
        echo "---------------------------------------------------"
        sleep 1
    fi
    
    # Handle log file deletion
    if [ "$mode" = "delete" ]; then
        rm -f "$LOG_FILE"
    elif [ -t 0 ] && [ "$mode" != "silent" ]; then
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

# Usage: copy_with_prompt <source> <destination> <is_directory>
copy_with_prompt() {
    local src="$1"
    local dst="$2"
    local is_dir="$3"
    
    # Expand ~
    dst="${dst/#\~/$HOME}"
    
    if [ -e "$dst" ]; then
        # Check if identical (using diff for files or a simple existence check for dirs)
        local identical=false
        if [ "$is_dir" = "true" ]; then
            # For directories, we'll just check if it exists for now, 
            # or we could do a deeper check. Let's keep it simple: if it exists, ask.
            identical=false 
        else
            if diff -q "$src" "$dst" >/dev/null 2>&1; then
                identical=true
            fi
        fi
        
        if [ "$identical" = "true" ]; then
            echo -e "  \e[1;32m[Identical]\e[0m $dst already matches."
            return 0
        fi
        
        echo -e "  \e[1;33m[Conflict]\e[0m $dst already exists and is different."
        pause_logging
        read -p "    What to do? [o]verwrite, [s]kip, [b]ackup & overwrite? [o/s/b]: " choice < /dev/tty
        resume_logging
        
        case "$choice" in
            s|S) echo "    Skipping $dst"; return 0 ;;
            b|B) 
                local backup="${dst}.bak_$(date +%Y%m%d_%H%M%S)"
                echo "    Backing up to $backup"
                mv "$dst" "$backup"
                ;;
            *) echo "    Overwriting $dst" ;;
        esac
    fi
    
    if [ "$is_dir" = "true" ]; then
        mkdir -p "$dst"
        cp -r "$src"/. "$dst/"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
    echo -e "  \e[1;32m[Done]\e[0m Deployed to $dst"
}
