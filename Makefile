# build-android-rom Makefile
.PHONY: help init sync build clean flash check-deps

ANDROID_TOP ?= $(PWD)
JOBS ?= $(shell nproc)

help:
	@echo "Android ROM Build Helper"
	@echo "  make init          - Initialize repo with Google's repo tool"
	@echo "  make sync          - Sync all sources (--force-sync)"
	@echo "  make build         - Build ROM (lunch first)"
	@echo "  make clean         - Clean build output"
	@echo "  make flash         - Flash to connected device (requires built image)"
	@echo "  make check-deps    - Verify all build dependencies"

check-deps:
	@command -v repo >/dev/null 2>&1 || { echo "repo tool not found"; exit 1; }
	@command -v adb >/dev/null 2>&1 || { echo "adb not found"; exit 1; }
	@echo "✓ Dependencies OK"

init:
	mkdir -p $(ANDROID_TOP)
	cd $(ANDROID_TOP) && repo init -u https://github.com/LineageOS/android.git -b lineage-21.0
	@echo "✓ Repo initialized"

sync:
	cd $(ANDROID_TOP) && repo sync -c -j$(JOBS) --force-sync

build:
	@test -d $(ANDROID_TOP)/.repo || { echo "Run 'make init' first"; exit 1; }
	cd $(ANDROID_TOP) && . build/envsetup.sh && lunch lineage_$(DEVICE)-userdebug && make -j$(JOBS)

clean:
	cd $(ANDROID_TOP) && rm -rf out/

flash:
	@test -f out/target/product/*/lineage-*.zip || { echo "Build first: make build"; exit 1; }
	adb reboot bootloader
	fastboot flashall
	@echo "✓ Flashed"
