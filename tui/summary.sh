#!/usr/bin/env bash

echo ""
echo -e "\e[1;33m--- ${SUMMARY_TITLE:-Installation} Summary ---\e[0m\n"

echo -e "\e[1;32m${SUMMARY_INSTALL_HDR:-Packages to Install/Update} (${#install_names[@]}):\e[0m"
if [ ${#install_names[@]} -eq 0 ]; then
    echo "  None"
else
    joined=$(printf ", %s" "${install_names[@]}")
    echo "  ${joined:2}"
fi

echo ""
echo -e "\e[1;37m${SUMMARY_SKIP_HDR:-Packages to be Skipped} (${#skip_names[@]}):\e[0m"
if [ ${#skip_names[@]} -eq 0 ]; then
    echo "  None"
else
    joined=$(printf ", %s" "${skip_names[@]}")
    echo "  ${joined:2}"
fi

echo ""
echo -e "\e[1;31m${SUMMARY_UNINSTALL_HDR:-Packages to be Uninstalled} (${#uninstall_names[@]}):\e[0m"
if [ ${#uninstall_names[@]} -eq 0 ]; then
    echo "  None"
else
    joined=$(printf ", %s" "${uninstall_names[@]}")
    echo "  ${joined:2}"
fi

echo ""
if [[ ${#install_names[@]} -eq 0 && ${#uninstall_names[@]} -eq 0 ]]; then
    echo "No actions selected. Exiting."
    exit 0
fi

read -p "Proceed with these changes? [Y/n]: " confirm
if [[ -n "$confirm" && "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation aborted."
    exit 0
fi
