#!/usr/bin/env bash

# Usage: install_package <os_family> <package_name1> [package_name2 ...]
install_package() {
    local family=$1
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    case "$family" in
        "arch" )
            ${AUR_HELPER:-sudo pacman} -S --noconfirm "${packages[@]}"
            ;;
        "debian" )
            sudo apt-get install -y "${packages[@]}"
            ;;
        "fedora" )
            sudo dnf install -y "${packages[@]}"
            ;;
        * )
            echo "Cannot automatically install [ ${packages[*]} ]. Unsupported OS family: $family"
            return 1
            ;;
    esac
}

# Usage: remove_package <os_family> <package_name1> [package_name2 ...]
remove_package() {
    local family=$1
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    case "$family" in
        "arch" )
            ${AUR_HELPER:-sudo pacman} -Rns --noconfirm "${packages[@]}"
            ;;
        "debian" )
            sudo apt-get autoremove --purge -y "${packages[@]}"
            ;;
        "fedora" )
            sudo dnf autoremove -y "${packages[@]}"
            ;;
        * )
            echo "Cannot automatically remove [ ${packages[*]} ]. Unsupported OS family: $family"
            return 1
            ;;
    esac
}

# Usage: manage_package <action> <os_family> <package_name1> [package_name2 ...]
manage_package() {
    local action=$1
    local family=$2
    shift 2

    if [ "$action" = "uninstall" ]; then
        remove_package "$family" "$@"
    else
        install_package "$family" "$@"
    fi
}
