#!/bin/bash
# lunch_helper.sh -- Interactive ROM lunch selector
# Usage: source lunch_helper.sh  (from AOSP build root)

if [[ -z "$ANDROID_BUILD_TOP" ]]; then
    echo "Error: Not in AOSP build directory"
    return 1
fi

# List available devices
echo "Available lunch combos:"
lunch_out=$(lunch 2>&1 | grep -E "^[0-9]+\." | head -20)
echo "$lunch_out"

echo ""
read -p "Select lunch combo (number or name): " choice

# If number, convert to name
if [[ "$choice" =~ ^[0-9]+$ ]]; then
    target=$(echo "$lunch_out" | sed -n "$((choice+1))p" | awk '{print $2}')
else
    target="$choice"
fi

if [[ -n "$target" ]]; then
    echo "Selected: $target"
    lunch "$target"
else
    echo "Invalid choice"
    return 1
fi
