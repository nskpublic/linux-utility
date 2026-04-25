#!/bin/bash

source "$(dirname "$0")/scripts/utils.sh"
setup_logging

# Overrides for testability
GRUB_FILE="${GRUB_FILE:-/etc/default/grub}"
GRUB_UPDATE_CMD="${GRUB_UPDATE_CMD:-grub-mkconfig -o /boot/grub/grub.cfg}"
GRUB_CMDLINE_PARAM_NAME="GRUB_CMDLINE_LINUX_DEFAULT"
PARAM_BASE="i915.enable_dpcd_backlight"
BACKLIGHT_PARAM="${PARAM_BASE}=1"
SKIP_ROOT_CHECK="${SKIP_ROOT_CHECK:-0}"
AUTO_CONFIRM="${AUTO_CONFIRM:-0}"

# Check if the script is run with root/sudo privileges (unless skipped for testing)
if [ "$SKIP_ROOT_CHECK" -ne 1 ] && [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  cleanup_logging
  exit 1
fi

get_confirmation() {
  if [ "$AUTO_CONFIRM" -eq 1 ]; then
    return 0
  fi
  read -p "Do you want to proceed? (y/N): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    return 0
  elif [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
    return 1
  else
    return 1
  fi
}

execute_fix() {
  local sed_expression="$1"
  if get_confirmation; then
    echo "Applying backlight fix..."
    sed -i "$sed_expression" "$GRUB_FILE"
    echo "Applied the changes to $GRUB_FILE"
    echo ""
    echo "Now, updating GRUB configuration..."
    $GRUB_UPDATE_CMD
    
    echo "Backlight fix applied successfully!"
    echo "Please restart your system to see the changes."
  else
    echo "Operation cancelled."
    cleanup_logging
    exit 0
  fi
}

# Check if the parameter exists with ANY value (using -F for fixed string is safer)
if grep -Fq "${PARAM_BASE}=" "$GRUB_FILE"; then
  # It exists. Check if it's strictly set to 1
  if grep -Fq "$BACKLIGHT_PARAM" "$GRUB_FILE"; then
    echo "The backlight fix is already correctly applied in $GRUB_FILE."
    cleanup_logging
    exit 0
  else
    echo "Found existing '${PARAM_BASE}' parameter, but it is not set to 1."
    echo ""
    echo "Next steps we are going to perform:"
    echo "1. Replace the existing '${PARAM_BASE}' value with '1' in $GRUB_FILE."
    echo "   (This modifies the value in-place without removing other parameters)"
    echo "2. Run '$GRUB_UPDATE_CMD' to apply changes."
    echo ""
    
    # Replace existing i915.enable_dpcd_backlight=... with =1
    execute_fix "s/${PARAM_BASE}=[^ \"\t]*/$BACKLIGHT_PARAM/g"
  fi
else
  # The parameter does not exist at all, so we can safely append it
  echo "The backlight fix is not present in $GRUB_FILE."
  echo ""
  echo "Next steps we are going to perform:"
  echo "1. Append '$BACKLIGHT_PARAM' to the '$GRUB_CMDLINE_PARAM_NAME' line in $GRUB_FILE."
  echo "   (This carefully appends without removing any existing parameters)"
  echo "2. Run '$GRUB_UPDATE_CMD' to apply changes."
  echo ""
  
  # Append the parameter to GRUB_CMDLINE_LINUX_DEFAULT
  execute_fix "s/^\(${GRUB_CMDLINE_PARAM_NAME}=\"[^\"]*\)\"/\1 $BACKLIGHT_PARAM\"/"
fi

cleanup_logging
