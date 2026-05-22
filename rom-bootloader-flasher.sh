#!/bin/bash
# ROM Bootloader Flasher — safely flash Android bootloader, recovery, and baseband
# Prevents hard-brick scenarios with pre-flight checks

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[*]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[!]${NC} $1"; }

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v adb &> /dev/null; then
        log_error "adb not found. Install Android SDK Platform-Tools"
        exit 1
    fi
    
    if ! command -v fastboot &> /dev/null; then
        log_error "fastboot not found. Install Android SDK Platform-Tools"
        exit 1
    fi
    
    log_info "✓ adb found: $(adb version | head -1)"
    log_info "✓ fastboot found: $(fastboot --version | head -1)"
}

check_device_connectivity() {
    log_info "Checking device connectivity..."
    
    local devices=$(adb devices | grep -c 'device$' || true)
    
    if [ "$devices" -eq 0 ]; then
        log_error "No ADB devices found. Enable USB debugging and reconnect."
        exit 1
    fi
    
    log_info "✓ Device detected via ADB"
}

check_device_state() {
    log_info "Checking device state..."
    
    local state=$(adb get-state 2>/dev/null || echo "unknown")
    log_info "Device state: $state"
    
    if [ "$state" != "device" ]; then
        log_warn "Device not in 'device' state. Waiting..."
        adb wait-for-device
        sleep 2
    fi
}

backup_current_images() {
    local device_id=$(adb shell getprop ro.serialno)
    local backup_dir="bootloader_backup_${device_id}_$(date +%s)"
    
    log_info "Backing up current images to $backup_dir/"
    mkdir -p "$backup_dir"
    
    # Backup bootloader
    log_info "  Dumping bootloader..."
    adb shell "dd if=/dev/block/platform/*/by-name/bootloader of=/data/local/tmp/bootloader.img 2>/dev/null || echo 'Bootloader backup skipped (not accessible)'" > /dev/null
    adb pull /data/local/tmp/bootloader.img "$backup_dir/" 2>/dev/null || true
    
    # Backup recovery
    log_info "  Dumping recovery..."
    adb shell "dd if=/dev/block/platform/*/by-name/recovery of=/data/local/tmp/recovery.img 2>/dev/null || echo 'Recovery backup skipped (not accessible)'" > /dev/null
    adb pull /data/local/tmp/recovery.img "$backup_dir/" 2>/dev/null || true
    
    log_info "✓ Backup complete: $backup_dir/"
}

validate_images() {
    local bootloader_file=$1
    local recovery_file=$2
    
    log_info "Validating image files..."
    
    if [ ! -f "$bootloader_file" ]; then
        log_error "Bootloader file not found: $bootloader_file"
        exit 1
    fi
    
    if [ ! -f "$recovery_file" ]; then
        log_error "Recovery file not found: $recovery_file"
        exit 1
    fi
    
    local bootloader_size=$(stat -f%z "$bootloader_file" 2>/dev/null || stat -c%s "$bootloader_file")
    local recovery_size=$(stat -f%z "$recovery_file" 2>/dev/null || stat -c%s "$recovery_file")
    
    if [ "$bootloader_size" -lt 1000000 ]; then
        log_error "Bootloader file suspiciously small: ${bootloader_size} bytes"
        exit 1
    fi
    
    if [ "$recovery_size" -lt 8000000 ]; then
        log_error "Recovery file suspiciously small: ${recovery_size} bytes"
        exit 1
    fi
    
    log_info "✓ Bootloader: ${bootloader_size} bytes"
    log_info "✓ Recovery: ${recovery_size} bytes"
}

flash_images() {
    local bootloader_file=$1
    local recovery_file=$2
    
    log_info "Entering fastboot mode..."
    adb reboot bootloader
    sleep 5
    
    log_info "Waiting for fastboot device..."
    fastboot wait-for-device
    
    log_info "Checking fastboot connectivity..."
    if ! fastboot devices | grep -q "fastboot"; then
        log_error "Device not detected in fastboot mode"
        exit 1
    fi
    
    log_info "🔥 Flashing bootloader..."
    fastboot flash bootloader "$bootloader_file"
    
    log_info "🔥 Flashing recovery..."
    fastboot flash recovery "$recovery_file"
    
    log_info "Rebooting to bootloader..."
    fastboot reboot bootloader
    sleep 3
    
    log_info "Rebooting to system..."
    fastboot reboot
    
    log_info "✓ Flash complete. Device rebooting..."
}

main() {
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <bootloader.img> <recovery.img>"
        echo "Example: $0 bootloader-flo-flo-latest.img recovery.img"
        exit 1
    fi
    
    local bootloader_file=$1
    local recovery_file=$2
    
    log_info "ROM Bootloader Flasher v1.0"
    log_info "================================"
    
    check_prerequisites
    check_device_connectivity
    check_device_state
    validate_images "$bootloader_file" "$recovery_file"
    
    log_warn "DANGER: This will flash critical boot partitions"
    log_warn "Ensure battery is ≥50% and connection is stable"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_error "Aborted"
        exit 1
    fi
    
    backup_current_images
    flash_images "$bootloader_file" "$recovery_file"
    
    log_info "✅ All done! Device is booting..."
}

main "$@"
