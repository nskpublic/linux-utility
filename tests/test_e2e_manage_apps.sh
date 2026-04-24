#!/usr/bin/env bash

# End-to-End Test Wrapper for manage_apps.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MOCK_BIN="$SCRIPT_DIR/mock_bin"
LOG_FILE="$SCRIPT_DIR/mock_log.txt"

# Cleanup runs on EXIT (success or failure) — like a finally block
cleanup() {
    echo ""
    echo "Cleaning up Mocks..."
    rm -rf "$MOCK_BIN"
    rm -f "$LOG_FILE"
    echo "Clean up of mocks complete"
}
trap cleanup EXIT

# Cleanup from previous runs
rm -rf "$MOCK_BIN"
rm -f "$LOG_FILE"
mkdir -p "$MOCK_BIN"
touch "$LOG_FILE"

echo "========================================="
echo " Setting up End-to-End Mock Environment"
echo "========================================="

# Commands to mock
MOCKS=(
    sudo apt-get pacman dnf snap rpm git chsh curl wget makepkg paru yay fc-list kvantummanager
)

for cmd in "${MOCKS[@]}"; do
    cat <<EOF > "$MOCK_BIN/$cmd"
#!/usr/bin/env bash
echo "[MOCK $cmd] \$@" >> "$LOG_FILE"
# specifically for fc-list check, we return success so it thinks fonts exist initially
if [ "\$cmd" = "fc-list" ]; then echo "JetBrains"; echo "Poppins"; exit 0; fi
if [ "\$cmd" = "kvantummanager" ]; then exit 0; fi
exit 0
EOF
    chmod +x "$MOCK_BIN/$cmd"
done

export PATH="$MOCK_BIN:$PATH"
cd "$REPO_ROOT"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_LIKE=${ID_LIKE:-$ID}
fi

run_test() {
    local test_name="$1"
    local input_str="$2"
    local expected_mock_str="$3"
    local prohibited_mock_str="$4"
    
    echo ""
    echo "--------------------------------------------------------"
    echo " RUNNING TEST: $test_name"
    echo "--------------------------------------------------------"
    # We remove > /dev/null so the user sees the execution logs of the script doing its job.
    printf "$input_str" | ./manage_apps.sh
    
    echo -e "\n--- Verifying Mocks Log for $test_name ---"
    
    if [ -n "$prohibited_mock_str" ]; then
        for prohib in $prohibited_mock_str; do
            if grep -q -e "$prohib" "$LOG_FILE"; then
                echo -e "\e[1;31mFAILED:\e[0m Test caught a BUG! Captured PROHIBITED mock command ($prohib)!"
                echo "Actual capture:"
                cat "$LOG_FILE"
                exit 1
            fi
        done
    fi
    
    if [ -n "$expected_mock_str" ]; then
        for exp in $expected_mock_str; do
            if ! grep -q "$exp" "$LOG_FILE"; then
                echo -e "\e[1;31mFAILED:\e[0m Did not capture expected mock command ($exp)!"
                echo "Actual capture:"
                cat "$LOG_FILE"
                exit 1
            fi
        done
        echo -e "\e[1;32mSUCCESS:\e[0m Mocks correctly captured execution:"
        cat "$LOG_FILE"
    else
        # If expected is empty, we expect NO installation commands to be run outside of safe checks (like fc-list)
        if grep -q "sudo" "$LOG_FILE"; then
            echo -e "\e[1;31mFAILED:\e[0m Expected NO execution, but something ran!"
            cat "$LOG_FILE"
            exit 1
        else
            echo -e "\e[1;32mSUCCESS:\e[0m Operation successfully aborted/skipped. No harmful execution captured."
        fi
    fi
    
    # clear log for next test
    > "$LOG_FILE"
}

# Payload variables depends on OS
AUR_PREFIX=""
if [[ "$DISTRO_LIKE" == *"arch"* || "$DISTRO" == "arch" ]]; then
    AUR_PREFIX="\n"  # Skip the AUR selection
fi

# 1. TEST INSTALL/UPDATE: Send 'Y', then confirm summary with 'Y\n'
run_test "Install / Update Logic (Confirming with 'Y')" "${AUR_PREFIX}Y\nY\n" "git"

# 2. TEST UNINSTALL: Send 'd', then confirm summary with 'y\n'
run_test "Uninstall Logic (Sending 'd', confirming with 'y')" "${AUR_PREFIX}d\ny\n" "git"

# 3. TEST ABORT/CANCELLATION: Send 'Y', then abort summary with 'N\n'
run_test "Summary Abort (Sending 'Y' for app, but 'N' to final confirmation)" "${AUR_PREFIX}Y\nN\n" ""

# 4. TEST COMBO (Install + Update + Delete in 1 Run):
# Uses \033[B (Down Arrow) to select first 3 items: Git(y), GitHub Desktop(y), and VS Code(d).
run_test "Combo: Install + Update + Uninstall in ONE run" "${AUR_PREFIX}y\033[By\033[Bd\ny\n" "git sudo"

# 5. TEST SAFEGUARDS (Cannot Uninstall Fonts & KDE Themes)
# Force KDE variable so Themes feature appears on all OS environments
export XDG_CURRENT_DESKTOP="KDE"
# Uses \033[A (Up Arrow) to loop to the bottom of the list where KDE Themes and Fonts sit.
# Tries to press 'd' on KDE Themes -> moves up -> presses 'd' on Fonts.
# Because these are protected in menu.sh, the 'd' is ignored.
# By default, because they exist, their state might be 'Update' (1), meaning they'll trigger a safe re-installation instead of deletion.
# We verify 'sudo' is successfully captured representing the install path, proving 'd' (uninstall) was successfully stripped!
# AND CRITICALLY: We pass "-Rs remove purge" as prohibited strings, so if a bug DOES allow uninstallation, the test aggressively FAILS.
run_test "Safeguards: Prevent Uninstallation of Fonts and Themes" "${AUR_PREFIX}\033[Ad\033[Ad\ny\n" "sudo" "-Rs remove purge"

echo "========================================="
echo " ALL E2E TESTS COVERED & PASSED PERFECTLY!"
echo "========================================="
