# Makefile for building FlappyBird on macOS

# Load environment variables from .env file if it exists
include ../.env

# Set paths to your Android tools
ANDROID_HOME := $(ANDROID_SDK_ROOT)
ANDROID_SDK_ROOT := $(ANDROID_SDK_ROOT)
ANDROID_NDK_ROOT := $(ANDROID_NDK_ROOT)

# Tools
ADB := $(ANDROID_SDK_ROOT)/platform-tools/adb
NDK_BUILD := $(ANDROID_NDK_ROOT)/ndk-build
AAPT := $(ANDROID_SDK_ROOT)/build-tools/$(BUILD_TOOLS_VERSION)/aapt
ZIPALIGN := $(ANDROID_SDK_ROOT)/build-tools/$(BUILD_TOOLS_VERSION)/zipalign
APKSIGNER := $(ANDROID_SDK_ROOT)/build-tools/$(BUILD_TOOLS_VERSION)/apksigner

# Variables
APKNAME := FlappyBird
ANDROIDTARGET := 30
KEYSTORE_PASSWORD := $(KEYSTORE_PASSWORD)
PACKAGE_NAME := $(PACKAGE_NAME)
BUILD_TOOLS_VERSION := $(BUILD_TOOLS_VERSION)

# Directories
BUILD_DIR := app/build
INTERMEDIATES_DIR := $(BUILD_DIR)/intermediates
APK_DIR := $(BUILD_DIR)/outputs/apk
SRC_DIR := app/src/main
JNI_DIR := $(SRC_DIR)/jni
LIBS_DIR := $(SRC_DIR)/libs
ASSETS_DIR := $(SRC_DIR)/assets
RES_DIR := $(SRC_DIR)/res
MANIFEST := $(SRC_DIR)/AndroidManifest.xml

# Platform JAR
ANDROID_JAR := $(ANDROID_SDK_ROOT)/platforms/android-$(ANDROIDTARGET)/android.jar

.PHONY: all clean build-native build-apk sign-apk install run

all: $(APK_DIR)/$(APKNAME)-signed.apk

clean:
	rm -rf $(BUILD_DIR)

build-native:
	mkdir -p $(INTERMEDIATES_DIR)/ndk
	cd $(JNI_DIR) && $(NDK_BUILD)

$(APK_DIR)/$(APKNAME)-signed.apk: build-native
	mkdir -p $(APK_DIR)
	
	# Replace package name in AndroidManifest.xml
	sed -i.bak "s/your.app.package.name/$(PACKAGE_NAME)/g" $(MANIFEST)
	
	# Create empty APK (without native libraries)
	$(AAPT) package -f -M $(MANIFEST) -S $(RES_DIR) -A $(ASSETS_DIR) -I $(ANDROID_JAR) -F $(APK_DIR)/unaligned.apk
	
	# Add native libraries to the APK in the correct location
	# Create a temporary directory structure that mirrors the APK's lib structure
	mkdir -p $(INTERMEDIATES_DIR)/apk_add_libs/lib
	cp -r $(LIBS_DIR)/* $(INTERMEDIATES_DIR)/apk_add_libs/lib/ 2>/dev/null || echo "No libs to copy"
	# Check if the APK file exists and is not empty
	ls -l $(APK_DIR)/unaligned.apk || echo "APK file not found or empty"
	# Small delay to ensure file is written
	sleep 1
	# Use zip to add the libs to the APK (use absolute path for APK and ensure recursive add)
	cd $(INTERMEDIATES_DIR)/apk_add_libs && zip -r $(CURDIR)/$(APK_DIR)/unaligned.apk lib 2>/dev/null || echo "No libs to add"
	
	# Align APK
	$(ZIPALIGN) -f 4 $(APK_DIR)/unaligned.apk $(APK_DIR)/$(APKNAME).apk
	
	# Sign APK
	$(APKSIGNER) sign --ks mykeystore.jks --ks-pass pass:$(KEYSTORE_PASSWORD) --out $@ $(APK_DIR)/$(APKNAME).apk
	
	# Cleanup
	rm -rf $(INTERMEDIATES_DIR)/apk_add_libs
	rm -f $(APK_DIR)/$(APKNAME).apk
	rm -f $(APK_DIR)/$(APKNAME)-signed.apk.idsig
	rm -f $(APK_DIR)/unaligned.apk
	
	# Restore original AndroidManifest.xml
	mv $(MANIFEST).bak $(MANIFEST)

install: $(APK_DIR)/$(APKNAME)-signed.apk
	$(ADB) install $(APK_DIR)/$(APKNAME)-signed.apk

run: install
	$(ADB) shell am start -n $(PACKAGE_NAME)/android.app.NativeActivity

debug: run
	$(ADB) logcat -s flappy