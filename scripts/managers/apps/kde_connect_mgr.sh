#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"
ACTION=$1
DISTRO=$2

if [ "$1" = "info" ]; then
    echo 'APP_NAME="KDE Connect"'
    echo 'APP_CHECK="command -v kdeconnect-cli >/dev/null 2>&1"'
    exit 0
fi

if [ "$DISTRO" = "fedora" ]; then
    PKG="kde-connect"
else
    PKG="kdeconnect"
fi

manage_package "$ACTION" "$DISTRO" "$PKG"
