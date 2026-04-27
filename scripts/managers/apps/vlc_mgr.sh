#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="VLC"'
    echo 'APP_CHECK="command -v vlc >/dev/null 2>&1"'
    exit 0
fi

if [[ "$2" == "arch" ]]; then
    manage_package "$1" "$2" vlc vlc-plugin-ffmpeg vlc-plugins-all gst-plugin-pipewire gst-plugins-bad gst-plugins-good gst-plugins-ugly
elif [[ "$2" == "debian" ]]; then
    manage_package "$1" "$2" vlc ubuntu-restricted-extras
else
    manage_package "$1" "$2" vlc
fi
