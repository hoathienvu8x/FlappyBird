@echo off
setlocal

:: Load environment variables from .env file if it exists
if exist ..\.env (
    for /f "tokens=*" %%i in ('type ..\.env') do (
        set %%i
    )
)

set PATH=%ANDROID_SDK_ROOT%\tools;%ANDROID_SDK_ROOT%\platform-tools;%PATH%

set ADB=%ANDROID_SDK_ROOT%\platform-tools\adb.exe

set APKNAME=FlappyBird
set ANDROIDVERSION=30
set ANDROIDTARGET=30

set KEYSTORE_PASSWORD=%KEYSTORE_PASSWORD%

echo Cleaning previous builds...
rmdir /s /q app\build

:: Backup original AndroidManifest.xml
copy app\src\main\AndroidManifest.xml app\src\main\AndroidManifest.xml.bak

:: Replace package name in AndroidManifest.xml
powershell -Command "(gc app\src\main\AndroidManifest.xml) -replace 'your.app.package.name', '%PACKAGE_NAME%' | Out-File -encoding UTF8 app\src\main\AndroidManifest.xml"

echo Creating build directories...
mkdir app\build\intermediates\ndk
mkdir app\build\outputs\apk

echo Building native code...
cd app\src\main
call %ANDROID_NDK_ROOT%\ndk-build
if %errorlevel% neq 0 (
    echo Error building native code!
    echo Error code: %errorlevel%
    exit /b %errorlevel%
)
cd ..\..\..

echo Creating empty APK...
%ANDROID_SDK_ROOT%\build-tools\%BUILD_TOOLS_VERSION%\aapt package -f -M app\src\main\AndroidManifest.xml -S app\src\main\res -A app\src\main\assets -I %ANDROID_SDK_ROOT%\platforms\android-%ANDROIDTARGET%\android.jar -F app\build\outputs\apk\unaligned.apk
if %errorlevel% neq 0 (
    echo Error creating empty APK!
    echo Error code: %errorlevel%
    exit /b %errorlevel%
)

mkdir lib

:: Copy files from libs to a temporary folder
xcopy "app\src\main\libs\*" "lib\" /E /I /Y

:: Add the contents of the temporary folder to the archive in the lib folder
start /min /wait WinRAR A -r app\build\outputs\apk\unaligned.apk "lib\*" "lib\"

echo Aligning APK...
%ANDROID_SDK_ROOT%\build-tools\%BUILD_TOOLS_VERSION%\zipalign -f 4 app\build\outputs\apk\unaligned.apk app\build\outputs\apk\%APKNAME%.apk
if %errorlevel% neq 0 (
    echo Error aligning APK!
    echo Error code: %errorlevel%
    exit /b %errorlevel%
)

echo Signing APK...
call %ANDROID_SDK_ROOT%\build-tools\%BUILD_TOOLS_VERSION%\apksigner sign --ks mykeystore.jks --ks-pass pass:%KEYSTORE_PASSWORD% --out app\build\outputs\apk\%APKNAME%-signed.apk app\build\outputs\apk\%APKNAME%.apk
if %errorlevel% neq 0 (
    echo Error signing APK!
    echo Error code: %errorlevel%
    exit /b %errorlevel%
)

:: Delete temporary folder
rmdir /S /Q lib

echo Deleting unnecessary files...
del /Q "app\build\outputs\apk\%APKNAME%.apk"
del /Q "app\build\outputs\apk\%APKNAME%-signed.apk.idsig"
del /Q "app\build\outputs\apk\unaligned.apk"

echo APK successfully created: app\build\outputs\apk\%APKNAME%-signed.apk

:: Debug moment
echo Clear logcat
%ADB% logcat -c
echo Installing APK
%ADB% install app\build\outputs\apk\%APKNAME%-signed.apk
start /min timeout.exe 1
echo Launching APK
%ADB% shell am start -n %PACKAGE_NAME%/android.app.NativeActivity
start /min timeout.exe 1
echo Starting logging
start %ADB% logcat -s flappy

:: Restore original AndroidManifest.xml
move /Y app\src\main\AndroidManifest.xml.bak app\src\main\AndroidManifest.xml

exit

endlocal