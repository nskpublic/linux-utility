#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Flutter"'
    echo 'APP_CHECK="command -v flutter >/dev/null 2>&1"'
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    case "$OS_FAMILY" in
        "arch" )
            remove_package "$OS_FAMILY" flutter-bin
            ;;
        "debian" | "fedora" )
            sudo snap remove flutter
            ;;
        * )
            echo "Unsupported distribution: $OS_FAMILY for Flutter uninstallation."
            ;;
    esac
else
    case "$OS_FAMILY" in
    "arch" )
        install_package "$OS_FAMILY" flutter-bin
        ;;
    "debian" | "fedora" )
        sudo snap install flutter --classic || echo "Snap not installed or failed, please install Flutter manually"
        ;;
    * )
        echo "Unsupported distribution: $OS_FAMILY for Flutter."
    esac
fi
