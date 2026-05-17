#!/bin/bash
# build-rom.sh -- Build Android ROM from source
# Supports: LineageOS, crDroid, GrapheneOS (partial), Evolution X
# Usage: ./build-rom.sh [rom] [device] [variant]
#        ./build-rom.sh lineageos sailfish userdebug
#        ./build-rom.sh crdroid munch eng

set -e
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

ROM="${1:-lineageos}"
DEVICE="${2:-sailfish}"
VARIANT="${3:-userdebug}"
BUILD_DIR="$HOME/android/build-${ROM}"
OUT_DIR="$BUILD_DIR/out/target/product/$DEVICE"

echo -e "\n${BOLD}🔨 Android ROM Builder${NC}"
echo "ROM: $ROM | Device: $DEVICE | Variant: $VARIANT"
echo "Build dir: $BUILD_DIR\n"

# ── Setup ────────────────────────────────────────────────────────────────────
check_deps() {
    missing=""
    for cmd in git curl wget python3; do
        ! command -v $cmd &>/dev/null && missing="$missing $cmd"
    done
    if [[ -n "$missing" ]]; then
        echo -e "${RED}Missing:$missing${NC}"
        echo "Install: sudo apt install git curl wget python3 build-essential"
        exit 1
    fi
}

setup_build_env() {
    echo -e "${YELLOW}Setting up build environment...${NC}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Install Android build tools
    if ! command -v repo &>/dev/null; then
        mkdir -p "$HOME/bin"
        curl https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/repo"
        chmod +x "$HOME/bin/repo"
        [[ ":$PATH:" != *":$HOME/bin:"* ]] && echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/bin:$PATH"
    fi
}

get_rom_manifest() {
    case "$ROM" in
        lineageos)
            echo "https://github.com/LineageOS/android.git"
            ;;
        crdroid)
            echo "https://github.com/crdroidandroid/android.git"
            ;;
        evolution)
            echo "https://github.com/Evolution-X/manifest.git"
            ;;
        *)
            echo "Unknown ROM: $ROM" >&2
            exit 1
            ;;
    esac
}

# ── Sync ─────────────────────────────────────────────────────────────────────
sync_repo() {
    echo -e "${YELLOW}Syncing $ROM repository...${NC}"
    manifest=$(get_rom_manifest)
    
    if [[ ! -d "$BUILD_DIR/.repo" ]]; then
        repo init -u "$manifest" -b main
    fi
    
    repo sync -j$(nproc) --force-sync --no-clone-bundle
    echo -e "${GREEN}✓ Sync complete${NC}"
}

# ── Build ────────────────────────────────────────────────────────────────────
build_rom() {
    echo -e "${YELLOW}Building $ROM for $DEVICE...${NC}"
    cd "$BUILD_DIR"
    
    # Source build env
    . build/envsetup.sh
    
    # Lunch (pick target)
    echo "lunch ${ROM}_${DEVICE}-${VARIANT}"
    lunch "${ROM}_${DEVICE}-${VARIANT}"
    
    # Build
    m -j$(nproc) 2>&1 | tee build.log
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Build successful!${NC}"
        echo "Output: $OUT_DIR"
        ls -lh "$OUT_DIR"/*.zip 2>/dev/null || ls -lh "$OUT_DIR"/*.img
    else
        echo -e "${RED}✗ Build failed. Check build.log${NC}"
        exit 1
    fi
}

# ── Clean ────────────────────────────────────────────────────────────────────
clean_build() {
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    cd "$BUILD_DIR"
    m clean
}

# ── Main ─────────────────────────────────────────────────────────────────────
case "$1" in
    sync)
        check_deps
        setup_build_env
        sync_repo
        ;;
    build)
        build_rom
        ;;
    clean)
        clean_build
        ;;
    full)
        check_deps
        setup_build_env
        sync_repo
        build_rom
        ;;
    *)
        echo "Usage: $0 {sync|build|clean|full} [rom] [device] [variant]"
        echo "Example: $0 full lineageos sailfish userdebug"
        echo ""
        echo "Supported ROMs: lineageos, crdroid, evolution"
        echo "Get device codenames from: https://wiki.lineageos.org/devices/"
        ;;
esac
