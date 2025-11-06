# 🧪 Audio Message Testing Script
# यह script audio messages को test करने के लिए है

Write-Host "🎤 ===== AUDIO MESSAGE TESTING GUIDE =====" -ForegroundColor Green
Write-Host ""

Write-Host "📱 Step 1: App Run करें" -ForegroundColor Cyan
Write-Host "Command: flutter run" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔍 Step 2: Logs Monitor करें" -ForegroundColor Cyan
Write-Host "New PowerShell window open करें और run करें:" -ForegroundColor Yellow
Write-Host "flutter logs | Select-String '🎤|📤|🔊|AUDIO|RECORD'" -ForegroundColor Yellow
Write-Host ""

Write-Host "✅ Step 3: Testing Checklist" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test 1: Recording Permission" -ForegroundColor White
Write-Host "  1. Communication screen खोलें" -ForegroundColor Gray
Write-Host "  2. PTT button को long press करें" -ForegroundColor Gray
Write-Host "  3. Permission dialog आना चाहिए" -ForegroundColor Gray
Write-Host "  4. Allow पर click करें" -ForegroundColor Gray
Write-Host "  Expected Log: ✅ Microphone permission granted" -ForegroundColor Green
Write-Host ""

Write-Host "Test 2: Audio Recording" -ForegroundColor White
Write-Host "  1. PTT button hold करें" -ForegroundColor Gray
Write-Host "  2. कुछ बोलें (5-10 seconds)" -ForegroundColor Gray
Write-Host "  3. Button release करें" -ForegroundColor Gray
Write-Host "  Expected Logs:" -ForegroundColor Green
Write-Host "    🎤 ===== START RECORDING =====" -ForegroundColor Green
Write-Host "    ✅ Recording started successfully" -ForegroundColor Green
Write-Host "    🎤 ===== STOP RECORDING =====" -ForegroundColor Green
Write-Host "    📁 Audio file path: /path/to/file.m4a" -ForegroundColor Green
Write-Host ""

Write-Host "Test 3: Audio Sending" -ForegroundColor White
Write-Host "  1. Recording stop होने के बाद automatic send होना चाहिए" -ForegroundColor Gray
Write-Host "  2. UI में green message bubble दिखना चाहिए" -ForegroundColor Gray
Write-Host "  Expected Logs:" -ForegroundColor Green
Write-Host "    📤 ===== SEND AUDIO MESSAGE =====" -ForegroundColor Green
Write-Host "    📂 File exists: true" -ForegroundColor Green
Write-Host "    🔐 Audio encoded to base64" -ForegroundColor Green
Write-Host "    ✅ Audio message sent to backend" -ForegroundColor Green
Write-Host ""

Write-Host "Test 4: Audio Playback" -ForegroundColor White
Write-Host "  1. Audio message पर tap करें" -ForegroundColor Gray
Write-Host "  2. Play icon pause में change होना चाहिए" -ForegroundColor Gray
Write-Host "  3. Audio play होना चाहिए" -ForegroundColor Gray
Write-Host "  Expected Logs:" -ForegroundColor Green
Write-Host "    🔊 ===== PLAY AUDIO MESSAGE =====" -ForegroundColor Green
Write-Host "    ✅ Playing from path/URL" -ForegroundColor Green
Write-Host ""

Write-Host "Test 5: Receiving Audio (2 devices required)" -ForegroundColor White
Write-Host "  1. दूसरे device से audio message भेजें" -ForegroundColor Gray
Write-Host "  2. First device पर gray message bubble दिखना चाहिए" -ForegroundColor Gray
Write-Host "  Expected Logs:" -ForegroundColor Green
Write-Host "    🎤 [FREQUENCY] Received audio message" -ForegroundColor Green
Write-Host ""

Write-Host "🐛 Troubleshooting" -ForegroundColor Cyan
Write-Host ""
Write-Host "Problem: Permission denied" -ForegroundColor Red
Write-Host "Solution: Settings > Apps > Your App > Permissions > Microphone = Allow" -ForegroundColor Yellow
Write-Host ""
Write-Host "Problem: Audio not sending" -ForegroundColor Red
Write-Host "Solution: Check WebSocket connection और backend server status" -ForegroundColor Yellow
Write-Host ""
Write-Host "Problem: Audio not playing" -ForegroundColor Red
Write-Host "Solution: Check device audio settings और file path" -ForegroundColor Yellow
Write-Host ""

Write-Host "📊 Useful Commands" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Run app with verbose logs" -ForegroundColor White
Write-Host "flutter run -v" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Watch logs in real-time" -ForegroundColor White
Write-Host "flutter logs" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Filter audio-related logs" -ForegroundColor White
Write-Host "flutter logs | Select-String '🎤|📤|🔊'" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Check device connection" -ForegroundColor White
Write-Host "flutter devices" -ForegroundColor Yellow
Write-Host ""

Write-Host "🎉 Ready to test! App run करें और PTT button try करें!" -ForegroundColor Green
Write-Host ""

# Prompt user to run app
$response = Read-Host "क्या आप अभी app run करना चाहते हैं? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "🚀 Starting Flutter app..." -ForegroundColor Green
    Set-Location "c:\FlutterDev\project\Clone\harborleaf_radio_app"
    flutter run
}
