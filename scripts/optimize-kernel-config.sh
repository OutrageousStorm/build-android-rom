#!/bin/bash
# optimize-kernel-config.sh -- Optimize Android kernel config for size/speed/battery
# Usage: ./optimize-kernel-config.sh <kernel-config-file>
# Removes debug symbols, unnecessary drivers, enables performance tweaks

CONFIG="${1:?Usage: $0 <kernel-config>}"
[[ ! -f "$CONFIG" ]] && echo "❌ File not found: $CONFIG" && exit 1

echo "🔧 Kernel Config Optimizer"
echo "=" * 40

# Backup
cp "$CONFIG" "$CONFIG.backup"
echo "✓ Backed up to $CONFIG.backup"

# Disable debugging (save ~20MB)
sed -i 's/CONFIG_DEBUG_INFO=y/CONFIG_DEBUG_INFO=n/g' "$CONFIG"
sed -i 's/CONFIG_DEBUG_KERNEL=y/CONFIG_DEBUG_KERNEL=n/g' "$CONFIG"

# Enable performance modes
sed -i 's/CONFIG_CPU_FREQ_POWERSAVE=y/CONFIG_CPU_FREQ_POWERSAVE=n/g' "$CONFIG"
sed -i 's/CONFIG_CPU_FREQ_CONSERVATIVE=y/CONFIG_CPU_FREQ_CONSERVATIVE=n/g' "$CONFIG"
sed -i 's/# CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE/CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y/g' "$CONFIG"

# Disable unnecessary modules
sed -i 's/CONFIG_MODULES=y/CONFIG_MODULES=n/g' "$CONFIG"
sed -i 's/CONFIG_NF_CONNTRACK=m/CONFIG_NF_CONNTRACK=n/g' "$CONFIG"

# Optimize memory
sed -i 's/CONFIG_HIGHMEM=y/CONFIG_HIGHMEM=n/g' "$CONFIG"
sed -i 's/CONFIG_MEMORY_HOTPLUG=y/CONFIG_MEMORY_HOTPLUG=n/g' "$CONFIG"

# Disable unused filesystems
for fs in ext2 jfs xfs btrfs; do
  sed -i "s/CONFIG_${fs^^}_FS=y/CONFIG_${fs^^}_FS=n/g" "$CONFIG"
done

# Enable core performance features
for opt in SMP PREEMPT HAVE_EFFICIENT_UNALIGNED_ACCESS; do
  sed -i "s/# CONFIG_$opt/CONFIG_$opt=y/g" "$CONFIG"
done

echo "✓ Debug symbols disabled"
echo "✓ Performance governors enabled"
echo "✓ Unused modules removed"
echo "✓ Memory optimizations applied"

# Count changes
REMOVED=$(diff "$CONFIG.backup" "$CONFIG" | grep "^<" | wc -l)
echo "\n✅ Applied $REMOVED optimizations"
echo "Next: make clean && make zImage"
