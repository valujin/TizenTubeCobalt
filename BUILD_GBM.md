# Building TizenTube Cobalt with GBM Support

This document describes how to build TizenTube Cobalt with GBM (Generic Buffer Management) support for running on Linux systems without X11.

## Overview

The GBM build creates a static binary that can run on Linux systems with DRM/KMS support, making it suitable for:
- Embedded Linux systems
- Headless servers with GPU
- Set-top boxes
- IoT devices with display output
- Any Linux system without X11/Wayland

## Prerequisites

### Required Dependencies

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    clang \
    ninja-build \
    python3 \
    python3-pip \
    wget \
    unzip \
    git \
    pkg-config \
    libasound2-dev \
    libgles2-mesa-dev \
    libgbm-dev \
    libdrm-dev \
    libegl1-mesa-dev \
    bison \
    nasm
```

#### Fedora/RHEL
```bash
sudo dnf install -y \
    gcc gcc-c++ \
    clang \
    ninja-build \
    python3 \
    wget \
    unzip \
    git \
    pkgconfig \
    alsa-lib-devel \
    mesa-libGLES-devel \
    mesa-libgbm-devel \
    libdrm-devel \
    mesa-libEGL-devel \
    bison \
    nasm
```

#### Arch Linux
```bash
sudo pacman -S --needed \
    base-devel \
    clang \
    ninja \
    python \
    wget \
    unzip \
    git \
    pkgconfig \
    alsa-lib \
    mesa \
    libdrm \
    bison \
    nasm
```

### Optional: Install GN

The build script can automatically download GN, but you can also install it manually:

```bash
# Download GN for your architecture
wget https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/latest -O gn.zip
unzip gn.zip
sudo mv gn /usr/local/bin/
sudo chmod +x /usr/local/bin/gn
```

For ARM64 systems, replace `linux-amd64` with `linux-arm64`.

## Building

### Quick Start

To build for both x86_64 and ARM64 architectures:

```bash
./build_gbm.sh
```

### Build Options

The build script supports several options:

```bash
./build_gbm.sh [OPTIONS]

Options:
  --build-type TYPE     Build type: debug, devel, qa, or gold (default: gold)
  --arch ARCHS          Space-separated architectures (default: "x86_64 arm64")
  --output DIR          Output directory (default: ./out)
  --jobs,-j NUM         Number of parallel ninja jobs (default: nproc)
  --help,-h             Show help message
```

### Build Examples

#### Build only for x86_64
```bash
./build_gbm.sh --arch x86_64
```

#### Build debug version
```bash
./build_gbm.sh --build-type debug
```

#### Build with specific number of parallel jobs
```bash
./build_gbm.sh --jobs 8
```

#### Build for ARM64 only with custom output directory
```bash
./build_gbm.sh --arch arm64 --output /tmp/cobalt_build
```

### Build Types

- **gold**: Release build with optimizations (recommended for production)
- **qa**: QA build with some debugging features
- **devel**: Development build with more debugging features
- **debug**: Full debug build (slowest, largest)

## Cross-Compilation

### Building ARM64 on x86_64

To cross-compile for ARM64 on an x86_64 host:

```bash
# Install cross-compilation toolchain
sudo apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu

# Build
./build_gbm.sh --arch arm64
```

### Building x86_64 on ARM64

To cross-compile for x86_64 on an ARM64 host:

```bash
# Install cross-compilation toolchain
sudo apt-get install -y \
    gcc-x86-64-linux-gnu \
    g++-x86-64-linux-gnu \
    binutils-x86-64-linux-gnu

# Build
./build_gbm.sh --arch x86_64
```

## Output

After a successful build, you'll find:

### Build Artifacts
- Binary: `out/<platform>_<build_type>/cobalt`
- Build logs: `out/<platform>_<build_type>/*.log`
- Content: `out/<platform>_<build_type>/content/`

### Distribution Packages
- Tarball: `out/tizentube-cobalt-<platform>-<build_type>.tar.gz`
- Package: `out/package/<platform>/`

### Platforms
- `linux-x64gbm`: x86_64 architecture
- `linux-arm64gbm`: ARM64 architecture

## Running the Binary

### Basic Usage
```bash
cd out/linux-x64gbm_gold
./cobalt
```

### With Custom Options
```bash
./cobalt --url=https://www.youtube.com/tv
```

### Required Runtime Environment

The binary requires:
1. A Linux system with DRM/KMS support
2. GPU with EGL support
3. No X11 or Wayland required
4. ALSA for audio (or audio can be disabled)

### Minimal Runtime Dependencies

The binary is statically linked to minimize dependencies. Required system libraries:
- `libc` (glibc or musl)
- `libpthread`
- `libdl`
- `libm`
- `libgcc_s`
- `libasound` (for ALSA audio)
- `libEGL`
- `libGLESv2`
- `libgbm`
- `libdrm`

To check actual dependencies:
```bash
ldd out/linux-x64gbm_gold/cobalt
```

## Troubleshooting

### GN Generation Fails

If GN fails to generate build files:

1. Check that all dependencies are installed
2. Verify PYTHONPATH is set correctly:
   ```bash
   export PYTHONPATH=$(pwd):$PYTHONPATH
   ```
3. Check GN logs: `cat out/<platform>_<build_type>/gn.log`

### Build Fails

If the build fails:

1. Check Ninja logs: `cat out/<platform>_<build_type>/ninja.log`
2. Ensure you have enough disk space (builds can be large)
3. Try building with fewer parallel jobs: `./build_gbm.sh --jobs 4`
4. Check that Clang is properly installed

### Binary Won't Run

If the binary doesn't run:

1. Check that your system has DRM/KMS support:
   ```bash
   ls -l /dev/dri/card*
   ```
2. Ensure you have GPU drivers installed
3. Check EGL is available:
   ```bash
   ldconfig -p | grep libEGL
   ```
4. Verify GBM support:
   ```bash
   ldconfig -p | grep libgbm
   ```
5. Check that you have permissions to access `/dev/dri/card0`

### Missing Dependencies

If you get "library not found" errors:

1. Install missing libraries using your package manager
2. For ALSA: `sudo apt-get install libasound2`
3. For EGL: `sudo apt-get install libegl1-mesa`
4. For GBM: `sudo apt-get install libgbm1`

## Performance Optimization

### Build Performance

To speed up builds:
- Use more parallel jobs: `--jobs $(nproc)`
- Use ccache: `export USE_CCACHE=1`
- Build only what you need: `--arch x86_64`

### Runtime Performance

The gold build is optimized for performance. For even better performance:
- Ensure GPU drivers are up to date
- Use appropriate GPU hardware acceleration
- Run on a system with sufficient RAM (recommended: 2GB+)

## Development

### Build Configuration

The build script generates GN args with these settings:
- Static linking for most dependencies
- GBM/DRM/KMS support enabled
- X11 disabled
- ALSA audio enabled (PulseAudio disabled)
- Optimizations enabled for gold builds

### Modifying the Build

To customize the build, edit `build_gbm.sh` and modify the `generate_gn_args()` function.

Common customizations:
- Add/remove media codecs
- Change optimization level
- Enable/disable features
- Adjust memory settings

### Adding GBM Platform Support

Currently, the build script uses the existing Linux platform as a base. To create a dedicated GBM platform:

1. Create platform directories:
   ```bash
   mkdir -p starboard/linux/x64gbm
   mkdir -p starboard/linux/arm64gbm
   ```

2. Implement GBM-specific window system code (replacing X11)

3. Update `starboard/build/platforms.py` to register new platforms

4. Create BUILD.gn, args.gn, and configuration files

## Contributing

When contributing GBM build improvements:

1. Test on multiple architectures
2. Ensure builds are as static as possible
3. Document any new dependencies
4. Update this documentation

## Additional Resources

- [Cobalt Documentation](https://cobalt.dev)
- [Starboard Porting Guide](starboard/README.md)
- [GBM API Documentation](https://www.freedesktop.org/wiki/Software/Mesa/GBM/)
- [DRM/KMS Documentation](https://www.kernel.org/doc/html/latest/gpu/drm-kms.html)

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.
