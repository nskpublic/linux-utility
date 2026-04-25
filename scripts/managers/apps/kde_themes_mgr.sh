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
        if ! install_package "$OS_FAMILY" sddm-kcm kvantum-qt6-git tela-circle-icon-theme-git; then
            echo -e "\e[1;31mError: Failed to install KDE theme packages. Skipping custom theme installation.\e[0m"
            exit 1
        fi
        ;;
    "debian" )
        if ! install_package "$OS_FAMILY" sddm-theme-debian kvantum; then
            echo -e "\e[1;31mError: Failed to install KDE theme packages. Skipping custom theme installation.\e[0m"
            exit 1
        fi
        echo "Tela icons must be installed via GitHub script manually on Ubuntu."
        ;;
    "fedora" )
        if ! install_package "$OS_FAMILY" kvantum sddm; then
            echo -e "\e[1;31mError: Failed to install KDE theme packages. Skipping custom theme installation.\e[0m"
            exit 1
        fi
        echo "Tela icons must be installed via GitHub script manually on Fedora."
        ;;
    * )
        echo "Unsupported distribution: $OS_FAMILY"
        exit 1
        ;;
esac

echo "Installing Orchis KDE theme..."
GIT_DIR="$HOME/my/gits"
mkdir -p "$GIT_DIR"
ORCHIS_DIR="$GIT_DIR/Orchis-kde"
if [ ! -d "$ORCHIS_DIR" ]; then
    if ! git clone https://github.com/vinceliuice/Orchis-kde.git "$ORCHIS_DIR"; then
        echo -e "\e[1;31mError: Failed to clone Orchis KDE theme repository.\e[0m"
        exit 1
    fi
else
    (cd "$ORCHIS_DIR" && git pull)
fi

(
    cd "$ORCHIS_DIR" || exit 1
    ./install.sh
)
