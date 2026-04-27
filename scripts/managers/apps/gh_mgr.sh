#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="GitHub CLI (gh)"'
    echo 'APP_CHECK="command -v gh >/dev/null 2>&1"'
    exit 0
fi

if [ "$2" = "arch" ]; then
    PKG="github-cli"
else
    PKG="gh"
fi

manage_package "$1" "$2" "$PKG"
