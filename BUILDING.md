# FlappyBird Android Build Instructions

This document explains how to build the FlappyBird Android game on macOS, Linux, and Windows using either the provided shell script or Makefile.

## Prerequisites

Before building, you need to set up your environment variables:

1. Copy the `.env.example` file from the project root to `.env` in the project root:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file in the project root to match your local setup:

   Make sure to:
   - Update the paths to your Android SDK and NDK installations
   - Change the `PACKAGE_NAME` variable to match your desired package name for the app
   - Update the `BUILD_TOOLS_VERSION` variable to match the version of the Android build tools you have installed
   - Set a secure `KEYSTORE_PASSWORD`

The build system uses the Android command-line tools. You'll need to specify the path to your Android SDK and NDK in the `.env` file.

## Building with Shell Script

To build using the shell script:

```bash
cd FlappyBird
./build.sh
```

The signed APK will be generated at:
`app/build/outputs/apk/FlappyBird-signed.apk`

Note: The script will automatically install and run the app on a connected device.

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

To debug the app:
```bash
make debug
```

## Build Process Overview

1. **Native Code Compilation**: The NDK builds the C code into shared libraries for armeabi-v7a and arm64-v8a architectures
2. **APK Creation**: An empty APK is created with the manifest, resources, and assets
3. **Library Inclusion**: Native libraries are added to the APK in the correct location (`lib/<abi>/`)
4. **Alignment**: The APK is aligned for better performance
5. **Signing**: The APK is signed with the provided keystore
6. **Cleanup**: Temporary files are removed

## Troubleshooting

If you encounter issues:
1. Ensure all paths in the `.env` file are correct for your system
2. Verify that the Android tools are properly installed
3. Check that you have the required Android platform (android-30) and build tools (30.0.3)
4. Make sure your device is connected and recognized by adb (`adb devices`)
5. Ensure the keystore file `mykeystore.jks` exists in the FlappyBird directory or create one with:
   ```bash
   keytool -genkeypair -dname "cn=Mark Jones, ou=JavaSoft, o=Sun, c=US" -alias business -keypass your_password -keystore mykeystore.jks -storepass your_password -validity 20000
   ```
