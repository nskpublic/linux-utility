#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="GNOME Themes"'
    echo 'APP_CHECK="command -v tela-icon-theme >/dev/null 2>&1 || true"'
    echo "APP_CONDITION='[[ \"$XDG_CURRENT_DESKTOP\" == *\"GNOME\"* ]] || [[ \"$DESKTOP_SESSION\" == *\"gnome\"* ]]'"
    exit 0
fi


if [ "$ACTION" = "uninstall" ]; then
    echo "Removing global GNOME display themes is heavily restricted to prevent desktop crashes."
    exit 0
fi

case "$OS_FAMILY" in
    "arch" )
        install_package "$OS_FAMILY" tela-circle-icon-theme-git
        ;;
    "debian" )
        echo "Tela icons must be installed via GitHub script manually on Ubuntu."
        ;;
    "fedora" )
        echo "Tela icons must be installed via GitHub script manually on Fedora."
        ;;
    * )
        echo "Unsupported distribution: $OS_FAMILY"
        ;;
esac

echo "Installing Orchis GNOME theme..."
GIT_DIR="$HOME/my/gits"
mkdir -p "$GIT_DIR"
ORCHIS_DIR="$GIT_DIR/Orchis-theme"
if [ ! -d "$ORCHIS_DIR" ]; then
    git clone https://github.com/vinceliuice/Orchis-theme.git "$ORCHIS_DIR"
else
    (cd "$ORCHIS_DIR" && git pull)
fi
(
    cd "$ORCHIS_DIR" || exit
    ./install.sh
)
