#!/bin/bash
# Example build commands for GBM builds
# This file shows various ways to build TizenTube Cobalt with GBM support

# NOTE: This is a documentation file showing examples.
# Copy and run the commands you need individually.

set -e

# ==============================================================================
# BASIC EXAMPLES
# ==============================================================================

# Build everything (both x86_64 and ARM64) - Gold release
./build_gbm.sh

# Build only x86_64
./build_gbm.sh --arch x86_64

# Build only ARM64
./build_gbm.sh --arch arm64

# ==============================================================================
# BUILD TYPES
# ==============================================================================

# Production release build (optimized, small binary)
./build_gbm.sh --build-type gold

# QA build (good performance, some debug info)
./build_gbm.sh --build-type qa

# Development build (faster compilation, more debug features)
./build_gbm.sh --build-type devel

# Full debug build (slowest, largest, maximum debug info)
./build_gbm.sh --build-type debug

# ==============================================================================
# ARCHITECTURE-SPECIFIC BUILDS
# ==============================================================================

# x86_64 gold build
./build_gbm.sh --build-type gold --arch x86_64

# ARM64 debug build
./build_gbm.sh --build-type debug --arch arm64

# ==============================================================================
# PARALLEL BUILDS
# ==============================================================================

# Use all available CPU cores (fastest)
./build_gbm.sh --jobs $(nproc)

# Use specific number of parallel jobs
./build_gbm.sh --jobs 8

# Conservative build (low memory usage)
./build_gbm.sh --jobs 2

# ==============================================================================
# CUSTOM OUTPUT DIRECTORY
# ==============================================================================

# Build to custom directory
./build_gbm.sh --output /tmp/cobalt_build

# Build to user's home directory
./build_gbm.sh --output ~/cobalt_builds

# ==============================================================================
# USING MAKE
# ==============================================================================

# Build using Makefile
make -f Makefile.gbm build

# Build only x86_64 using Make
make -f Makefile.gbm build-x64

# Build only ARM64 using Make
make -f Makefile.gbm build-arm64

# Debug build using Make
make -f Makefile.gbm build-debug

# Fast build using all cores
make -f Makefile.gbm fast-build

# Clean and rebuild
make -f Makefile.gbm clean build

# ==============================================================================
# DOCKER BUILDS
# ==============================================================================

# Build Docker image
docker build -t cobalt-gbm-builder -f Dockerfile.gbm .

# Run interactive shell in Docker
docker run -it -v $(pwd):/code -v ccache:/root/.ccache cobalt-gbm-builder

# Build x86_64 in Docker
docker run -v $(pwd):/code -v ccache:/root/.ccache cobalt-gbm-builder \
    ./build_gbm.sh --arch x86_64

# Using Docker Compose
docker-compose -f docker-compose-gbm.yml build
docker-compose -f docker-compose-gbm.yml run --rm gbm-x64

# ==============================================================================
# CROSS-COMPILATION
# ==============================================================================

# Cross-compile ARM64 on x86_64 (requires cross-compiler)
# First install: sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
./build_gbm.sh --arch arm64

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# Set environment variables for build
export BUILD_TYPE=gold
export ARCHITECTURES="x86_64 arm64"
export NINJA_PARALLEL=8
./build_gbm.sh

# One-liner with environment variables
BUILD_TYPE=debug ARCHITECTURES=x86_64 ./build_gbm.sh

# ==============================================================================
# COMBINED EXAMPLES
# ==============================================================================

# Production build for x86_64 with 8 parallel jobs
./build_gbm.sh --build-type gold --arch x86_64 --jobs 8

# Debug build for ARM64 to custom directory
./build_gbm.sh --build-type debug --arch arm64 --output /tmp/arm64_debug

# Build both architectures as QA builds with maximum parallelism
./build_gbm.sh --build-type qa --arch "x86_64 arm64" --jobs $(nproc)

# ==============================================================================
# VALIDATION AND TESTING
# ==============================================================================

# Test build setup before building
./test_build_setup.sh

# Check dependencies using Make
make -f Makefile.gbm check-deps

# Show build information
make -f Makefile.gbm info

# ==============================================================================
# RUNNING THE BUILT BINARY
# ==============================================================================

# Run x86_64 binary
./out/linux-x64gbm_gold/cobalt

# Run with custom URL
./out/linux-x64gbm_gold/cobalt --url=https://www.youtube.com/tv

# Run ARM64 binary
./out/linux-arm64gbm_gold/cobalt

# Run using Make helper
make -f Makefile.gbm run-x64

# ==============================================================================
# CLEANING
# ==============================================================================

# Clean all build artifacts
make -f Makefile.gbm clean

# Clean only x86_64 builds
make -f Makefile.gbm clean-x64

# Clean only ARM64 builds
make -f Makefile.gbm clean-arm64

# Manual clean
rm -rf out/

# ==============================================================================
# CI/CD EXAMPLES
# ==============================================================================

# Simulate CI build
NINJA_PARALLEL=4 BUILD_TYPE=gold ./build_gbm.sh --arch x86_64

# Build for release (both architectures)
./build_gbm.sh --build-type gold --arch "x86_64 arm64" --jobs $(nproc)

# ==============================================================================
# ADVANCED: CUSTOM GN ARGS
# ==============================================================================

# For advanced users who want to customize GN args:
# 1. Edit the generate_gn_args() function in build_gbm.sh
# 2. Or manually run GN and Ninja:

# Example manual build:
export PYTHONPATH=$(pwd):$PYTHONPATH
mkdir -p out/custom_build

# Create custom args.gn file
cat > out/custom_build/args.gn <<EOF
target_platform="linux-x64x11"
target_os="linux"
target_cpu="x64"
build_type="gold"
sb_api_version=15
is_clang=true
EOF

# Generate and build
gn gen out/custom_build
ninja -C out/custom_build cobalt

# ==============================================================================
# TROUBLESHOOTING BUILDS
# ==============================================================================

# Build with verbose output
./build_gbm.sh --arch x86_64 2>&1 | tee build.log

# Check build logs
less out/linux-x64gbm_gold/ninja.log
less out/linux-x64gbm_gold/gn.log

# Build with single thread for easier debugging
./build_gbm.sh --jobs 1

# ==============================================================================
# PERFORMANCE TESTING
# ==============================================================================

# Time the build
time ./build_gbm.sh --arch x86_64

# Build with ccache statistics
CCACHE_DIR=$HOME/.ccache ccache -z  # Reset stats
./build_gbm.sh --arch x86_64
ccache -s  # Show stats

# ==============================================================================
# INSTALL AND PACKAGE
# ==============================================================================

# Build and create packages
make -f Makefile.gbm install

# Manually create tarball
cd out
tar -czf ../cobalt-gbm-x64-gold.tar.gz linux-x64gbm_gold/

# ==============================================================================
# NOTES
# ==============================================================================

# - Replace 'gold' with 'debug', 'devel', or 'qa' as needed
# - Replace 'x86_64' with 'arm64' for ARM builds
# - Adjust --jobs based on available CPU and RAM
# - Use ccache for faster rebuilds
# - Check disk space before building (need 50GB+)
# - First build takes longer (downloads dependencies)
# - Subsequent builds are much faster with ccache

# ==============================================================================
# MORE INFORMATION
# ==============================================================================

# See documentation:
# - QUICKSTART_GBM.md - Quick start guide
# - BUILD_GBM.md - Detailed build documentation
# - GBM_BUILD_README.md - Complete overview
# - docs/GBM_ARCHITECTURE.md - Technical details

# Get help:
./build_gbm.sh --help
make -f Makefile.gbm help
