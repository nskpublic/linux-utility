echo -n "Press space: "
IFS= read -rsn1 key
if [[ "$key" == " " ]]; then
    echo "SPACE matched!"
else
    echo "SPACE NOT matched. key is '$key'"
fi
