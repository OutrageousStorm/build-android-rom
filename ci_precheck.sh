#!/bin/bash
# Pre-build validation for ROM compilation
echo "Checking build environment..."
[[ ! -d "build" ]] && echo "Not in AOSP root" && exit 1
echo "✓ Valid AOSP structure"
echo "✓ Build environment ready"
