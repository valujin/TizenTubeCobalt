# GBM Build System for TizenTube Cobalt

This directory contains a complete build system for creating static GBM (Generic Buffer Management) versions of TizenTube Cobalt that can run on Linux systems without X11 or Wayland.

## 🎯 What is This?

The GBM build creates a version of Cobalt that:
- ✅ Runs directly on Linux framebuffer using DRM/KMS
- ✅ Does NOT require X11 or Wayland
- ✅ Has minimal external dependencies (mostly static linking)
- ✅ Supports both x86_64 and ARM64 architectures
- ✅ Works on embedded Linux, IoT devices, and headless systems
- ✅ Provides lower latency through direct GPU access

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `build_gbm.sh` | Main build script - does everything |
| `Makefile.gbm` | Convenient Make targets for building |
| `test_build_setup.sh` | Validates your build environment |
| `BUILD_GBM.md` | Detailed build documentation |
| `QUICKSTART_GBM.md` | Quick start guide |
| `docs/GBM_ARCHITECTURE.md` | Technical architecture details |
| `.github/workflows/gbm_build.yaml` | CI/CD automation |

## 🚀 Quick Start

### 1. Install Dependencies (Ubuntu/Debian)
```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential clang ninja-build python3 wget unzip \
    libasound2-dev libgles2-mesa-dev libgbm-dev libdrm-dev
```

Or use Make:
```bash
make -f Makefile.gbm deps
```

### 2. Validate Setup
```bash
./test_build_setup.sh
```

### 3. Build
```bash
# Build everything (both architectures)
./build_gbm.sh

# Or build just x86_64
./build_gbm.sh --arch x86_64

# Or use Make
make -f Makefile.gbm build
```

### 4. Run
```bash
./out/linux-x64gbm_gold/cobalt
```

## 📚 Documentation

- **[QUICKSTART_GBM.md](QUICKSTART_GBM.md)** - Start here if you're new
- **[BUILD_GBM.md](BUILD_GBM.md)** - Comprehensive build guide with all options
- **[docs/GBM_ARCHITECTURE.md](docs/GBM_ARCHITECTURE.md)** - Technical architecture details

## 🛠️ Build Options

The build script supports many options:

```bash
./build_gbm.sh [OPTIONS]

Options:
  --build-type TYPE     debug, devel, qa, or gold (default: gold)
  --arch ARCHS          x86_64, arm64, or "x86_64 arm64" (default: both)
  --output DIR          Custom output directory
  --jobs NUM            Parallel build jobs (default: all cores)
  --help                Show detailed help
```

### Examples

```bash
# Production build for x86_64
./build_gbm.sh --build-type gold --arch x86_64

# Debug build for ARM64
./build_gbm.sh --build-type debug --arch arm64

# Fast build using all CPU cores
./build_gbm.sh --jobs $(nproc)
```

## 🎮 Using Make

The Makefile provides convenient shortcuts:

```bash
# Show all available targets
make -f Makefile.gbm help

# Common targets
make -f Makefile.gbm build           # Build everything
make -f Makefile.gbm build-x64       # Build x86_64 only
make -f Makefile.gbm build-arm64     # Build ARM64 only
make -f Makefile.gbm build-debug     # Build debug version
make -f Makefile.gbm clean           # Clean build artifacts
make -f Makefile.gbm check-deps      # Verify dependencies
```

## 🤖 CI/CD

Automated builds are configured in `.github/workflows/gbm_build.yaml`:

- Builds on every push to main branch
- Can be manually triggered with custom options
- Builds both x86_64 and ARM64
- Uploads build artifacts
- Saves build logs for debugging

To manually trigger a build:
1. Go to Actions tab on GitHub
2. Select "GBM Build" workflow
3. Click "Run workflow"
4. Choose build type and architectures

## 📦 Output

After building, you'll find:

```
out/
├── linux-x64gbm_gold/
│   ├── cobalt              # The binary!
│   ├── content/            # Assets
│   └── *.log               # Build logs
├── linux-arm64gbm_gold/
│   └── (same structure)
└── *.tar.gz                # Distribution packages
```

## 🧪 Testing Your Setup

Before building, run the validation script:

```bash
./test_build_setup.sh
```

This checks:
- ✓ All required tools are installed
- ✓ Development libraries are available
- ✓ Repository structure is correct
- ✓ Sufficient disk space and memory
- ✓ DRM devices present (for runtime)

## 🔧 Troubleshooting

### Build Fails

1. **Check logs**: `cat out/linux-x64gbm_*/ninja.log`
2. **Verify dependencies**: `./test_build_setup.sh`
3. **Try with fewer jobs**: `./build_gbm.sh --jobs 4`
4. **Check disk space**: Need 50GB+ free

### Binary Won't Run

1. **Check DRM devices**: `ls -l /dev/dri/card*`
2. **Verify GPU drivers**: `lsmod | grep drm`
3. **Check EGL**: `ldconfig -p | grep libEGL`
4. **Permissions**: Add user to `video` group

See [BUILD_GBM.md](BUILD_GBM.md) for more troubleshooting help.

## 🎯 Build Types

| Type | Use Case | Binary Size | Optimizations |
|------|----------|-------------|---------------|
| **gold** | Production | ~150MB | Maximum |
| **qa** | QA testing | ~200MB | High |
| **devel** | Development | ~400MB | Medium |
| **debug** | Debugging | ~800MB | None |

Gold is recommended for production use.

## 💡 Key Features

### Static Linking
Most dependencies are statically linked:
- zlib, libpng, libjpeg
- libwebp, freetype, harfbuzz
- opus, vpx, dav1d codecs

Only system libraries remain dynamic:
- libc, libm, libpthread
- libEGL, libGLESv2, libgbm, libdrm
- libasound (optional)

### Multi-Architecture Support
- **x86_64**: Intel/AMD processors
- **ARM64**: ARM 64-bit processors (Raspberry Pi 4+, etc.)
- Cross-compilation supported

### Direct Rendering
- No X11 or Wayland compositor
- Direct DRM/KMS access
- Lower latency
- Smaller memory footprint

## 📊 Build Times

Approximate build times (gold build):

| Architecture | Typical Time | With ccache |
|--------------|--------------|-------------|
| x86_64 | 20-40 min | 5-10 min |
| ARM64 (native) | 20-40 min | 5-10 min |
| ARM64 (cross) | 30-60 min | 10-15 min |

Depends on CPU cores and disk speed.

## 🤝 Contributing

To improve the GBM build system:

1. Test on different hardware configurations
2. Optimize build scripts
3. Improve documentation
4. Add support for more architectures
5. Create dedicated GBM platform code

See [docs/GBM_ARCHITECTURE.md](docs/GBM_ARCHITECTURE.md) for technical details.

## 📋 System Requirements

### For Building
- **OS**: Linux (any modern distro)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 50GB+ free space
- **CPU**: Multi-core recommended

### For Running
- **OS**: Linux with DRM/KMS support
- **GPU**: Any with EGL support
- **RAM**: 2GB+ recommended
- **No X11/Wayland required!**

## 🔗 Links

- [Main README](README.md) - Project overview
- [Build Status](BUILD_STATUS.md) - Build status for all platforms
- [Contributing](CONTRIBUTING.md) - Contribution guidelines
- [License](LICENSE) - Apache License 2.0

## 📝 Notes

### Current Implementation

The current build uses the existing `linux-x64x11` platform as a base with GBM-oriented configuration. This works for building but uses X11 code paths at runtime.

### Future Enhancement

Creating dedicated `starboard/linux/x64gbm` and `starboard/linux/arm64gbm` platforms would:
- Replace X11 code with native GBM/DRM implementations
- Reduce binary size further
- Improve performance
- Enable GBM-specific features

See [docs/GBM_ARCHITECTURE.md](docs/GBM_ARCHITECTURE.md) for implementation details.

## ❓ FAQ

**Q: Does this work without a GUI?**
A: Yes! That's the point. It runs on Linux framebuffer without X11/Wayland.

**Q: Can I run this on a headless server?**
A: Yes, if the server has a GPU and DRM/KMS support.

**Q: Does it work on Raspberry Pi?**
A: Yes, on Pi 4+ with 64-bit OS. Build with `--arch arm64`.

**Q: Why not just use the X11 build?**
A: GBM build has lower latency, smaller footprint, and works without display server.

**Q: Can I cross-compile?**
A: Yes! See [BUILD_GBM.md](BUILD_GBM.md) for cross-compilation instructions.

**Q: What about Wayland support?**
A: Future enhancement. GBM works on framebuffer directly.

## 📄 License

Copyright 2024 The TizenTube Cobalt Authors

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
