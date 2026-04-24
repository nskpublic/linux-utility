#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="UFW Firewall"'
    echo 'APP_CHECK="command -v ufw >/dev/null 2>&1"'
    exit 0
fi


if [ "$ACTION" = "uninstall" ]; then
    sudo ufw disable
    manage_package "$ACTION" "$OS_FAMILY" ufw
    exit 0
fi

manage_package "$ACTION" "$OS_FAMILY" ufw

echo "Configuring firewall..."
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
