#!/bin/bash
# ROM Build Monitor - Real-time build process monitor and analyzer
# Tracks build time, resource usage, and provides optimization suggestions

set -e

BUILD_LOG="${1:-.}"
MONITOR_INTERVAL=5
TOTAL_BUILD_TIME=0
PEAK_MEMORY=0
PEAK_CPU=0
FAILED_MODULES=()

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Monitor build process in real-time
monitor_build() {
    log_info "Starting ROM build monitor..."
    
    local start_time=$(date +%s)
    local build_pid=$1
    
    while kill -0 "$build_pid" 2>/dev/null; do
        # Get memory usage in MB
        local mem_usage=$(ps -p "$build_pid" -o %mem= | awk '{print $1 * 10}' 2>/dev/null || echo "0")
        
        # Get CPU usage
        local cpu_usage=$(ps -p "$build_pid" -o %cpu= 2>/dev/null || echo "0")
        
        # Update peaks
        if (( $(echo "$mem_usage > $PEAK_MEMORY" | bc -l) )); then
            PEAK_MEMORY="$mem_usage"
        fi
        
        if (( $(echo "$cpu_usage > $PEAK_CPU" | bc -l) )); then
            PEAK_CPU="$cpu_usage"
        fi
        
        sleep "$MONITOR_INTERVAL"
    done
    
    local end_time=$(date +%s)
    TOTAL_BUILD_TIME=$((end_time - start_time))
}

# Parse build log for warnings and errors
parse_build_log() {
    log_info "Analyzing build log: $BUILD_LOG"
    
    if [[ ! -f "$BUILD_LOG" ]]; then
        log_error "Build log not found: $BUILD_LOG"
        return 1
    fi
    
    # Count errors and warnings
    local error_count=$(grep -c "error:" "$BUILD_LOG" 2>/dev/null || echo "0")
    local warning_count=$(grep -c "warning:" "$BUILD_LOG" 2>/dev/null || echo "0")
    
    # Find failed modules
    while IFS= read -r line; do
        if [[ $line =~ \[ERROR\].*module ]]; then
            FAILED_MODULES+=("$line")
        fi
    done < "$BUILD_LOG"
    
    echo "  Errors: $error_count"
    echo "  Warnings: $warning_count"
    echo "  Failed modules: ${#FAILED_MODULES[@]}"
}

# Generate build report
generate_report() {
    log_info "Generating build report..."
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   ROM BUILD ANALYSIS REPORT            ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "⏱️  Build Time:"
    echo "   Total: ${TOTAL_BUILD_TIME}s ($(( TOTAL_BUILD_TIME / 60 ))m $(( TOTAL_BUILD_TIME % 60 ))s)"
    echo ""
    echo "💾 Resource Usage:"
    echo "   Peak Memory: ${PEAK_MEMORY}%"
    echo "   Peak CPU: ${PEAK_CPU}%"
    echo ""
    
    if [[ ${#FAILED_MODULES[@]} -gt 0 ]]; then
        echo "⚠️  Failed Modules (${#FAILED_MODULES[@]}):"
        for module in "${FAILED_MODULES[@]}"; do
            echo "   $module"
        done
        echo ""
    fi
    
    parse_build_log
    echo ""
    echo "📊 Build Recommendations:"
    
    # Check for optimization opportunities
    if (( $(echo "$PEAK_MEMORY > 80" | bc -l) )); then
        log_warning "High memory usage detected. Consider: -j1 or --low-memory flag"
    fi
    
    if (( TOTAL_BUILD_TIME > 3600 )); then
        log_warning "Long build time (>1hr). Enable ccache or use parallel compilation"
    fi
    
    echo ""
}

# Main execution
main() {
    if [[ ! -f "$BUILD_LOG" ]]; then
        log_error "Usage: $0 <build_log_file>"
        exit 1
    fi
    
    generate_report
}

main "$@"
