# Quick Start Guide: Building GBM Version

This guide will help you quickly build TizenTube Cobalt with GBM support.

## TL;DR

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y \
    build-essential clang ninja-build python3 wget unzip \
    libasound2-dev libgles2-mesa-dev libgbm-dev libdrm-dev

# Build
./build_gbm.sh

# Run (x86_64)
./out/linux-x64gbm_gold/cobalt
```

## Step by Step

### 1. Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y build-essential clang ninja-build python3 \
    wget unzip git pkg-config libasound2-dev libgles2-mesa-dev \
    libgbm-dev libdrm-dev libegl1-mesa-dev bison nasm
```

**Using Make:**
```bash
make -f Makefile.gbm deps
```

### 2. Build

**Default build (both architectures):**
```bash
./build_gbm.sh
```

**Or using Make:**
```bash
make -f Makefile.gbm build
```

**Build only x86_64:**
```bash
./build_gbm.sh --arch x86_64
# or
make -f Makefile.gbm build-x64
```

**Build only ARM64:**
```bash
./build_gbm.sh --arch arm64
# or
make -f Makefile.gbm build-arm64
```

### 3. Find Your Binary

After building, your binary will be at:
- x86_64: `out/linux-x64gbm_gold/cobalt`
- ARM64: `out/linux-arm64gbm_gold/cobalt`

### 4. Run

```bash
cd out/linux-x64gbm_gold
./cobalt
```

Or with custom URL:
```bash
./cobalt --url=https://www.youtube.com/tv
```

## Build Options

### Build Types

- `--build-type gold` - Production release (default, recommended)
- `--build-type qa` - QA build
- `--build-type devel` - Development build
- `--build-type debug` - Full debug build

### Examples

**Debug build:**
```bash
./build_gbm.sh --build-type debug
```

**Fast build (use all CPU cores):**
```bash
./build_gbm.sh --jobs $(nproc)
```

**Custom output directory:**
```bash
./build_gbm.sh --output /tmp/mybuild
```

## Troubleshooting

### "Command not found: gn"
The script will automatically download GN. If it fails:
```bash
wget https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/latest -O gn.zip
unzip gn.zip && sudo mv gn /usr/local/bin/ && sudo chmod +x /usr/local/bin/gn
```

### Build fails with missing dependencies
Install all dependencies:
```bash
make -f Makefile.gbm deps
```

### Binary won't run
Check that you have GPU support:
```bash
ls -l /dev/dri/card*
ldconfig -p | grep -E "libEGL|libgbm|libdrm"
```

### Out of memory during build
Use fewer parallel jobs:
```bash
./build_gbm.sh --jobs 4
```

## What's Next?

- See [BUILD_GBM.md](BUILD_GBM.md) for detailed build instructions
- Check [README.md](README.md) for project information
- Report issues at https://github.com/reisxd/TizenTube/issues

## Build Time

Expected build times (approximate):
- x86_64 gold build: 20-40 minutes (depending on CPU)
- ARM64 gold build: 20-40 minutes (native) or 30-60 minutes (cross-compile)
- Debug builds take longer

## System Requirements

**For Building:**
- Linux (any modern distribution)
- 8GB+ RAM (16GB recommended)
- 50GB+ free disk space
- Multi-core CPU (more cores = faster builds)

**For Running:**
- Linux with DRM/KMS support
- GPU with EGL support
- 2GB+ RAM
- No X11 or Wayland required
