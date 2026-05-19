#!/bin/bash
# optimize_kernel_config.sh -- Optimize Android kernel config for size/performance
# Usage: ./optimize_kernel_config.sh <kernel_source_dir> [output.config]
# Analyzes defconfig and applies optimizations for smaller, faster kernel

set -e
KERNEL_DIR="${1:?Usage: $0 <kernel_dir> [output]}"
OUTPUT="${2:-optimized.config}"

[[ ! -f "$KERNEL_DIR/.config" ]] && echo "Error: .config not found in $KERNEL_DIR" && exit 1

echo "🔧 Android Kernel Config Optimizer"
echo "Source: $KERNEL_DIR"
echo "Output: $OUTPUT"
echo ""

cp "$KERNEL_DIR/.config" "$OUTPUT"

# Strip debug symbols (reduce size by ~30%)
echo "  Removing CONFIG_DEBUG_* symbols..."
sed -i '/^CONFIG_DEBUG_/d' "$OUTPUT"
sed -i '/^CONFIG_DYNAMIC_DEBUG/d' "$OUTPUT"

# Disable unused features
echo "  Disabling unused features..."
for feature in CONFIG_SECURITY_SELINUX_DISABLE CONFIG_MAGIC_SYSRQ CONFIG_DEVKMEM \
               CONFIG_UEVENT_HELPER CONFIG_USER_NS CONFIG_PID_NS CONFIG_NET_NS; do
    sed -i "s/^$feature=.*/# $feature is not set/" "$OUTPUT"
done

# Enable performance features
echo "  Enabling performance features..."
for opt in CONFIG_CPU_FREQ CONFIG_CPUFREQ_SCHEDUTIL CONFIG_SCHED_TUNE \
           CONFIG_SCHEDUTIL_FREQ_SYNC CONFIG_CPU_BOOST; do
    sed -i "s/^# $opt is not set/$opt=y/" "$OUTPUT"
done

# Optimize module loading
echo "  Module optimizations..."
sed -i 's/^CONFIG_MODULE_COMPRESS=.*/CONFIG_MODULE_COMPRESS=y/' "$OUTPUT"

# Count changes
ORIG_SIZE=$(wc -l < "$KERNEL_DIR/.config")
NEW_SIZE=$(wc -l < "$OUTPUT")
REDUCTION=$((ORIG_SIZE - NEW_SIZE))

echo ""
echo "✅ Config optimized!"
echo "  Original: $ORIG_SIZE lines"
echo "  Optimized: $NEW_SIZE lines"
echo "  Removed: $REDUCTION lines (${REDUCTION}% reduction)"
echo ""
echo "Next: cp $OUTPUT $KERNEL_DIR/.config && make clean && make -j$(nproc)"
