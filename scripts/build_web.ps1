# Build Flutter web for Netlify / Cloudflare Pages
# Usage: .\scripts\build_web.ps1 -ApiUrl "https://kiryana-ai-api.onrender.com"

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl
)

$ErrorActionPreference = "Stop"
$Flutter = "C:\Users\LENOVO\flutter-sdk\bin\flutter.bat"
$Frontend = Join-Path $PSScriptRoot "..\kiryana-ai-frontend"

Push-Location $Frontend
& $Flutter pub get
& $Flutter build web --release --dart-define=API_BASE_URL=$ApiUrl
Pop-Location

$out = Join-Path $Frontend "build\web"
Write-Host ""
Write-Host "Web build ready (deploy this folder):" -ForegroundColor Green
Write-Host $out
