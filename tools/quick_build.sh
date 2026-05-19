#!/bin/bash
# quick_build.sh -- Fast incremental ROM build after lunch
# Usage: ./quick_build.sh system-image  # or: boot, recovery, etc

TARGET="${1:-system-image}"
JOBS=$(nproc)

echo "🔨 Building $TARGET with $JOBS jobs..."
cd ~/android/source

time make -j$JOBS $TARGET 2>&1 | tail -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Build successful"
    echo "Output: out/target/product/*/$(basename $TARGET)"
else
    echo "❌ Build failed"
    exit 1
fi
