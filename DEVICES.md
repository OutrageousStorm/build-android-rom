# Supported Devices

This ROM builder focuses on high-quality devices with complete hardware support.

## Tier 1 (Excellent Support)

| Device | Codename | Build Time | Notes |
|--------|----------|-----------|-------|
| Google Pixel 8 Pro | husky | 45 min | Full support, all features work |
| Google Pixel 8 | shiba | 45 min | Excellent support |
| Xiaomi 14 | alioth | 50 min | Full support with MIUI customizations |
| OnePlus 12 | lemon | 48 min | Complete support |

## Tier 2 (Good Support)

| Device | Codename | Build Time | Notes |
|--------|----------|-----------|-------|
| Samsung Galaxy S24 Ultra | lemonade | 55 min | Missing some Samsung-specific features |
| Google Pixel 7 | panther | 48 min | Good support, minor issues |
| Xiaomi 13 Ultra | yuxuan | 52 min | Camera may have quirks |

## Tier 3 (Basic Support)

- OnePlus 11: basic camera, works
- Motorola Edge 40 Pro: no custom kernel support yet

## How to add your device

1. Fork the ROM source repo
2. Create device tree in `device/<vendor>/<codename>/`
3. Copy from a similar device and customize:
   - `BoardConfig.mk` — partitions, kernel, hardware
   - `device.mk` — packages, props
   - Kernel binary (or clone from LineageOS device tree)
4. Test build: `./build.sh <codename>`
5. Submit as PR with device tree

See [android-rom-guide](https://github.com/OutrageousStorm/android-rom-guide) for full device tree walkthrough.
