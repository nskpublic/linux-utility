#!/usr/bin/env bash
source "$(dirname "$0")/../../utils.sh"

if [ "$1" = "info" ]; then
    echo 'APP_NAME="Walker Launcher"'
    echo 'APP_CHECK="command -v walker >/dev/null 2>&1"'
    exit 0
fi

if [ "$1" = "install" ]; then
    # Install walker and elephant
    echo "Installing Walker and Elephant..."
    # We use both walker and elephant. On Arch these are often AUR packages.
    install_package "$2" walker elephant
    
    # Post-installation steps for elephant
    if command -v elephant &> /dev/null; then
        echo "Configuring Elephant service..."
        elephant service enable
        systemctl --user enable --now elephant.service
    fi
    
    # Persistence for walker daemon
    echo "Setting up Walker daemon persistence..."
    USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
    mkdir -p "$USER_SYSTEMD_DIR"
    
    cat > "$USER_SYSTEMD_DIR/walker.service" <<EOF
[Unit]
Description=Walker Daemon
After=graphical-session.target

[Service]
ExecStart=/usr/bin/walker --gapplication-service
Restart=always

[Install]
WantedBy=graphical-session.target
EOF
    
    systemctl --user daemon-reload
    systemctl --user enable --now walker.service
    
    # Keybind for KDE
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        echo "Configuring KDE keybind (Alt+Space) for Walker..."
        kwriteconfig5 --file kglobalshortcutsrc --group "krunner" --key "_launch" "none,Alt+Space,Search"
        kwriteconfig5 --file kglobalshortcutsrc --group "services" --group "org.kde.krunner.desktop" --key "_launch" "none,Alt+Space,Search"
        kwriteconfig5 --file kglobalshortcutsrc --group "services" --group "net.local.walker.desktop" --key "_launch" "Alt+Space,Alt+Space,Walker"
        qdbus org.kde.kglobalaccel /kglobalaccel org.kde.kglobalaccel.reconfigure
        echo "KDE keybinds updated."
    fi

    # Keybind for GNOME
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        echo "Configuring GNOME keybind (Alt+Space) for Walker..."
        gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
        
        BIND_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/walker/"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BIND_PATH name "Walker"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BIND_PATH command "walker"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BIND_PATH binding "<Alt>space"
        
        current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | tr -d "[]' " | sed 's/^,//;s/,$//')
        if [[ "$current_bindings" != *"$BIND_PATH"* ]]; then
            if [ -z "$current_bindings" ]; then
                new_bindings="['$BIND_PATH']"
            else
                new_bindings="['${current_bindings//,/','}','$BIND_PATH']"
            fi
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"
        fi
    fi

    # Keybind for Niri
    if [[ "$XDG_CURRENT_DESKTOP" == *"niri"* ]] || [ -f "$HOME/.config/niri/config.kdl" ]; then
        NIRI_CONFIG="$HOME/.config/niri/config.kdl"
        if [ -f "$NIRI_CONFIG" ]; then
            if ! grep -q "spawn \"walker\"" "$NIRI_CONFIG"; then
                echo "Configuring Niri keybind (Alt+Space) for Walker..."
                echo -e "\n// Added by linux-utility\nbinds {\n    Alt+Space { spawn \"walker\"; }\n}" >> "$NIRI_CONFIG"
            fi
        fi
    fi
    
elif [ "$1" = "uninstall" ]; then
    echo "Removing Walker and Elephant..."
    systemctl --user disable --now walker.service
    systemctl --user disable --now elephant.service
    rm -f "$HOME/.config/systemd/user/walker.service"
    remove_package "$2" walker elephant
fi
