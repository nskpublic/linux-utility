#!/usr/bin/env bash
ACTION=$1
DISTRO=$2

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Flutter"'
    echo 'APP_CHECK="command -v flutter >/dev/null 2>&1"'
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    case "$DISTRO" in
        "arch" )
            ${AUR_HELPER:-sudo pacman} -Rns --noconfirm flutter-bin
            ;;
        "debian" )
            sudo snap remove flutter
            ;;
        "fedora" )
            sudo snap remove flutter
            ;;
        * )
            echo "Unsupported distribution: $DISTRO for Flutter uninstallation."
            ;;
    esac
else
    case "$DISTRO" in
    "arch" )
        ${AUR_HELPER:-sudo pacman} -S --noconfirm flutter-bin
        ;;
    "debian" )
        sudo snap install flutter --classic || echo "Snap not installed or failed, please install Flutter manually"
        ;;
    "fedora" )
        sudo snap install flutter --classic || echo "Snap not installed or failed, please install Flutter manually"
        ;;
    * )
        echo "Unsupported distribution: $DISTRO for Flutter."
    esac
fi
