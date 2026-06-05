@echo off
setlocal

echo === LoveLink APK Builder ===
echo.

REM Check Flutter
where flutter >NUL 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter not found in PATH
    echo Run this script after extracting Flutter SDK and adding it to PATH
    exit /b 1
)

echo Flutter: OK
flutter --version | findstr "Flutter"

REM Setup Android SDK
set ANDROID_HOME=C:\Android
if not exist "%ANDROID_HOME%" (
    echo ERROR: Android SDK not found at C:\Android
    exit /b 1
)
echo Android SDK: OK

REM Create local.properties
echo Writing local.properties...
for %%F in ("%FLUTTER_HOME%") do set FLUTTER_PATH=%%~fF
if "%FLUTTER_PATH%"=="" for /f "delims=" %%i in ('where flutter') do set FLUTTER_PATH=%%~dpi..
echo sdk.dir=%ANDROID_HOME:\=\\% > flutter_app\android\local.properties
echo flutter.sdk=%FLUTTER_PATH:\=\\% >> flutter_app\android\local.properties
echo flutter.buildMode=release >> flutter_app\android\local.properties
echo flutter.versionName=1.0.0 >> flutter_app\android\local.properties
echo flutter.versionCode=1 >> flutter_app\android\local.properties

REM Accept Android licenses
echo Accepting Android SDK licenses...
echo y | "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --licenses --sdk_root="%ANDROID_HOME%" > NUL 2>&1

REM Install dependencies
echo.
echo Installing Flutter packages...
cd flutter_app
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: flutter pub get failed
    exit /b 1
)

REM Build APK
echo.
echo Building release APK...
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo === BUILD SUCCESS ===
echo APK location:
echo   flutter_app\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Copy this file to both phones and install it.

cd ..
endlocal
