#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Visual Studio Code"'
    echo 'APP_CHECK="command -v code >/dev/null 2>&1"'
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    case "$OS_FAMILY" in
        "arch" )
            remove_package "$OS_FAMILY" visual-studio-code-bin
            ;;
        "debian" )
            sudo snap remove code || sudo apt-get purge -y code
            ;;
        "fedora" )
            remove_package "$OS_FAMILY" code
            ;;
        * )
            echo "Unsupported distribution: $OS_FAMILY for VS Code uninstallation."
            ;;
    esac
else
    case "$OS_FAMILY" in
    "arch" )
        install_package "$OS_FAMILY" visual-studio-code-bin
        ;;
    "debian" )
        # Can use snap on ubuntu
        sudo snap install --classic code || echo "Snap not installed or failed, please install manually"
        ;;
    "fedora" )
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf check-update
        install_package "$OS_FAMILY" code
        ;;
    * )
        echo "Unsupported distribution: $OS_FAMILY for VS Code."
    esac
fi
