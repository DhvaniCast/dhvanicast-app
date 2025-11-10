#!/usr/bin/env pwsh
# Simple Testing Script - Run This!

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LiveKit Voice Testing - Easy Way!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check backend
Write-Host "[1/4] Checking backend..." -ForegroundColor Yellow
$backend = netstat -ano | Select-String ":5000"
if ($backend) {
    Write-Host "      SUCCESS: Backend is running!" -ForegroundColor Green
} else {
    Write-Host "      ERROR: Backend not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "      Start backend in another terminal:" -ForegroundColor Yellow
    Write-Host "      cd c:\FlutterDev\project\Clone\harborleaf_radio_backend" -ForegroundColor White
    Write-Host "      npm start" -ForegroundColor White
    Write-Host ""
    exit
}

Write-Host ""

# Step 2: Check flutter
Write-Host "[2/4] Checking Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
    Write-Host "      SUCCESS: Flutter is ready!" -ForegroundColor Green
} catch {
    Write-Host "      ERROR: Flutter not found!" -ForegroundColor Red
    exit
}

Write-Host ""

# Step 3: Check devices
Write-Host "[3/4] Checking devices..." -ForegroundColor Yellow
$devices = flutter devices 2>&1
if ($devices -match "Chrome") {
    Write-Host "      SUCCESS: Chrome browser available!" -ForegroundColor Green
} else {
    Write-Host "      ERROR: No Chrome browser found!" -ForegroundColor Red
    exit
}

Write-Host ""

# Step 4: Ready to run
Write-Host "[4/4] Everything is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Ab kya karna hai:" -ForegroundColor Yellow
Write-Host ""

Write-Host "STEP 1: Ek window me ye command run karo:" -ForegroundColor Cyan
Write-Host "   flutter run -d chrome" -ForegroundColor White
Write-Host ""

Write-Host "STEP 2: Jab app load ho jaye:" -ForegroundColor Cyan
Write-Host "   - Login: 9876543210" -ForegroundColor White
Write-Host "   - OTP: 100623" -ForegroundColor White
Write-Host "   - Frequency join karo: 450" -ForegroundColor White
Write-Host ""

Write-Host "STEP 3: DUSRI terminal window kholo aur phir se:" -ForegroundColor Cyan
Write-Host "   flutter run -d chrome" -ForegroundColor White
Write-Host ""

Write-Host "STEP 4: Dusri window me:" -ForegroundColor Cyan
Write-Host "   - Login: 9876543211 (different number)" -ForegroundColor White
Write-Host "   - OTP: 100623" -ForegroundColor White
Write-Host "   - Frequency join karo: 450" -ForegroundColor White
Write-Host ""

Write-Host "STEP 5: Ab test karo:" -ForegroundColor Cyan
Write-Host "   - Window 1 me bolo" -ForegroundColor White
Write-Host "   - Window 2 me sunai dega!" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Kya aap abhi test start karna chahte ho? (Y/N): " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Host "Starting app in Chrome..." -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: Dusra terminal window khol kar phir se same command run karna!" -ForegroundColor Yellow
    Write-Host ""
    
    # Start the app
    flutter run -d chrome
} else {
    Write-Host ""
    Write-Host "OK! Jab ready ho tab ye command run karo:" -ForegroundColor Yellow
    Write-Host "   flutter run -d chrome" -ForegroundColor White
    Write-Host ""
}
