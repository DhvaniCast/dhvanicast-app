#!/usr/bin/env pwsh
# LiveKit Voice Communication Test Script
# Run this to verify all fixes are in place

Write-Host "🔍 LiveKit Voice Communication - Verification Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Gray
Write-Host ""

$hasErrors = $false

# Check 1: Android Permissions
Write-Host "📱 Checking Android Permissions..." -ForegroundColor Yellow
$androidManifest = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $androidManifest) {
    $content = Get-Content $androidManifest -Raw
    
    $permissions = @(
        "BLUETOOTH",
        "BLUETOOTH_CONNECT", 
        "ACCESS_NETWORK_STATE",
        "CHANGE_NETWORK_STATE",
        "ACCESS_WIFI_STATE",
        "CHANGE_WIFI_STATE",
        "WAKE_LOCK",
        "FOREGROUND_SERVICE",
        "RECORD_AUDIO",
        "MODIFY_AUDIO_SETTINGS"
    )
    
    foreach ($permission in $permissions) {
        if ($content -match $permission) {
            Write-Host "   ✅ $permission" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $permission MISSING!" -ForegroundColor Red
            $hasErrors = $true
        }
    }
} else {
    Write-Host "   ❌ AndroidManifest.xml not found!" -ForegroundColor Red
    $hasErrors = $true
}

Write-Host ""

# Check 2: iOS Permissions
Write-Host "📱 Checking iOS Permissions..." -ForegroundColor Yellow
$iosInfoPlist = "ios\Runner\Info.plist"
if (Test-Path $iosInfoPlist) {
    $content = Get-Content $iosInfoPlist -Raw
    
    $iOSPermissions = @(
        "NSMicrophoneUsageDescription",
        "NSBluetoothAlwaysUsageDescription",
        "UIBackgroundModes"
    )
    
    foreach ($permission in $iOSPermissions) {
        if ($content -match $permission) {
            Write-Host "   ✅ $permission" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $permission MISSING!" -ForegroundColor Red
            $hasErrors = $true
        }
    }
} else {
    Write-Host "   ❌ Info.plist not found!" -ForegroundColor Red
    $hasErrors = $true
}

Write-Host ""

# Check 3: LiveKit Service Implementation
Write-Host "🎙️ Checking LiveKit Service..." -ForegroundColor Yellow
$livekitService = "lib\shared\services\livekit_service.dart"
if (Test-Path $livekitService) {
    $content = Get-Content $livekitService -Raw
    
    if ($content -match "_subscribeToParticipant") {
        Write-Host "   ✅ Participant subscription method" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Participant subscription MISSING!" -ForegroundColor Red
        $hasErrors = $true
    }
    
    if ($content -match "_subscribeToExistingParticipants") {
        Write-Host "   ✅ Existing participants check" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Existing participants check MISSING!" -ForegroundColor Red
        $hasErrors = $true
    }
    
    if ($content -match "adaptiveStream") {
        Write-Host "   ✅ Adaptive streaming" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Adaptive streaming not configured" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ livekit_service.dart not found!" -ForegroundColor Red
    $hasErrors = $true
}

Write-Host ""

# Check 4: Backend Configuration
Write-Host "🖥️ Checking Backend Configuration..." -ForegroundColor Yellow
$livekitConfig = "..\harborleaf_radio_backend\src\config\livekit.js"
if (Test-Path $livekitConfig) {
    $content = Get-Content $livekitConfig -Raw
    
    if ($content -match "canPublishSources") {
        Write-Host "   ✅ Token publish sources configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Token publish sources not found" -ForegroundColor Yellow
    }
    
    if ($content -match "audioEnabled") {
        Write-Host "   ✅ Room audio metadata configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Room audio metadata not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️ Backend livekit.js not found" -ForegroundColor Yellow
}

Write-Host ""

# Check 5: Backend Environment Variables
Write-Host "🔐 Checking Backend Environment..." -ForegroundColor Yellow
$backendEnv = "..\harborleaf_radio_backend\.env"
if (Test-Path $backendEnv) {
    $content = Get-Content $backendEnv -Raw
    
    if ($content -match "LIVEKIT_URL=.+") {
        Write-Host "   ✅ LIVEKIT_URL is set" -ForegroundColor Green
    } else {
        Write-Host "   ❌ LIVEKIT_URL NOT SET!" -ForegroundColor Red
        $hasErrors = $true
    }
    
    if ($content -match "LIVEKIT_API_KEY=.+") {
        Write-Host "   ✅ LIVEKIT_API_KEY is set" -ForegroundColor Green
    } else {
        Write-Host "   ❌ LIVEKIT_API_KEY NOT SET!" -ForegroundColor Red
        $hasErrors = $true
    }
    
    if ($content -match "LIVEKIT_API_SECRET=.+") {
        Write-Host "   ✅ LIVEKIT_API_SECRET is set" -ForegroundColor Green
    } else {
        Write-Host "   ❌ LIVEKIT_API_SECRET NOT SET!" -ForegroundColor Red
        $hasErrors = $true
    }
} else {
    Write-Host "   ❌ Backend .env not found!" -ForegroundColor Red
    $hasErrors = $true
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Gray

# Final Summary
if ($hasErrors) {
    Write-Host ""
    Write-Host "❌ VERIFICATION FAILED - Some fixes are missing!" -ForegroundColor Red
    Write-Host "   Please review the errors above." -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "✅ ALL CHECKS PASSED - Ready to test!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 Testing Instructions:" -ForegroundColor Cyan
    Write-Host "   1. Build app: flutter clean; flutter pub get; flutter run" -ForegroundColor White
    Write-Host "   2. Use 2 devices" -ForegroundColor White
    Write-Host "   3. Both join frequency 450" -ForegroundColor White
    Write-Host "   4. Test voice communication" -ForegroundColor White
    Write-Host ""
}

Write-Host "🚀 Done!" -ForegroundColor Cyan

