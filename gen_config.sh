#!/bin/bash
# gen_config.sh -- Generate optimized Android build config
# Usage: ./gen_config.sh <device_codename> <version>

DEVICE="$1"; VERSION="${2:-14}"
[[ -z "$DEVICE" ]] && echo "Usage: $0 <device> [android_version]" && exit 1

CONFIG_DIR="$DEVICE/config"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/BoardConfig.mk" << 'EOF'
# Auto-generated board config for $DEVICE

# Device
TARGET_DEVICE := $DEVICE
TARGET_BOOTLOADER_BOARD_NAME := $DEVICE

# CPU
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a-generic
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic

# Partitions
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
BOARD_USERDATAIMAGE_PARTITION_SIZE := 6442450944

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
BOARD_HAS_LARGE_FILESYSTEM := true

# Kernel
TARGET_KERNEL_SOURCE := kernel/linux-generic
KERNEL_DEFCONFIG := generic_defconfig
EOF

echo "✓ Generated $CONFIG_DIR/BoardConfig.mk"
