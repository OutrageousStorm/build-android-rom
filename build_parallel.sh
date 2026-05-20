#!/bin/bash
# build_parallel.sh — Parallel Android ROM build with progress monitoring
set -e

THREADS=${1:-8}
DEVICE=${2:-oriole}

echo "🔨 Starting parallel ROM build for $DEVICE (using $THREADS threads)"
echo "Start time: $(date)"

# Set up environment
. build/envsetup.sh
lunch ${DEVICE}-user

# Build with parallel jobs
echo "Building lunch target..."
time m -j${THREADS} 2>&1 | tee build_${DEVICE}_$(date +%s).log

echo "\n✅ Build complete: $(date)"
echo "Output: out/target/product/$DEVICE/system.img"

# Verify outputs exist
if [[ -f "out/target/product/$DEVICE/system.img" ]]; then
  SIZE=$(du -h "out/target/product/$DEVICE/system.img" | cut -f1)
  echo "System image size: $SIZE"
  echo "Ready to flash via: adb reboot bootloader && fastboot flashall"
else
  echo "⚠️  system.img not found!"
  exit 1
fi
