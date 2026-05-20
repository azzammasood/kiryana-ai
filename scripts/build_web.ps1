# Build Flutter web for Netlify / Cloudflare Pages
# Usage: .\scripts\build_web.ps1 -ApiUrl "https://kiryana-ai-api.onrender.com"

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl
)

$ErrorActionPreference = "Stop"
$Flutter = "C:\Users\LENOVO\flutter-sdk\bin\flutter.bat"
$Frontend = Join-Path $PSScriptRoot "..\kiryana-ai-frontend"

$ApiUrl = $ApiUrl.TrimEnd('/')
$configPath = Join-Path $Frontend "assets\config.json"
@{ apiBaseUrl = $ApiUrl } | ConvertTo-Json | Set-Content -Path $configPath -Encoding utf8
$envJsPath = Join-Path $Frontend "web\env.js"
"window.KIRYANA_API_BASE_URL = '$ApiUrl';" | Set-Content -Path $envJsPath -Encoding utf8

$indexPath = Join-Path $Frontend "web\index.html"
$indexHtml = Get-Content $indexPath -Raw
if ($indexHtml -match 'name="kiryana-api-base"') {
    $indexHtml = $indexHtml -replace 'name="kiryana-api-base" content="[^"]*"', "name=`"kiryana-api-base`" content=`"$ApiUrl`""
} else {
    $indexHtml = $indexHtml -replace '<meta name="description"', "<meta name=`"kiryana-api-base`" content=`"$ApiUrl`">`n  <meta name=`"description`""
}
Set-Content -Path $indexPath -Value $indexHtml -Encoding utf8 -NoNewline

Push-Location $Frontend
& $Flutter pub get
& $Flutter build web --release --dart-define=API_BASE_URL=$ApiUrl
Pop-Location

$out = Join-Path $Frontend "build\web"
Write-Host ""
Write-Host "Web build ready (deploy this folder):" -ForegroundColor Green
Write-Host $out
