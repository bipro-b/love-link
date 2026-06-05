# LoveLink APK Builder - PowerShell Script
# Run this after the Flutter download is complete

$ErrorActionPreference = "Stop"
$FlutterZip = "$env:USERPROFILE\flutter_sdk.zip"
$FlutterDir = "C:\flutter"
$AndroidHome = "C:\Android"
$ProjectDir = "D:\0.dev-bipro\android-app\lovelink\flutter_app"
$JavaHome = "C:\Program Files\Java\jdk-25"

Write-Host "=== LoveLink APK Builder ===" -ForegroundColor Cyan

# Step 1: Extract Flutter
if (-not (Test-Path "$FlutterDir\bin\flutter.bat")) {
    Write-Host "Extracting Flutter SDK..." -ForegroundColor Yellow
    if (-not (Test-Path $FlutterZip)) {
        Write-Host "ERROR: $FlutterZip not found" -ForegroundColor Red
        exit 1
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($FlutterZip, "C:\")
    Write-Host "Flutter extracted to $FlutterDir" -ForegroundColor Green
} else {
    Write-Host "Flutter already extracted: $FlutterDir" -ForegroundColor Green
}

# Step 2: Set environment
$env:PATH = "$FlutterDir\bin;$JavaHome\bin;$AndroidHome\cmdline-tools\latest\bin;$AndroidHome\platform-tools;$env:PATH"
$env:ANDROID_HOME = $AndroidHome
$env:JAVA_HOME = $JavaHome
$env:SKIP_JDK_VERSION_CHECK = "true"

Write-Host "Flutter version: $(flutter --version 2>&1 | Select-Object -First 1)" -ForegroundColor Green

# Step 3: Create local.properties
$localProps = @"
sdk.dir=$($AndroidHome -replace '\\', '\\\\')
flutter.sdk=$($FlutterDir -replace '\\', '\\\\')
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
"@
$localProps | Out-File -FilePath "$ProjectDir\android\local.properties" -Encoding utf8 -NoNewline
Write-Host "local.properties written" -ForegroundColor Green

# Step 4: Accept Android licenses
Write-Host "Accepting Android SDK licenses..." -ForegroundColor Yellow
$env:SKIP_JDK_VERSION_CHECK = "true"
echo "y`ny`ny`ny`ny`ny`n" | cmd /c "set JAVA_HOME=$JavaHome && set SKIP_JDK_VERSION_CHECK=true && $AndroidHome\cmdline-tools\latest\bin\sdkmanager.bat --licenses --sdk_root=$AndroidHome" 2>&1 | Out-Null

# Step 5: flutter pub get
Write-Host "Installing Flutter packages..." -ForegroundColor Yellow
Push-Location $ProjectDir
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter pub get failed" -ForegroundColor Red
    exit 1
}
Write-Host "Packages installed" -ForegroundColor Green

# Step 6: Build APK
Write-Host "Building release APK..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    exit 1
}

Pop-Location

$apkPath = "$ProjectDir\build\app\outputs\flutter-apk\app-release.apk"
$apkSize = [math]::Round((Get-Item $apkPath).Length/1MB, 1)

Write-Host ""
Write-Host "=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "APK: $apkPath" -ForegroundColor Cyan
Write-Host "Size: $apkSize MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy signaling_server/ to Railway.app" -ForegroundColor White
Write-Host "2. Install the APK on both phones" -ForegroundColor White
Write-Host "3. Enter server URL on first launch" -ForegroundColor White
Write-Host "4. Choose who you are (User 1 or User 2)" -ForegroundColor White
Write-Host "5. Call each other!" -ForegroundColor White
