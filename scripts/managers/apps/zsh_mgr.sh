#!/usr/bin/env bash
ACTION=$1
OS_FAMILY=$2

source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Zsh"'
    echo 'APP_CHECK="command -v zsh >/dev/null 2>&1"'
    exit 0
fi


if [ "$ACTION" = "uninstall" ]; then
    echo "Uninstalling Zsh plugins..."
    rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    rm -rf "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    rm -rf "$HOME/.zsh/zsh-autosuggestions"
    rm -rf "$HOME/.zsh/zsh-syntax-highlighting"
    
    # Optional: Uninstall Zsh base package
    remove_package "$OS_FAMILY" zsh
    exit 0
fi

# 1. Install base Zsh
install_package "$OS_FAMILY" zsh git curl || exit 1

echo ""
read -p "Do you want to install oh-my-zsh (optional)? [Y/n]: " install_omz
if [[ -z "$install_omz" || "$install_omz" == "y" || "$install_omz" == "Y" ]]; then
    echo "Installing oh-my-zsh..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    echo "Installing zsh-autosuggestions for Oh-My-Zsh..."
    if [ ! -d "$OMZ_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
    fi
    
    echo "Installing zsh-syntax-highlighting for Oh-My-Zsh..."
    if [ ! -d "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    # Update ~/.zshrc plugins array. Matches the default `plugins=(git)` and updates it.
    # zsh-syntax-highlighting MUST be the active last plugin in the list.
    if grep -q "plugins=(git)" "$HOME/.zshrc"; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$HOME/.zshrc"
        echo "Added plugins to ~/.zshrc"
    else
        echo "Could not auto-inject into ~/.zshrc. Please manually add 'zsh-autosuggestions zsh-syntax-highlighting' to your plugins=() array."
    fi
else
    echo "Installing zsh plugins manually (Git Clone without OMZ)..."
    
    ZSH_PLUGINS_DIR="$HOME/.zsh"
    mkdir -p "$ZSH_PLUGINS_DIR"
    
    echo "Cloning zsh-autosuggestions..."
    if [ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
    fi
    
    echo "Cloning zsh-syntax-highlighting..."
    if [ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
    fi
    
    # Append the source commands safely avoiding duplicates
    if ! grep -q "zsh-autosuggestions.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo "source $ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$HOME/.zshrc"
    fi
    
    if ! grep -q "zsh-syntax-highlighting.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo "source $ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$HOME/.zshrc"
    fi
    echo "Source appended to ~/.zshrc"
fi
