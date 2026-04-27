#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Steam"'
    echo 'APP_CHECK="command -v steam >/dev/null 2>&1 || flatpak info com.valvesoftware.Steam >/dev/null 2>&1"'
    exit 0
fi

if [ "$1" = "uninstall" ]; then
    if command -v steam >/dev/null 2>&1; then
        remove_package "$2" steam
    fi
    if flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
        flatpak uninstall -y com.valvesoftware.Steam
    fi
else
    # Default to repo version on Arch if multilib is enabled, otherwise Flatpak is a safe bet
    if [[ "$2" == "arch" ]]; then
        install_package "$2" steam
    else
        # For others, flatpak is often easier for Steam
        if command -v flatpak >/dev/null 2>&1; then
            flatpak install -y flathub com.valvesoftware.Steam
        else
            install_package "$2" steam
        fi
    fi
fi
