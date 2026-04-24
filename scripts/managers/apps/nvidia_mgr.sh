#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="NVIDIA Open Drivers"'
    echo 'APP_CHECK="pacman -Qq nvidia-open >/dev/null 2>&1"'
    echo "APP_CONDITION='lspci | grep -i -q nvidia'"
    exit 0
fi


if [ "$ACTION" = "uninstall" ]; then
    remove_package "$OS_FAMILY" nvidia-open nvidia-utils egl-wayland
    exit 0
fi

if lspci | grep -i -q "nvidia"; then
    echo "NVIDIA hardware detected. Installing open drivers..."
    install_package "$OS_FAMILY" nvidia-open nvidia-utils egl-wayland

    # 1. Update GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub
    GRUB_FILE="/etc/default/grub"
    if [ -f "$GRUB_FILE" ]; then
        GRUB_CHANGED=false
        if ! grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
            echo "Adding nvidia-drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT..."
            sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' "$GRUB_FILE"
            GRUB_CHANGED=true
        else
            echo "nvidia-drm.modeset=1 already exists in GRUB_CMDLINE_LINUX_DEFAULT, skipping."
        fi
        
        # Add ibt=off for Intel processors
        if grep -q "GenuineIntel" /proc/cpuinfo; then
            echo "Intel processor detected."
            if ! grep -q "ibt=off" "$GRUB_FILE"; then
                echo "Adding ibt=off to GRUB_CMDLINE_LINUX_DEFAULT..."
                sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 ibt=off"/' "$GRUB_FILE"
                GRUB_CHANGED=true
            else
                echo "ibt=off already exists in GRUB_CMDLINE_LINUX_DEFAULT, skipping."
            fi
        fi
        
        if [ "$GRUB_CHANGED" = true ]; then
            echo "Updating GRUB configuration..."
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    fi

    # 2. Update MODULES in /etc/mkinitcpio.conf
    MKINIT_FILE="/etc/mkinitcpio.conf"
    if [ -f "$MKINIT_FILE" ]; then
        if ! grep -q "^MODULES=.*nvidia" "$MKINIT_FILE"; then
            echo "Adding nvidia modules to MODULES in mkinitcpio.conf..."
            sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINIT_FILE"
            
            sudo mkinitcpio -P
        else
            echo "NVIDIA modules already exist in MODULES of mkinitcpio.conf, skipping."
        fi
    fi
else
    echo "No NVIDIA hardware detected. Skipping drivers installation."
fi
