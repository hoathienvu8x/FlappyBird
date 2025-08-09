#! /bin/bash

# Load environment variables from .env file if it exists
if [ -f "../.env" ]; then
    export $(cat ../.env | xargs)
fi

export PATH=$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools:$PATH

export ADB=$ANDROID_SDK_ROOT/platform-tools/adb

export APKNAME=FlappyBird
export ANDROIDVERSION=34
export ANDROIDTARGET=34

export KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD

echo Cleaning previous builds...
rm -r app/build

# Replace package name in AndroidManifest.xml
sed -i.bak "s/your.app.package.name/$PACKAGE_NAME/g" app/src/main/AndroidManifest.xml

echo Creating build directories...
mkdir -p app/build/intermediates/ndk
mkdir -p app/build/outputs/apk

echo Building native code...
cd app/src/main
$ANDROID_NDK_ROOT/ndk-build
ret_code=$?
if [ $ret_code != 0 ]; then     
    echo Error building native code!
    echo Error code: $ret_code
    exit $ret_code
fi
cd ../../..

echo Creating empty APK...
$ANDROID_SDK_ROOT/build-tools/$BUILD_TOOLS_VERSION/aapt package -f -M app/src/main/AndroidManifest.xml -S app/src/main/res -A app/src/main/assets -I $ANDROID_SDK_ROOT/platforms/android-$ANDROIDTARGET/android.jar -F app/build/outputs/apk/unaligned.apk
ret_code=$?
if [ $ret_code != 0 ]; then     
    echo Error creating empty APK!
    echo Error code: $ret_code
    exit $ret_code
fi

mkdir lib

echo Copy files from libs to a temporary folder
cp app/src/main/libs/* lib/ -R

echo Add the contents of the temporary folder to the archive in the lib folder
zip app/build/outputs/apk/unaligned.apk -r  lib/* lib/

echo Aligning APK...
$ANDROID_SDK_ROOT/build-tools/$BUILD_TOOLS_VERSION/zipalign -f 4 app/build/outputs/apk/unaligned.apk app/build/outputs/apk/$APKNAME.apk
ret_code=$?
if [ $ret_code != 0 ]; then     
    echo Error aligning APK!
    echo Error code: $ret_code
    exit $ret_code
fi

# create a keystore if needed
if [ 0 ]; then
echo y | $JAVA_HOME/bin/keytool -genkeypair \
  -dname "cn=Mark Jones, ou=JavaSoft, o=Sun, c=US" \
  -alias business \
  -keypass $KEYSTORE_PASSWORD \
  -keystore mykeystore.jks \
  -storepass $KEYSTORE_PASSWORD \
  -validity 20000
fi

echo Signing APK...
$ANDROID_SDK_ROOT/build-tools/$BUILD_TOOLS_VERSION/apksigner sign --ks mykeystore.jks --ks-pass pass:$KEYSTORE_PASSWORD --out app/build/outputs/apk/$APKNAME-signed.apk app/build/outputs/apk/$APKNAME.apk
ret_code=$?
if [ $ret_code != 0 ]; then     
    echo Error signing APK!
    echo Error code: $ret_code
    exit $ret_code
fi

echo Delete temporary folder
rm -r lib

echo Deleting unnecessary files...
rm app/build/outputs/apk/$APKNAME.apk
rm app/build/outputs/apk/$APKNAME-signed.apk.idsig
rm app/build/outputs/apk/unaligned.apk

# Restore original AndroidManifest.xml
mv app/src/main/AndroidManifest.xml.bak app/src/main/AndroidManifest.xml

echo APK successfully created: app/build/outputs/apk/$APKNAME-signed.apk

echo Debug moment
echo Clear logcat
$ADB logcat -c
echo Installing APK
$ADB install app/build/outputs/apk/$APKNAME-signed.apk
echo Launching APK
$ADB shell am start -n $PACKAGE_NAME/android.app.NativeActivity
echo Starting logging
$ADB logcat -s flappy

exit
