#!/bin/bash
# build.sh -- Build LineageOS ROM from source
# Usage: ./build.sh --device marlin --jobs 4
set -e
DEVICE="${DEVICE:-marlin}"
JOBS="${JOBS:-$(nproc)}"

source build/envsetup.sh
lunch lineage_${DEVICE}-user
brunch ${DEVICE}
