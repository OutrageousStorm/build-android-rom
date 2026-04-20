#!/bin/bash
# build.sh -- Build Android ROM with Docker
# Usage: ./build.sh --device taimen --rom lineageos --version 21.0

set -e
DEVICE="taimen"
ROM="lineageos"
VERSION="21.0"

while [[ $# -gt 0 ]]; do
  case $1 in
    --device) DEVICE="$2"; shift 2;;
    --rom) ROM="$2"; shift 2;;
    --version) VERSION="$2"; shift 2;;
    *) echo "Unknown: $1"; exit 1;;
  esac
done

echo "🔨 Building $ROM $VERSION for $DEVICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Docker
[[ ! $(command -v docker) ]] && echo "Install Docker: https://docker.io" && exit 1

# Create build volume
docker volume create android-build 2>/dev/null || true

# Dockerfile (inline)
DOCKERFILE=$(cat <<'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    git curl wget zip unzip bzip2 \
    openjdk-11-jdk python3 \
    bc bison build-essential \
    flex g++ gperf imagemagick \
    lib32ncurses5-dev lib32readline-dev lib32z1-dev \
    libgl1-mesa-dev libmagick++-dev libncurses5-dev \
    libreadline-dev libx11-dev libxml2-utils lz4 \
    squashfs-tools xsltproc zip zlib1g-dev
RUN groupadd -r builder && useradd -r -g builder builder
WORKDIR /build
RUN chown -R builder:builder /build
USER builder
ENV USE_CCACHE=1 CCACHE_DIR=/build/.ccache
RUN git config --global user.email "build@docker" && git config --global user.name "Docker Builder"
EOF
)

echo "$DOCKERFILE" > /tmp/Dockerfile.rom

docker build -f /tmp/Dockerfile.rom -t android-builder .

# Run build
docker run --rm -it \
  -v android-build:/build \
  android-builder bash -c "
    echo '📥 Syncing sources...'
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0
    repo sync -j8 --depth=1
    echo '🔨 Building...'
    source build/envsetup.sh
    lunch lineage_${DEVICE}-userdebug
    make -j\$(nproc) bacon
  "

echo "✅ Build complete!"
echo "Output: /var/lib/docker/volumes/android-build/_data/out/target/product/$DEVICE"
