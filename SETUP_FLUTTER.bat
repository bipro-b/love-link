@echo off
setlocal
echo === Flutter SDK Setup ===
echo.

set FLUTTER_ZIP=%USERPROFILE%\flutter_sdk.zip
set FLUTTER_DIR=C:\flutter

if not exist "%FLUTTER_ZIP%" (
    echo ERROR: Flutter SDK zip not found at %FLUTTER_ZIP%
    echo Download it from: https://docs.flutter.dev/get-started/install/windows
    exit /b 1
)

echo Checking zip file...
if exist "%FLUTTER_DIR%\bin\flutter.bat" (
    echo Flutter already extracted at %FLUTTER_DIR%
    goto addpath
)

echo Extracting Flutter SDK to C:\flutter (this takes a few minutes)...
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%FLUTTER_ZIP%', 'C:\')"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Extraction failed. The zip may be incomplete.
    exit /b 1
)

:addpath
echo Flutter extracted. Adding to system PATH...

REM Add Flutter to user PATH permanently
setx PATH "%FLUTTER_DIR%\bin;%PATH%" /M >NUL 2>&1
if %ERRORLEVEL% NEQ 0 (
    REM Try without /M (no admin needed)
    setx PATH "%FLUTTER_DIR%\bin;%PATH%" >NUL 2>&1
)

REM Set for current session
set PATH=%FLUTTER_DIR%\bin;%PATH%
set JAVA_HOME=C:\Program Files\Java\jdk-25
set ANDROID_HOME=C:\Android

echo Accepting Android SDK licenses...
echo y | "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --licenses --sdk_root="%ANDROID_HOME%" > NUL 2>&1

echo Running flutter doctor...
flutter doctor --android-licenses << y 2>&1 | head -10
flutter doctor

echo.
echo === Flutter is ready! ===
echo Now run BUILD.bat to build the APK
endlocal
