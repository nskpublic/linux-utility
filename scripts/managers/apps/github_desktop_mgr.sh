#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="GitHub Desktop"'
    echo 'APP_CHECK="command -v github-desktop >/dev/null 2>&1 || ls /opt/GitHub/Desktop/github-desktop >/dev/null 2>&1"'
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    case "$OS_FAMILY" in
        "arch" )
            remove_package "$OS_FAMILY" github-desktop-bin
            ;;
        "debian" | "fedora" )
            echo "Please uninstall GitHub Desktop manually (flatpak uninstall)."
            ;;
        * )
            echo "Unsupported distribution: $OS_FAMILY"
            ;;
    esac
else
    case "$OS_FAMILY" in
    "arch" )
        install_package "$OS_FAMILY" github-desktop-bin
        ;;
    "debian" )
        # Flatpak or manual installation
        echo "Please install github desktop via Flatpak or direct .deb download on Ubuntu."
        ;;
    "fedora" )
        echo "Please install github desktop via Flatpak or third-party repo on Fedora."
        ;;
    * )
        echo "Unsupported distribution: $OS_FAMILY"
    esac
fi
