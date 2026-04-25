#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Nano Text Editor"'
    echo 'APP_CHECK="command -v nano >/dev/null 2>&1"'
    exit 0
fi

manage_package "$1" "$2" nano
