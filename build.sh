#!/bin/bash
# build.sh -- Build Android ROM locally
# Usage: ./build.sh [target_device] [build_type]
set -e

DEVICE="${1:-lemonade}"
TYPE="${2:-user}"
REPO_URL="${3:-https://github.com/LineageOS/android.git}"
BRANCH="${4:-lineage-21.0}"

echo "🔨 Android ROM Builder"
echo "Device: $DEVICE | Type: $TYPE"
echo "==========================================="

# Setup
BUILD_DIR="${HOME}/rom-${DEVICE}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [[ ! -d ".repo" ]]; then
    echo "🔄 Initializing repo..."
    mkdir -p ~/bin
    [[ ! -f ~/bin/repo ]] && curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo && chmod +x ~/bin/repo
    ~/bin/repo init -u "$REPO_URL" -b "$BRANCH"
fi

echo "📥 Syncing source (this may take 30+ minutes)..."
~/bin/repo sync --force-sync -j4

echo "🛠️  Building ROM for $DEVICE..."
source build/envsetup.sh
lunch "lineage_${DEVICE}-${TYPE}"
make -j$(nproc) bacon

if [[ -f "out/target/product/${DEVICE}/lineage-"*.zip ]]; then
    echo ""
    echo "✅ Build complete!"
    ls -lh "out/target/product/${DEVICE}/lineage-"*.zip
    echo ""
    echo "📱 Flash with: fastboot update out/target/product/${DEVICE}/lineage-*.zip"
else
    echo "❌ Build failed"
    exit 1
fi
