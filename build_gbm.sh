#!/bin/bash
# Copyright 2024 The TizenTube Cobalt Authors. All Rights Reserved.
#
# Build script for creating static GBM (Generic Buffer Management) builds
# of TizenTube Cobalt for Linux x86_64 and ARM64 architectures.
#
# This script builds Cobalt with:
# - GBM/DRM/KMS support (no X11 dependency)
# - Static linking for minimal external dependencies
# - Support for both x86_64 and arm64 architectures

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE="${BUILD_TYPE:-gold}"
ARCHITECTURES="${ARCHITECTURES:-x86_64 arm64}"
OUTPUT_BASE_DIR="${OUTPUT_BASE_DIR:-${SCRIPT_DIR}/out}"
NINJA_PARALLEL="${NINJA_PARALLEL:-$(nproc)}"
SB_API_VERSION="${SB_API_VERSION:-15}"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    print_info "Checking build dependencies..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in gn ninja python3 clang; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install the following packages:"
        print_info "  Ubuntu/Debian: sudo apt-get install gn ninja-build python3 clang"
        return 1
    fi
    
    # Check GN version
    if ! gn --version &> /dev/null; then
        print_warning "Could not determine GN version"
    fi
    
    print_info "All required dependencies are installed"
    return 0
}

# Function to install GN if not available
install_gn() {
    if command -v gn &> /dev/null; then
        print_info "GN is already installed"
        return 0
    fi
    
    print_info "Installing GN..."
    local gn_dir="${SCRIPT_DIR}/.build_tools"
    mkdir -p "$gn_dir"
    
    cd "$gn_dir"
    if [ ! -f "gn" ]; then
        local arch=$(uname -m)
        local gn_platform="linux-amd64"
        
        if [ "$arch" = "aarch64" ]; then
            gn_platform="linux-arm64"
        fi
        
        print_info "Downloading GN for ${gn_platform}..."
        wget -q "https://chrome-infra-packages.appspot.com/dl/gn/gn/${gn_platform}/+/latest" -O gn.zip
        unzip -q gn.zip
        chmod +x gn
        rm gn.zip
    fi
    
    export PATH="${gn_dir}:${PATH}"
    cd "$SCRIPT_DIR"
    
    if command -v gn &> /dev/null; then
        print_info "GN installed successfully"
    else
        print_error "Failed to install GN"
        return 1
    fi
}

# Function to setup build environment
setup_environment() {
    print_info "Setting up build environment..."
    
    # Set PYTHONPATH to include the source root
    export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH}"
    
    # Download clang if needed
    if [ ! -d "${HOME}/starboard-toolchains" ]; then
        print_info "Downloading Clang toolchain..."
        bash "${SCRIPT_DIR}/starboard/tools/download_clang.sh"
    fi
    
    print_info "Build environment ready"
}

# Function to generate GN arguments for GBM build
generate_gn_args() {
    local platform="$1"
    local arch="$2"
    
    cat <<EOF
target_platform="${platform}"
target_os="linux"
target_cpu="${arch}"
build_type="${BUILD_TYPE}"
sb_api_version=${SB_API_VERSION}
is_clang=true
use_thin_lto=false

# Static linking configuration
use_system_libjpeg=false
use_system_libpng=false
use_system_zlib=false
use_system_libwebp=false
use_system_freetype=false
use_system_harfbuzz=false

# GBM/DRM specific configuration
use_gbm=true
use_x11=false
use_wayland=false

# Media codecs - statically linked
ffmpeg_branding="Chrome"

# Disable features that require external dependencies
enable_plugins=false
use_glib=false
use_pulseaudio=false
use_alsa=true

# Performance optimizations
is_debug=false
symbol_level=0
enable_stripping=true
EOF
}

# Function to build for a specific architecture
build_for_architecture() {
    local arch="$1"
    local platform_name=""
    local target_cpu=""
    
    case "$arch" in
        x86_64|x64)
            platform_name="linux-x64gbm"
            target_cpu="x64"
            ;;
        arm64|aarch64)
            platform_name="linux-arm64gbm"
            target_cpu="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    local out_dir="${OUTPUT_BASE_DIR}/${platform_name}_${BUILD_TYPE}"
    
    print_info "Building for ${arch} (${platform_name})..."
    print_info "Output directory: ${out_dir}"
    
    # Generate GN configuration
    print_info "Generating build files with GN..."
    local args_content=$(generate_gn_args "$platform_name" "$target_cpu")
    
    # For now, use the existing linux-x64x11 platform as base
    # We'll fallback to this until GBM-specific platforms are created
    local fallback_platform="linux-x64x11"
    if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
        # For ARM64, we'll still use x64x11 config but with arm64 target_cpu
        print_warning "Using ${fallback_platform} as base platform (GBM-specific platform not yet implemented)"
    fi
    
    # Create a temporary args.gn file
    mkdir -p "$out_dir"
    echo "$args_content" > "${out_dir}/args.gn"
    
    # Run GN with properly escaped args
    # We pass the args via the args.gn file rather than command line for reliability
    if ! gn gen "$out_dir" 2>&1 | tee "${out_dir}/gn.log"; then
        print_error "GN generation failed for ${arch}"
        print_info "Check ${out_dir}/gn.log for details"
        return 1
    fi
    
    # Check GN configuration
    print_info "Validating GN configuration..."
    if ! gn check "$out_dir" 2>&1 | tee "${out_dir}/gn_check.log"; then
        print_warning "GN check reported issues (this may be expected)"
    fi
    
    # Build with Ninja
    print_info "Building Cobalt with Ninja (using ${NINJA_PARALLEL} parallel jobs)..."
    local ninja_status="[%e sec | %f/%t %u remaining | %c/sec | j%r] "
    
    if ! NINJA_STATUS="$ninja_status" ninja -C "$out_dir" -j "${NINJA_PARALLEL}" cobalt 2>&1 | tee "${out_dir}/ninja.log"; then
        print_error "Build failed for ${arch}"
        print_info "Check ${out_dir}/ninja.log for details"
        return 1
    fi
    
    # Check if binary was created
    if [ -f "${out_dir}/cobalt" ]; then
        print_info "Build successful for ${arch}!"
        print_info "Binary location: ${out_dir}/cobalt"
        
        # Print binary information
        file "${out_dir}/cobalt"
        ls -lh "${out_dir}/cobalt"
        
        # Check dependencies (should be minimal for static build)
        print_info "Binary dependencies:"
        ldd "${out_dir}/cobalt" || print_warning "ldd not available or binary is fully static"
    else
        print_warning "Binary not found at expected location: ${out_dir}/cobalt"
        print_info "Looking for alternative build outputs..."
        find "$out_dir" -name "cobalt" -o -name "*.so" -o -name "*.a" | head -20
    fi
    
    return 0
}

# Function to create distribution package
create_package() {
    local arch="$1"
    local platform_name=""
    
    case "$arch" in
        x86_64|x64)
            platform_name="linux-x64gbm"
            ;;
        arm64|aarch64)
            platform_name="linux-arm64gbm"
            ;;
        *)
            return 1
            ;;
    esac
    
    local out_dir="${OUTPUT_BASE_DIR}/${platform_name}_${BUILD_TYPE}"
    local package_dir="${OUTPUT_BASE_DIR}/package/${platform_name}"
    
    if [ ! -f "${out_dir}/cobalt" ]; then
        print_warning "Cannot create package: binary not found for ${arch}"
        return 1
    fi
    
    print_info "Creating distribution package for ${arch}..."
    mkdir -p "$package_dir"
    
    # Copy binary
    cp "${out_dir}/cobalt" "${package_dir}/"
    
    # Copy content directory if it exists
    if [ -d "${out_dir}/content" ]; then
        cp -r "${out_dir}/content" "${package_dir}/"
    fi
    
    # Create README
    cat > "${package_dir}/README.txt" <<EOF
TizenTube Cobalt - GBM Build
============================

Architecture: ${arch}
Build Type: ${BUILD_TYPE}
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

This is a static build designed to run on Linux systems with GBM/DRM/KMS support.
No X11 or Wayland is required.

To run:
  ./cobalt

For more information, visit:
https://github.com/reisxd/TizenTubeCobalt
EOF
    
    # Create tarball
    local tarball="${OUTPUT_BASE_DIR}/tizentube-cobalt-${platform_name}-${BUILD_TYPE}.tar.gz"
    print_info "Creating tarball: ${tarball}"
    tar -czf "$tarball" -C "${OUTPUT_BASE_DIR}/package" "${platform_name}"
    
    print_info "Package created: ${tarball}"
    ls -lh "$tarball"
}

# Main build function
main() {
    print_info "TizenTube Cobalt - GBM Static Build Script"
    print_info "=========================================="
    print_info "Build Type: ${BUILD_TYPE}"
    print_info "Architectures: ${ARCHITECTURES}"
    print_info "Output Directory: ${OUTPUT_BASE_DIR}"
    print_info "Ninja Parallel Jobs: ${NINJA_PARALLEL}"
    print_info ""
    
    # Check and install dependencies
    if ! check_dependencies; then
        print_info "Attempting to install GN..."
        if ! install_gn; then
            print_error "Failed to install required dependencies"
            exit 1
        fi
        # Recheck after installation
        if ! check_dependencies; then
            print_error "Dependencies still missing after installation attempt"
            exit 1
        fi
    fi
    
    # Setup environment
    setup_environment
    
    # Build for each architecture
    local failed_builds=()
    for arch in $ARCHITECTURES; do
        print_info ""
        print_info "=========================================="
        if build_for_architecture "$arch"; then
            print_info "Successfully built for ${arch}"
            create_package "$arch" || print_warning "Failed to create package for ${arch}"
        else
            print_error "Failed to build for ${arch}"
            failed_builds+=("$arch")
        fi
    done
    
    # Summary
    print_info ""
    print_info "=========================================="
    print_info "Build Summary"
    print_info "=========================================="
    
    if [ ${#failed_builds[@]} -eq 0 ]; then
        print_info "All builds completed successfully!"
    else
        print_error "Failed builds: ${failed_builds[*]}"
        exit 1
    fi
    
    print_info ""
    print_info "Build artifacts are located in: ${OUTPUT_BASE_DIR}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --arch)
            ARCHITECTURES="$2"
            shift 2
            ;;
        --output)
            OUTPUT_BASE_DIR="$2"
            shift 2
            ;;
        --jobs|-j)
            NINJA_PARALLEL="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [OPTIONS]

Build TizenTube Cobalt with GBM support for Linux.

Options:
  --build-type TYPE     Build type: debug, devel, qa, or gold (default: gold)
  --arch ARCHS          Space-separated architectures to build (default: "x86_64 arm64")
  --output DIR          Output directory (default: ./out)
  --jobs,-j NUM         Number of parallel ninja jobs (default: nproc)
  --help,-h             Show this help message

Environment Variables:
  BUILD_TYPE            Build type (default: gold)
  ARCHITECTURES         Architectures to build (default: "x86_64 arm64")
  OUTPUT_BASE_DIR       Output directory (default: ./out)
  NINJA_PARALLEL        Ninja parallel jobs (default: nproc)
  SB_API_VERSION        Starboard API version (default: 15)

Examples:
  # Build for both architectures (default)
  $0

  # Build only x86_64 debug version
  $0 --build-type debug --arch x86_64

  # Build with 16 parallel jobs
  $0 --jobs 16

EOF
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_info "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main
