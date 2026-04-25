#!/bin/bash
# test_fix_backlight.sh

echo "Setting up tests for fix_backlight.sh..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../fix_backlight.sh"

# We create a temporary dummy grub file
TEMP_GRUB=$(mktemp)

# Mocked update cmd
MOCK_UPDATE="echo Mocking grub update..."

# Test 1: File without parameter -> should append
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"" > "$TEMP_GRUB"

GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=1 bash "$TARGET_SCRIPT" >/dev/null

if grep -q "quiet splash i915.enable_dpcd_backlight=1" "$TEMP_GRUB"; then
  echo "Test 1 Passed: Parameter appended successfully."
else
  echo "Test 1 Failed: Parameter not appended."
  cat "$TEMP_GRUB"
  exit 1
fi

# Test 2: File with parameter=0 -> should replace with =1
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet i915.enable_dpcd_backlight=0 splash\"" > "$TEMP_GRUB"

GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=1 bash "$TARGET_SCRIPT" >/dev/null

if grep -q "quiet i915.enable_dpcd_backlight=1 splash" "$TEMP_GRUB"; then
  echo "Test 2 Passed: Parameter correctly replaced."
else
  echo "Test 2 Failed: Parameter not replaced."
  cat "$TEMP_GRUB"
  exit 1
fi

# Test 3: File with parameter=1 -> should do nothing (early exit)
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash i915.enable_dpcd_backlight=1\"" > "$TEMP_GRUB"

OUTPUT=$(GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=1 bash "$TARGET_SCRIPT")

if echo "$OUTPUT" | grep -q "already correctly applied"; then
  echo "Test 3 Passed: Script recognized parameter is already applied."
else
  echo "Test 3 Failed: Script did not exit early."
  echo "$OUTPUT"
  exit 1
fi

# Test 4: Confirmation 'n' -> should cancel
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"" > "$TEMP_GRUB"
OUTPUT=$(echo "n" | GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=0 bash "$TARGET_SCRIPT")
if echo "$OUTPUT" | grep -q "Operation cancelled"; then
  echo "Test 4 Passed: Confirmation 'n' correctly cancelled operation."
else
  echo "Test 4 Failed: Script did not cancel."
  echo "$OUTPUT"
  exit 1
fi

# Test 5: Confirmation 'N' -> should cancel
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"" > "$TEMP_GRUB"
OUTPUT=$(echo "N" | GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=0 bash "$TARGET_SCRIPT")
if echo "$OUTPUT" | grep -q "Operation cancelled"; then
  echo "Test 5 Passed: Confirmation 'N' correctly cancelled operation."
else
  echo "Test 5 Failed: Script did not cancel."
  echo "$OUTPUT"
  exit 1
fi

# Test 6: Confirmation 'y' -> should apply
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"" > "$TEMP_GRUB"
OUTPUT=$(echo "y" | GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=0 bash "$TARGET_SCRIPT")
if echo "$OUTPUT" | grep -q "successfully"; then
  echo "Test 6 Passed: Confirmation 'y' correctly applied operation."
else
  echo "Test 6 Failed: Script did not apply fix."
  echo "$OUTPUT"
  exit 1
fi

# Test 7: Confirmation 'Y' -> should apply
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"" > "$TEMP_GRUB"
OUTPUT=$(echo "Y" | GRUB_FILE="$TEMP_GRUB" GRUB_UPDATE_CMD="$MOCK_UPDATE" SKIP_ROOT_CHECK=1 AUTO_CONFIRM=0 bash "$TARGET_SCRIPT")
if echo "$OUTPUT" | grep -q "successfully"; then
  echo "Test 7 Passed: Confirmation 'Y' correctly applied operation."
else
  echo "Test 7 Failed: Script did not apply fix."
  echo "$OUTPUT"
  exit 1
fi

rm -f "$TEMP_GRUB"
echo "All tests passed successfully!"
