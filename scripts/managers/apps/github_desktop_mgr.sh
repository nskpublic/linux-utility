#!/usr/bin/env bash
ACTION=$1
DISTRO=$2

if [ "$1" = "info" ]; then
    echo 'APP_NAME="GitHub Desktop"'
    echo 'APP_CHECK="command -v github-desktop >/dev/null 2>&1 || ls /opt/GitHub/Desktop/github-desktop >/dev/null 2>&1"'
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    case "$DISTRO" in
        "arch" )
            ${AUR_HELPER:-sudo pacman} -Rns --noconfirm github-desktop-bin
            ;;
        "debian" | "fedora" )
            echo "Please uninstall GitHub Desktop manually (flatpak uninstall)."
            ;;
        * )
            echo "Unsupported distribution: $DISTRO"
            ;;
    esac
else
    case "$DISTRO" in
    "arch" )
        ${AUR_HELPER:-sudo pacman} -S --noconfirm github-desktop-bin
        ;;
    "debian" )
        # Flatpak or manual installation
        echo "Please install github desktop via Flatpak or direct .deb download on Ubuntu."
        ;;
    "fedora" )
        echo "Please install github desktop via Flatpak or third-party repo on Fedora."
        ;;
    * )
        echo "Unsupported distribution: $DISTRO"
    esac
fi
