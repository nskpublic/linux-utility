#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Curl"'
    echo 'APP_CHECK="command -v curl >/dev/null 2>&1"'
    exit 0
fi

manage_package "$1" "$2" curl
