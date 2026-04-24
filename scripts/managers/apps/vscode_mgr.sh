#!/usr/bin/env bash
ACTION=$1
DISTRO=$2

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Visual Studio Code"'
    echo 'APP_CHECK="command -v code >/dev/null 2>&1"'
    exit 0
fi

if [ "$ACTION" = "uninstall" ]; then
    case "$DISTRO" in
        "arch" )
            ${AUR_HELPER:-sudo pacman} -Rns --noconfirm visual-studio-code-bin
            ;;
        "debian" )
            sudo snap remove code || sudo apt-get purge -y code
            ;;
        "fedora" )
            sudo dnf autoremove -y code
            ;;
        * )
            echo "Unsupported distribution: $DISTRO for VS Code uninstallation."
            ;;
    esac
else
    case "$DISTRO" in
    "arch" )
        ${AUR_HELPER:-sudo pacman} -S --noconfirm visual-studio-code-bin
        ;;
    "debian" )
        # Can use snap on ubuntu
        sudo snap install --classic code || echo "Snap not installed, please install manually"
        ;;
    "fedora" )
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf check-update
        sudo dnf install -y code
        ;;
    * )
        echo "Unsupported distribution: $DISTRO for VS Code."
    esac
fi
