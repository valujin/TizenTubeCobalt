#!/bin/bash
# Test script to validate GBM build setup without building
# This script checks that all dependencies and configurations are correct

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0
warnings=0

print_test() {
    echo -e "\n${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((passed++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((failed++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((warnings++))
}

echo "======================================"
echo "GBM Build Setup Validation"
echo "======================================"

# Test 1: Check build script exists and is executable
print_test "Checking build script..."
if [ -x "${SCRIPT_DIR}/build_gbm.sh" ]; then
    print_pass "build_gbm.sh exists and is executable"
else
    print_fail "build_gbm.sh not found or not executable"
fi

# Test 2: Check documentation exists
print_test "Checking documentation..."
docs_ok=true
for doc in BUILD_GBM.md QUICKSTART_GBM.md Makefile.gbm docs/GBM_ARCHITECTURE.md; do
    if [ -f "${SCRIPT_DIR}/${doc}" ]; then
        print_pass "${doc} exists"
    else
        print_fail "${doc} not found"
        docs_ok=false
    fi
done

# Test 3: Check required commands
print_test "Checking required tools..."
for cmd in python3 clang ninja; do
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        print_pass "${cmd} is installed: ${version}"
    else
        print_fail "${cmd} is not installed"
    fi
done

# Test 4: Check optional but recommended tools
print_test "Checking optional tools..."
if command -v gn &> /dev/null; then
    version=$(gn --version 2>&1)
    print_pass "gn is installed: ${version}"
else
    print_warn "gn not installed (will be auto-downloaded)"
fi

if command -v ccache &> /dev/null; then
    print_pass "ccache is installed (will speed up builds)"
else
    print_warn "ccache not installed (builds will be slower)"
fi

# Test 5: Check for required libraries
print_test "Checking for required development libraries..."
# Note: Package names vary by distribution, so we check for the actual libraries
libs_to_check=(
    "ALSA:asound"
    "OpenGL ES:GLESv2"
    "GBM:gbm"
    "DRM:drm"
    "EGL:EGL"
)

for lib_pair in "${libs_to_check[@]}"; do
    lib_name="${lib_pair%%:*}"
    lib_file="${lib_pair##*:}"
    if ldconfig -p 2>/dev/null | grep -q "lib${lib_file}"; then
        print_pass "${lib_name} library (lib${lib_file}) is available"
    else
        print_warn "${lib_name} library (lib${lib_file}) may not be installed"
        print_warn "  Package names vary by distribution (e.g., lib${lib_file}-dev on Debian/Ubuntu)"
    fi
done

# Test 6: Check Python path setup
print_test "Checking Python environment..."
export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH}"
if python3 -c "import sys; sys.path.append('${SCRIPT_DIR}')" 2>/dev/null; then
    print_pass "Python can import from source directory"
else
    print_fail "Python import test failed"
fi

# Test 7: Check for Starboard structure
print_test "Checking Starboard structure..."
if [ -d "${SCRIPT_DIR}/starboard" ]; then
    print_pass "starboard directory exists"
    
    if [ -f "${SCRIPT_DIR}/starboard/build/platforms.py" ]; then
        print_pass "starboard/build/platforms.py exists"
    else
        print_fail "starboard/build/platforms.py not found"
    fi
    
    if [ -d "${SCRIPT_DIR}/starboard/linux/x64x11" ]; then
        print_pass "starboard/linux/x64x11 platform exists"
    else
        print_fail "starboard/linux/x64x11 platform not found"
    fi
else
    print_fail "starboard directory not found"
fi

# Test 8: Check for Cobalt structure
print_test "Checking Cobalt structure..."
if [ -d "${SCRIPT_DIR}/cobalt" ]; then
    print_pass "cobalt directory exists"
else
    print_fail "cobalt directory not found"
fi

# Test 9: Test GN args generation (dry run)
print_test "Testing GN args generation..."
test_output="/tmp/test_gbm_args_$$.txt"
cat > "$test_output" <<'EOF'
target_platform="linux-x64gbm"
target_os="linux"
target_cpu="x64"
build_type="gold"
sb_api_version=15
is_clang=true
EOF

if [ -s "$test_output" ]; then
    print_pass "GN args generation works"
    rm -f "$test_output"
else
    print_fail "GN args generation failed"
fi

# Test 10: Check disk space
print_test "Checking disk space..."
if command -v df &> /dev/null; then
    # Try modern df first, fallback to basic df
    if available_gb=$(df --output=avail -BG "${SCRIPT_DIR}" 2>/dev/null | tail -1 | sed 's/G//'); then
        # Modern df worked
        :
    else
        # Fallback to basic df
        available_gb=$(df -BG "${SCRIPT_DIR}" | tail -1 | awk '{print $(NF-2)}' | sed 's/G//')
    fi
    
    if [ -n "$available_gb" ] && [ "$available_gb" -gt 0 ] 2>/dev/null; then
        if [ "$available_gb" -gt 50 ]; then
            print_pass "Sufficient disk space available (${available_gb}GB)"
        elif [ "$available_gb" -gt 20 ]; then
            print_warn "Low disk space (${available_gb}GB) - 50GB+ recommended"
        else
            print_fail "Insufficient disk space (${available_gb}GB) - need at least 20GB"
        fi
    else
        print_warn "Could not determine available disk space"
    fi
else
    print_warn "df command not available"
fi

# Test 11: Check memory
print_test "Checking available memory..."
if command -v free &> /dev/null; then
    # Try to get available memory - format varies by free version
    mem_gb=$(free -g | awk '/^Mem:/ {print $7}' 2>/dev/null)
    if [ -z "$mem_gb" ] || [ "$mem_gb" -eq 0 ] 2>/dev/null; then
        # Fallback: try "available" field or total memory
        mem_gb=$(free -g | awk '/^Mem:/ {if ($7) print $7; else if ($4) print $4; else print $2}' 2>/dev/null)
    fi
    
    if [ -n "$mem_gb" ] && [ "$mem_gb" -gt 0 ] 2>/dev/null; then
        if [ "$mem_gb" -gt 8 ]; then
            print_pass "Sufficient memory available (${mem_gb}GB)"
        elif [ "$mem_gb" -gt 4 ]; then
            print_warn "Low memory (${mem_gb}GB) - 8GB+ recommended"
        else
            print_warn "Very low memory (${mem_gb}GB) - may need to reduce parallel jobs"
        fi
    else
        print_warn "Could not determine available memory"
    fi
else
    print_warn "free command not available"
fi

# Test 12: Check for DRM devices (runtime requirement)
print_test "Checking for DRM devices (runtime)..."
if ls /dev/dri/card* &> /dev/null; then
    drm_devices=$(ls /dev/dri/card* | wc -l)
    print_pass "Found ${drm_devices} DRM device(s)"
else
    print_warn "No DRM devices found (needed at runtime, not for building)"
fi

# Summary
echo ""
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "${GREEN}Passed:${NC}   $passed"
echo -e "${YELLOW}Warnings:${NC} $warnings"
echo -e "${RED}Failed:${NC}   $failed"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ Build setup is ready!${NC}"
    echo ""
    echo "You can now run:"
    echo "  ./build_gbm.sh"
    echo ""
    echo "Or use Make:"
    echo "  make -f Makefile.gbm build"
    exit 0
else
    echo -e "${RED}✗ Build setup has issues${NC}"
    echo ""
    echo "Please fix the failed checks above."
    echo "See BUILD_GBM.md for installation instructions."
    echo ""
    echo "To install dependencies on Ubuntu/Debian:"
    echo "  make -f Makefile.gbm deps"
    exit 1
fi
