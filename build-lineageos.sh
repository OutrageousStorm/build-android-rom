#!/bin/bash
# build-lineageos.sh -- Full LineageOS build automation
# Usage: ./build-lineageos.sh <device_codename> [android_version]
set -e
BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

DEVICE="${1:?Usage: $0 <device_codename> [version]}"
VERSION="${2:-lineage-21}"
JOBS=$(nproc)
BUILD_DIR="$HOME/lineageos-build"

echo -e "\n${BOLD}🔨 LineageOS Build for $DEVICE${NC}"
echo "Version: $VERSION | Jobs: $JOBS"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [[ ! -d ".repo" ]]; then
    echo "Initializing repo..."
    repo init -u https://github.com/LineageOS/android.git -b "$VERSION" --git-lfs || exit 1
fi

echo "Syncing source..."
repo sync --force-sync -j"$JOBS" -q

source build/envsetup.sh
echo "Building for $DEVICE..."
export CCACHE_EXEC="/usr/bin/ccache"
export USE_CCACHE=1

lunch lineage_"$DEVICE"-userdebug || { echo "Invalid device: $DEVICE"; exit 1; }
mka bacon -j"$JOBS"

if [[ -f "out/target/product/$DEVICE/lineage-$VERSION-$DEVICE-signed.zip" ]]; then
    echo "✅ Build successful!"
    echo "Output: $(pwd)/out/target/product/$DEVICE/"
else
    echo "❌ Build failed"
    exit 1
fi
