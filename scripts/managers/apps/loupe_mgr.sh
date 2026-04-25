#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"
ACTION=$1
DISTRO=$2

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Loupe (Image Viewer)"'
    echo 'APP_CHECK="command -v loupe >/dev/null 2>&1"'
    exit 0
fi

manage_package "$ACTION" "$DISTRO" "loupe"
