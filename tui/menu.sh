#!/usr/bin/env bash

# Switched to alternate screen rendering
# Initialize selected array 
selected_flags=()
for i in "${!app_names[@]}"; do
    if ${app_installed_status[$i]}; then
        selected_flags[$i]=0 # Skip by default if already installed
    else
        selected_flags[$i]=1 # Install by default if not installed
    fi
done

current_idx=0

# Trap to restore cursor on exit/interrupt
trap "tput rmcup; tput cnorm; echo; exit 1" SIGINT SIGTERM
tput smcup # Switch to alternate screen
tput civis # Hide cursor

draw_menu() {
    echo -e "\e[1;36m${MENU_TITLE:-Available Applications}:\e[0m\n"
    local last_cat=""
    for i in "${!app_names[@]}"; do
        if [[ -n "${app_categories[$i]}" && "${app_categories[$i]}" != "$last_cat" ]]; then
            echo -e "\n  \e[1;35m--- ${app_categories[$i]} ---\e[0m"
            last_cat="${app_categories[$i]}"
        fi
        local state=${selected_flags[$i]}
        local display_name="${app_names[$i]}"
        if ${app_installed_status[$i]}; then
            display_name="\e[1;33m*\e[0m $display_name"
        fi
        
        if [[ $i -eq $current_idx ]]; then
            # Highlight selected row
            if [[ $state -eq -1 ]]; then
                echo -e " \e[1;32m>\e[0m \e[7m[\e[1;31m✗\e[0m\e[7m] $display_name (Uninstall)\e[27m\e[0m"
            elif [[ $state -eq 1 ]] && ${app_installed_status[$i]}; then
                echo -e " \e[1;32m>\e[0m \e[7m[✓] $display_name (Update)\e[27m"
            elif [[ $state -eq 1 ]]; then
                echo -e " \e[1;32m>\e[0m \e[7m[✓] $display_name\e[27m"
            else
                echo -e " \e[1;32m>\e[0m \e[7m[ ] $display_name\e[27m"
            fi
        else
            # Unselected row
            if [[ $state -eq -1 ]]; then
                echo -e "   [\e[1;31m✗\e[0m] $display_name \e[1;31m(Uninstall)\e[0m"
            elif [[ $state -eq 1 ]] && ${app_installed_status[$i]}; then
                echo -e "   [\e[1;32m✓\e[0m] $display_name \e[1;32m(Update)\e[0m"
            elif [[ $state -eq 1 ]]; then
                echo -e "   [\e[1;32m✓\e[0m] $display_name"
            else
                echo -e "   [ ] $display_name"
            fi
        fi
    done
    echo -e "\n  (\e[1;33m*\e[0m indicates already installed)"
    echo -e "  \e[1mUP/DOWN\e[0m Navigate | \e[1mSPACE\e[0m Toggle \e[1;32m[✓]\e[0m \e[1;37m[ ]\e[0m \e[1;31m[✗]\e[0m"
    echo -e "  \e[1my\e[0m (install), \e[1mn\e[0m (skip), \e[1md\e[0m (uninstall) | \e[1mENTER\e[0m Confirm"
}

render_menu() {
    tput clear
    local menu_content
    menu_content=$(draw_menu)
    echo -en "$menu_content"
}

# Initial draw
render_menu

while true; do
    IFS= read -rsn1 key
    if [[ $key == $'\e' ]]; then
        IFS= read -rsn2 key
        if [[ $key == '[A' ]]; then # Up
            ((current_idx--))
            if [[ $current_idx -lt 0 ]]; then current_idx=$(( ${#app_names[@]} - 1 )); fi
        elif [[ $key == '[B' ]]; then # Down
            ((current_idx++))
            if [[ $current_idx -ge ${#app_names[@]} ]]; then current_idx=0; fi
        fi
    elif [[ "$key" == " " ]]; then
        st=${selected_flags[$current_idx]}
        is_safe="true"
        if [[ "${app_scripts[$current_idx]}" == "fonts" || "${app_scripts[$current_idx]}" == "kde_themes" ]]; then
            is_safe="false"
        fi

        if [[ "$st" -eq 1 ]]; then
            selected_flags[$current_idx]=0
        elif [[ "$st" -eq 0 ]]; then
            if [[ "$is_safe" == "true" ]]; then
                selected_flags[$current_idx]=-1
            else
                selected_flags[$current_idx]=1
            fi
        else
            selected_flags[$current_idx]=1
        fi
    elif [[ $key == 'y' || $key == 'Y' || $key == 'i' || $key == 'I' ]]; then
        selected_flags[$current_idx]=1
    elif [[ $key == 'n' || $key == 'N' || $key == 's' || $key == 'S' ]]; then
        selected_flags[$current_idx]=0
    elif [[ $key == 'd' || $key == 'D' || $key == 'u' || $key == 'U' ]]; then
        if [[ "${app_scripts[$current_idx]}" != "fonts" && "${app_scripts[$current_idx]}" != "kde_themes" ]]; then
            selected_flags[$current_idx]=-1
        fi
    elif [[ $key == "" ]]; then # Enter
        break
    fi


    render_menu
done

# Restore screen and cursor, and clean trap
tput rmcup
tput cnorm
trap - SIGINT SIGTERM
echo "Menu selection completed."

install_scripts=()
install_names=()
skip_names=()
uninstall_scripts=()
uninstall_names=()

for i in "${!app_names[@]}"; do
    if [[ ${selected_flags[$i]} -eq 1 ]]; then
        install_scripts+=("${app_scripts[$i]}")
        install_names+=("${app_names[$i]}")
    elif [[ ${selected_flags[$i]} -eq -1 ]]; then
        uninstall_scripts+=("${app_scripts[$i]}")
        uninstall_names+=("${app_names[$i]}")
    else
        skip_names+=("${app_names[$i]}")
    fi
done
