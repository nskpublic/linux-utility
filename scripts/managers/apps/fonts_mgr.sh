#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="System Fonts (JetBrains Mono & Poppins)"'
    echo 'APP_CHECK="fc-list | grep -qi "JetBrains" && fc-list | grep -qi "Poppins""'
    exit 0
fi


if [ "$ACTION" = "uninstall" ]; then
    echo "Removing system fonts is restricted for desktop safety."
    exit 0
fi

case "$OS_FAMILY" in
    "arch" )
        install_package "$OS_FAMILY" ttf-jetbrains-mono-nerd ttf-poppins
        ;;
    "debian" )
        install_package "$OS_FAMILY" fonts-poppins fonts-jetbrains-mono || echo "Fonts not found. Install manually."
        ;;
    "fedora" )
        install_package "$OS_FAMILY" jetbrains-mono-fonts google-poppins-fonts || echo "Fonts missing."
        ;;
    * )
        echo "Unsupported distribution for fonts auto-installation"
        ;;
esac
