#!/bin/bash
# build_parallel.sh - Parallel Android ROM build with logging
set -e
CORES=$(nproc)
ROM_DIR=${1:-.}
LOG_DIR="$ROM_DIR/build_logs"
mkdir -p "$LOG_DIR"
echo "🔨 Building ROM with $CORES parallel jobs..."
cd "$ROM_DIR"
source build/envsetup.sh
lunch lineage_$(getprop ro.product.device)-user 2>&1 | tee "$LOG_DIR/lunch.log"
make -j$CORES 2>&1 | tee "$LOG_DIR/build.log"
echo "✅ Build complete. Logs in $LOG_DIR"
