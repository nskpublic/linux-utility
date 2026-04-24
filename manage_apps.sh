#!/usr/bin/env bash

# Detect Distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_LIKE=${ID_LIKE:-$ID}
else
    echo "Unsupported or unknown distribution."
    exit 1
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

echo -e "\e[1;36mDetected distribution: \e[1;32m$DISTRO\e[0m (Family: \e[1;32m$OS_FAMILY\e[0m)\n"

export AUR_HELPER="sudo pacman"
if [[ "$OS_FAMILY" == "arch" ]]; then
    while true; do
        echo "Select an AUR package manager (or press Enter to default to pacman):"
        echo "1) paru"
        echo "2) yay"
        read -p "Choice [1/2]: " aur_choice
        case "$aur_choice" in
            1) AUR_HELPER="paru" ;;
            2) AUR_HELPER="yay" ;;
            *) AUR_HELPER="sudo pacman" ;;
        esac
        echo -e "Using package manager: \e[1;32m$AUR_HELPER\e[0m\n"

        if [[ "$AUR_HELPER" == "paru" || "$AUR_HELPER" == "yay" ]]; then
            if ! command -v "$AUR_HELPER" &> /dev/null; then
                echo -e "\e[1;33m$AUR_HELPER is not installed.\e[0m"
                read -p "Would you like to install it now? [Y/n]: " install_aur
                if [[ -z "$install_aur" || "$install_aur" == "y" || "$install_aur" == "Y" ]]; then
                    echo "Installing $AUR_HELPER from the AUR..."
                    sudo pacman -S --needed --noconfirm base-devel git
                    git clone "https://aur.archlinux.org/$AUR_HELPER.git" "/tmp/$AUR_HELPER-install"
                    (cd "/tmp/$AUR_HELPER-install" && makepkg -si --noconfirm)
                    rm -rf "/tmp/$AUR_HELPER-install"
                    echo -e "\e[1;32m$AUR_HELPER installed successfully.\e[0m\n"
                    break
                else
                    echo -e "\e[1;31mWarning: You chose $AUR_HELPER but opted out of installing it. Please select an AUR helper or select default by pressing enter.\e[0m\n"
                fi
            else
                echo -e "\e[1;32m$AUR_HELPER is already installed.\e[0m\n"
                break
            fi
        else
            break
        fi
    done
fi

app_names=()
app_scripts=()
app_checks=()

echo -e "\n\e[1;36mScanning system for modules...\e[0m"
for script_path in ./scripts/managers/apps/*_mgr.sh; do
    [ -e "$script_path" ] || continue
    info_output=$(bash "$script_path" "info" 2>/dev/null)
    if [[ -n "$info_output" && "$info_output" == *APP_NAME=* ]]; then
        # Reset variables
        APP_NAME=""
        APP_CHECK=""
        APP_CONDITION=""
        
        eval "$info_output"
        
        if [ -n "$APP_CONDITION" ]; then
            eval "$APP_CONDITION" || continue
        fi
        
        script_file=$(basename "$script_path")
        app_names+=("$APP_NAME")
        app_scripts+=("${script_file%_mgr.sh}")
        app_checks+=("${APP_CHECK:-false}")
    fi
done

echo -e "\e[1;36mScanning system for installed packages...\e[0m"
app_installed_status=()
for i in "${!app_names[@]}"; do
    if eval "${app_checks[$i]}"; then
        app_installed_status[$i]=true
    else
        app_installed_status[$i]=false
    fi
done

# Hand off control to the multi-select TUI menu
source "$(dirname "$0")/tui/menu.sh"

# Display chosen packages and await final confirmation
source "$(dirname "$0")/tui/summary.sh"

echo -e "\n\e[1;32mStarting operation...\e[0m"

# Execute uninstall scripts
for i in "${!uninstall_scripts[@]}"; do
    script="${uninstall_scripts[$i]}"
    name="${uninstall_names[$i]}"
    script_path="./scripts/managers/apps/${script}_mgr.sh"
    
    echo -e "\n\e[1;31m>>> Uninstalling $name ($script_path)...\e[0m"
    if [ -f "$script_path" ]; then
        bash "$script_path" "uninstall" "$OS_FAMILY"
    else
        echo -e "\e[1;31mError: Script $script_path not found. Skipping.\e[0m"
    fi
done

# Execute install modular scripts
for i in "${!install_scripts[@]}"; do
    script="${install_scripts[$i]}"
    name="${install_names[$i]}"
    script_path="./scripts/managers/apps/${script}_mgr.sh"
    
    echo -e "\n\e[1;36m>>> Installing/Updating $name ($script_path)...\e[0m"
    if [ -f "$script_path" ]; then
        bash "$script_path" "install" "$OS_FAMILY"
    else
        echo -e "\e[1;31mError: Script $script_path not found. Skipping.\e[0m"
    fi
done

echo -e "\n\e[1;32mInstallation Process Completed!\e[0m"
