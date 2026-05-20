#!/bin/bash
# build_parallel.sh — Build Android ROM in parallel with logging
# Inspired by: parallel processing optimization (HN #5)
set -e

ROM_DIR=${1:-.}
JOBS=${2:-$(nproc)}
LOG_DIR="build_logs"

mkdir -p "$LOG_DIR"

echo "🔨 Building $ROM_DIR with $JOBS parallel jobs"
echo "📝 Logs: $LOG_DIR/"

cd "$ROM_DIR"
source build/envsetup.sh
lunch lineage_device-userdebug

# Parallel build with per-job logging
m -j$JOBS 2>&1 | tee "$LOG_DIR/build_$(date +%s).log"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    echo "✅ Build successful"
    ls -lh out/target/product/*/lineage-*.zip
else
    echo "❌ Build failed"
    tail -50 "$LOG_DIR"/*.log
    exit 1
fi
