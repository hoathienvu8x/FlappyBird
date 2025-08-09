# FlappyBird Android Build Instructions

This document explains how to build the FlappyBird Android game on macOS using either the provided shell script or Makefile.

## Prerequisites

Before building, you need to set up your environment variables:

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file to match your local setup:
   ```bash
   nano .env
   ```

   Make sure to update the `PACKAGE_NAME` variable to match your desired package name for the app and the `BUILD_TOOLS_VERSION` variable to match the version of the Android build tools you have installed.

The build system uses the Android command-line tools. You'll need to specify the path to your Android SDK and NDK in the `.env` file.

## Building with Shell Script

To build using the shell script:

```bash
cd FlappyBird
./build-local.sh
```

The signed APK will be generated at:
`app/build/outputs/apk/FlappyBird-signed.apk`

## Building with Makefile

To build using the Makefile:

```bash
cd FlappyBird
make
```

To clean the build:
```bash
make clean
```

To install and run on a connected device:
```bash
make install
# or to also start the app:
make run
```

## Build Process Overview

1. **Native Code Compilation**: The NDK builds the C code into shared libraries for armeabi-v7a and arm64-v8a architectures
2. **APK Creation**: An empty APK is created with the manifest, resources, and assets
3. **Library Inclusion**: Native libraries are added to the APK
4. **Alignment**: The APK is aligned for better performance
5. **Signing**: The APK is signed with the provided keystore
6. **Cleanup**: Temporary files are removed

## Troubleshooting

If you encounter issues:
1. Ensure all paths in `build-local.sh` or `Makefile` match your actual installation
2. Verify that the Android tools are properly installed
3. Check that you have the required Android platform (android-30) and build tools (30.0.3)