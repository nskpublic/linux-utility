skip_names=("Git" "GitHub Desktop" "Zsh")
joined=$(printf ", %s" "${skip_names[@]}")
echo "  ${joined:2}"
