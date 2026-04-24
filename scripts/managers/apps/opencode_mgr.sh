#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Opencode"'
    echo 'APP_CHECK="pacman -Qq opencode >/dev/null 2>&1 || paru -Qq opencode >/dev/null 2>&1"'
    exit 0
fi


manage_package "$ACTION" "$OS_FAMILY" opencode
