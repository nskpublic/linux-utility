#!/bin/bash

# Enable strict error handling
set -e

# Overrides for testability
AUTO_CONFIRM="${AUTO_CONFIRM:-0}"

source "$(dirname "$0")/scripts/utils.sh"
setup_logging

# Check if the script is run with root/sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root"
  exit 1
fi

get_confirmation() {
  if [ "$AUTO_CONFIRM" -eq 1 ]; then
    return 0
  fi
  read -p "$1 (y/N): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    return 0
  else
    return 1
  fi
}

echo "======================================"
echo " Post Installation Configuration Tool"
echo "======================================"
echo "This script automates the chroot and post-installation setup for"
echo "Arch Linux on a removable drive, making it bootable on any computer."
echo ""

# Step 1 & 2: Check if running in archiso and /mnt exists
if [[ "$(hostname)" != "archiso" ]]; then
  echo "WARNING: You do not appear to be running this from the Arch installation ISO (hostname is not 'archiso')."
  echo "If you have already chrooted into the installation, DO NOT run this script here."
  if ! get_confirmation "Are you sure you want to proceed?"; then
    echo "Operation cancelled."
    cleanup_logging
    exit 0
  fi
fi

echo "Checking mounted file systems for /mnt..."
df -h | grep "/mnt" || echo "/mnt doesn't seem to be explicitly listed by df, checking /mnt directory..."

if [ ! -d "/mnt/boot" ]; then
  echo "WARNING: /mnt/boot does not exist. Please ensure your root (and boot/efi) partitions are mounted to /mnt."
  if ! get_confirmation "Proceed anyway?"; then
    cleanup_logging
    exit 1
  fi
fi

# Step 3: Mount virtual filesystems needed for chroot
echo ""
echo "Mounting system directories into /mnt..."
for i in /dev /dev/pts /proc /sys /run; do
  if ! mountpoint -q "/mnt$i"; then
    mount -B "$i" "/mnt$i"
    echo "Mounted $i"
  else
    echo "Already mounted: /mnt$i"
  fi
done

# Step 4 - 12: Enter chroot and execute operations
echo ""
echo "Entering chroot environment to configure bootloader..."
echo "--------------------------------------------------------"

chroot /mnt /bin/bash << 'CHROOT_EOF'
# Inside chroot

echo "Mounting efivarfs..."
if ! mountpoint -q /sys/firmware/efi/efivars; then
  mount -t efivarfs none /sys/firmware/efi/efivars || echo "Warning: Could not mount efivarfs."
else
  echo "efivarfs already mounted."
fi

echo "Checking EFI boot manager:"
efibootmgr || echo "Warning: efibootmgr command failed or returned nothing."

echo ""
echo "Installing GRUB for UEFI..."
# Adding --removable to make the drive bootable on any computer without host NVRAM changes
grub-install --target=x86_64-efi --efi-directory=/boot --removable

echo ""
echo "Installing os-prober..."
pacman -S --noconfirm os-prober

echo ""
echo "Running os-prober..."
os-prober

echo ""
echo "Configuring /etc/default/grub..."
GRUB_FILE="/etc/default/grub"
if grep -q "^#GRUB_DISABLE_OS_PROBER=false" "$GRUB_FILE" || grep -q "^# GRUB_DISABLE_OS_PROBER=false" "$GRUB_FILE"; then
  echo "Uncommenting GRUB_DISABLE_OS_PROBER=false..."
  sed -i 's/^#[ \t]*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_FILE"
elif ! grep -q "^GRUB_DISABLE_OS_PROBER=false" "$GRUB_FILE"; then
  echo "Appending GRUB_DISABLE_OS_PROBER=false..."
  echo "GRUB_DISABLE_OS_PROBER=false" >> "$GRUB_FILE"
else
  echo "GRUB_DISABLE_OS_PROBER=false is already configured."
fi

echo ""
echo "Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "--------------------------------------------------------"
echo "Exiting chroot environment..."
CHROOT_EOF

# Step 13: Verify
echo ""
echo "Verifying EFI boot manager entries from host..."
efibootmgr || echo "efibootmgr command failed to execute."

echo ""
echo "Post-installation configuration successfully completed!"

cleanup_logging
