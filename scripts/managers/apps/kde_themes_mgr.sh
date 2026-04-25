#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="KDE Themes (Kvantum, Orchis, Tela, SDDM)"'
    echo 'APP_CHECK="command -v kvantummanager >/dev/null 2>&1"'
    echo "APP_CONDITION='[[ \"$XDG_CURRENT_DESKTOP\" == *\"KDE\"* ]] || [[ \"$DESKTOP_SESSION\" == *\"plasma\"* ]]'"
    exit 0
fi


if [ "$ACTION" = "uninstall" ]; then
    echo "Removing global KDE display themes is heavily restricted to prevent desktop crashes."
    exit 0
fi

case "$OS_FAMILY" in
    "arch" )
        install_package "$OS_FAMILY" sddm-kcm kvantum-qt6-git tela-circle-icon-theme-git
        ;;
    "debian" )
        install_package "$OS_FAMILY" sddm-theme-debian kvantum
        echo "Tela icons must be installed via GitHub script manually on Ubuntu."
        ;;
    "fedora" )
        install_package "$OS_FAMILY" kvantum sddm
        echo "Tela icons must be installed via GitHub script manually on Fedora."
        ;;
    * )
        echo "Unsupported distribution: $OS_FAMILY"
        ;;
esac

echo "Installing Orchis KDE theme..."
GIT_DIR="$HOME/my/gits"
mkdir -p "$GIT_DIR"
ORCHIS_DIR="$GIT_DIR/Orchis-kde"
if [ ! -d "$ORCHIS_DIR" ]; then
    git clone https://github.com/vinceliuice/Orchis-kde.git "$ORCHIS_DIR"
else
    (cd "$ORCHIS_DIR" && git pull)
fi
(
    cd "$ORCHIS_DIR" || exit
    ./install.sh
)
