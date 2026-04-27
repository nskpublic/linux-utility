#!/usr/bin/env bash

source "$(dirname "$0")/scripts/utils.sh"
setup_logging
trap 'cleanup_logging delete' EXIT

detect_os
echo -e "\e[1;36mDetected distribution: \e[1;32m$DISTRO\e[0m (Family: \e[1;32m$OS_FAMILY\e[0m)\n"
echo -e "\e[1;36mConfiguration Restoration Utility\e[0m\n"

METADATA="./configs/metadata.json"

if [ ! -f "$METADATA" ]; then
    echo -e "\e[1;31mError: Metadata file '$METADATA' not found.\e[0m"
    exit 1
fi

ensure_jq

app_names=()
app_scripts=() 
app_installed_status=()
app_categories=()
config_keys=() # To store the keys from JSON

echo -e "\e[1;36mLoading configurations from metadata.json...\e[0m"

# Get keys from JSON
keys=$(jq -r 'keys[]' "$METADATA")

# Group keys by type
folder_keys=()
file_keys=()

for key in $keys; do
    type=$(jq -r ".\"$key\".type" "$METADATA")
    if [ "$type" = "dir" ]; then
        folder_keys+=("$key")
    else
        file_keys+=("$key")
    fi
done

# Process Folders first, then Files
idx=0
for key in "${folder_keys[@]}" "${file_keys[@]}"; do
    name=$(jq -r ".\"$key\".name" "$METADATA")
    dest=$(jq -r ".\"$key\".dest" "$METADATA")
    type=$(jq -r ".\"$key\".type" "$METADATA")
    
    app_names+=("$name")
    app_scripts+=("$idx")
    config_keys+=("$key")
    
    if [ "$type" = "dir" ]; then
        app_categories+=("Folders")
    else
        app_categories+=("Files")
    fi
    
    # Expand ~ for check
    expanded_sys_path="${dest/#\~/$HOME}"
    if [ -e "$expanded_sys_path" ]; then
        app_installed_status[$idx]=true
    else
        app_installed_status[$idx]=false
    fi
    ((idx++))
done

if [ ${#app_names[@]} -eq 0 ]; then
    echo -e "\e[1;31mNo configurations found in metadata.\e[0m"
    exit 0
fi

# Hand off control to the multi-select TUI menu
pause_logging
export MENU_TITLE="Available Configurations"
source "$(dirname "$0")/tui/menu.sh"
resume_logging

# Log the final selection state once
echo -e "\n\e[1;36mFinal Configuration Selection:\e[0m"
current_idx=-1 
export SUMMARY_TITLE="Configuration"
export SUMMARY_INSTALL_HDR="Configs to Deploy"
export SUMMARY_SKIP_HDR="Configs to Skip"
export SUMMARY_UNINSTALL_HDR="Configs to Remove"
source "$(dirname "$0")/tui/summary.sh"

echo -e "\n\e[1;32mStarting operation...\e[0m"

# Execute removal
for i in "${!uninstall_scripts[@]}"; do
    sel_idx="${uninstall_scripts[$i]}"
    key="${config_keys[$sel_idx]}"
    
    name=$(jq -r ".\"$key\".name" "$METADATA")
    dest=$(jq -r ".\"$key\".dest" "$METADATA")
    type=$(jq -r ".\"$key\".type" "$METADATA")
    
    expanded_sys_path="${dest/#\~/$HOME}"
    echo -e "\n\e[1;31m>>> Removing $name ($expanded_sys_path)...\e[0m"
    if [ "$type" = "dir" ]; then
        rm -rf "$expanded_sys_path"
    else
        rm -f "$expanded_sys_path"
    fi
    echo "  Removed."
done

# Execute deployment
for i in "${!install_scripts[@]}"; do
    sel_idx="${install_scripts[$i]}"
    key="${config_keys[$sel_idx]}"
    
    name=$(jq -r ".\"$key\".name" "$METADATA")
    dest=$(jq -r ".\"$key\".dest" "$METADATA")
    type=$(jq -r ".\"$key\".type" "$METADATA")
    file=$(jq -r ".\"$key\".file" "$METADATA")
    
    is_dir="false"
    [ "$type" = "dir" ] && is_dir="true"
    
    echo -e "\n\e[1;36m>>> Deploying $name...\e[0m"
    copy_with_prompt "./configs/$file" "$dest" "$is_dir"
done

echo -e "\n\e[1;32mConfiguration Process Completed!\e[0m"
