# GBM Build Architecture

This document explains the technical architecture of the GBM (Generic Buffer Management) build system for TizenTube Cobalt.

## Overview

The GBM build creates a version of Cobalt that runs directly on Linux framebuffer using DRM/KMS (Direct Rendering Manager / Kernel Mode Setting) instead of requiring X11 or Wayland. This makes it suitable for embedded systems, IoT devices, and headless environments.

## Key Features

- **No X11 Required**: Runs directly on DRM/KMS
- **Static Linking**: Minimal external dependencies
- **Multi-Architecture**: Supports x86_64 and ARM64
- **Lower Latency**: Direct GPU access without compositor overhead
- **Smaller Footprint**: Fewer dependencies and services

## Build Process

The `build_gbm.sh` script automates the entire build process:

1. **Dependency Check**: Verifies required tools are installed
2. **GN Installation**: Downloads GN if not available
3. **Environment Setup**: Configures build environment
4. **Configuration**: Generates GN build files with static linking
5. **Compilation**: Builds using Ninja with optimal parallelization
6. **Packaging**: Creates distribution tarballs

## Usage

See [QUICKSTART_GBM.md](../QUICKSTART_GBM.md) for quick start instructions and [BUILD_GBM.md](../BUILD_GBM.md) for detailed build documentation.

## Technical Details

### Current Implementation

The current build uses the existing `linux-x64x11` platform as a base but configures it for:
- Static linking of most dependencies
- GBM/DRM support (where available in shared code)
- Optimized builds with minimal external requirements

### Future Platform Structure

A dedicated GBM platform implementation would include:

```
starboard/linux/x64gbm/     # x86_64 GBM platform
starboard/linux/arm64gbm/   # ARM64 GBM platform
starboard/shared/gbm/       # Shared GBM code
```

This would replace X11-specific code with GBM-based window system implementations.

## Contributing

Contributions to improve GBM support are welcome. Areas for improvement:

1. Create dedicated GBM platform configurations
2. Implement GBM-based window system (replacing X11)
3. Optimize static linking further
4. Add more architecture support
5. Improve hardware compatibility testing

## License

Licensed under Apache License 2.0.
