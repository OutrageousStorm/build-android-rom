# 🔨 Build Android ROM

Automated scripts to compile LineageOS or AOSP with Docker. Works on any system.

## Quick start

```bash
./build.sh --device taimen --rom lineageos --version 21.0

# Output: out/target/product/taimen/lineage-21.0-*.zip
```

## Features

- Docker-based (no local Java/Gradle setup needed)
- Parallel compilation (`-j$(nproc)`)
- Automatic repo sync + shallow clone for speed
- Output signing with test keys
- Resume capability (restarts from last successful step)

## Supported ROMs

- LineageOS (18.1+)
- Pixel Experience
- crDroid
