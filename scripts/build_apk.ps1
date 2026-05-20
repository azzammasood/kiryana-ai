# Build release APK with production API URL
# Usage: .\scripts\build_apk.ps1 -ApiUrl "https://kiryana-ai-api.onrender.com"

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl
)

$ErrorActionPreference = "Stop"
$Flutter = "C:\Users\LENOVO\flutter-sdk\bin\flutter.bat"
$Frontend = Join-Path $PSScriptRoot "..\kiryana-ai-frontend"

Push-Location $Frontend
& $Flutter pub get
& $Flutter build apk --release --dart-define=API_BASE_URL=$ApiUrl
Pop-Location

$apk = Join-Path $Frontend "build\app\outputs\flutter-apk\app-release.apk"
Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host $apk
