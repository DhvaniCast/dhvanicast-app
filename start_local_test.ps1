#!/usr/bin/env pwsh
# LiveKit Local Testing - Step by Step Guide

Write-Host "LiveKit Local Testing - Step by Step" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

# Check 1: Backend Server
Write-Host "1. Checking Backend Server..." -ForegroundColor Yellow
$backendRunning = $false
try {
    $netstat = netstat -ano | Select-String ":5000"
    if ($netstat) {
        Write-Host "   SUCCESS: Backend is running on port 5000" -ForegroundColor Green
        $backendRunning = $true
    } else {
        Write-Host "   ERROR: Backend NOT running on port 5000" -ForegroundColor Red
        Write-Host "   Start backend: cd harborleaf_radio_backend; npm start" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ERROR: Could not check backend" -ForegroundColor Red
}

Write-Host ""

# Check 2: Flutter Devices
Write-Host "2. Checking Flutter Devices..." -ForegroundColor Yellow
try {
    $devices = flutter devices 2>&1
    Write-Host "   Available devices:" -ForegroundColor Cyan
    Write-Host $devices
    
    if ($devices -match "No devices detected") {
        Write-Host "   ERROR: No devices connected!" -ForegroundColor Red
        Write-Host "   Connect a phone via USB or start an emulator" -ForegroundColor Yellow
    } else {
        Write-Host "   SUCCESS: Device detected" -ForegroundColor Green
    }
} catch {
    Write-Host "   ERROR: Could not check devices" -ForegroundColor Red
}

Write-Host ""

# Check 3: App Configuration
Write-Host "3. Checking App Configuration..." -ForegroundColor Yellow
$apiEndpoints = "lib\shared\constants\api_endpoints.dart"
if (Test-Path $apiEndpoints) {
    $content = Get-Content $apiEndpoints -Raw
    
    if ($content -match "Environment.local") {
        Write-Host "   SUCCESS: Environment set to LOCAL" -ForegroundColor Green
    } else {
        Write-Host "   WARNING: Environment NOT set to local" -ForegroundColor Yellow
    }
    
    if ($content -match "_useEmulator\s*=\s*true") {
        Write-Host "   INFO: Emulator mode ENABLED" -ForegroundColor Cyan
    } else {
        Write-Host "   INFO: Real device mode (using computer IP)" -ForegroundColor Cyan
    }
} else {
    Write-Host "   ERROR: api_endpoints.dart not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

if ($backendRunning) {
    Write-Host "SUCCESS: Ready to test!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Testing Steps:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Step 1: Run Flutter App" -ForegroundColor White
    Write-Host "   flutter run -v" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 2: Login on Device 1" -ForegroundColor White
    Write-Host "   Mobile: 9876543210" -ForegroundColor Gray
    Write-Host "   OTP: 100623" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 3: Join Frequency 450" -ForegroundColor White
    Write-Host "   Watch console for LiveKit connection logs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 4: Open Second Device" -ForegroundColor White
    Write-Host "   Login with: 9876543211" -ForegroundColor Gray
    Write-Host "   Join frequency: 450" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 5: Test Voice Communication" -ForegroundColor White
    Write-Host "   Speak on Device 1 - Should hear on Device 2" -ForegroundColor Gray
    Write-Host "   Speak on Device 2 - Should hear on Device 1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Watch for these logs:" -ForegroundColor Cyan
    Write-Host "   [LiveKit] Connected to room" -ForegroundColor Green
    Write-Host "   [LiveKit] Audio track published" -ForegroundColor Green
    Write-Host "   [LiveKit] Participant joined" -ForegroundColor Green
    Write-Host "   [LiveKit] Receiving audio from" -ForegroundColor Green
    Write-Host ""
    Write-Host "Full guide: LOCAL_TESTING_GUIDE.md" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "WARNING: Backend not running!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Start backend first:" -ForegroundColor White
    Write-Host "   cd ..\harborleaf_radio_backend" -ForegroundColor Gray
    Write-Host "   npm start" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Done!" -ForegroundColor Cyan
