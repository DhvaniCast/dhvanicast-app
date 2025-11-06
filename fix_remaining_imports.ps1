# 🔧 Import Fixer Script
# Run this if you encounter any import errors

Write-Host "🔍 Scanning for import issues..." -ForegroundColor Cyan

$rootPath = "lib"
$files = Get-ChildItem -Path $rootPath -Filter "*.dart" -Recurse -File
$fixCount = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if (-not $content) { continue }
    
    $originalContent = $content
    $modified = $false
    
    # Fix common import patterns
    $patterns = @{
        # Old presentation paths
        "import '\.\./(\.\./)*(presentation/screens/auth/[^']+)'" = "import 'package:harborleaf_radio_app/features/auth/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/radio/[^']+)'" = "import 'package:harborleaf_radio_app/features/radio/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/communication/[^']+)'" = "import 'package:harborleaf_radio_app/features/communication/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/dialer/[^']+)'" = "import 'package:harborleaf_radio_app/features/dialer/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/moderator/[^']+)'" = "import 'package:harborleaf_radio_app/features/moderation/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/profile/[^']+)'" = "import 'package:harborleaf_radio_app/features/profile/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/subscription/[^']+)'" = "import 'package:harborleaf_radio_app/features/subscription/presentation/screens/`$2'"
        "import '\.\./(\.\./)*(presentation/screens/home/[^']+)'" = "import 'package:harborleaf_radio_app/features/home/presentation/screens/`$2'"
        
        # Old data paths
        "import '\.\./(\.\./)*(data/models/[^']+)'" = "import 'package:harborleaf_radio_app/shared/data/models/`$2'"
        "import '\.\./(\.\./)*(data/network/[^']+)'" = "import 'package:harborleaf_radio_app/shared/data/network/`$2'"
        "import '\.\./(\.\./)*(data/local/[^']+)'" = "import 'package:harborleaf_radio_app/shared/data/local/`$2'"
        
        # Old core paths
        "import '\.\./(\.\./)*(core/constants/[^']+)'" = "import 'package:harborleaf_radio_app/shared/constants/`$2'"
        "import '\.\./(\.\./)*(core/services/[^']+)'" = "import 'package:harborleaf_radio_app/shared/services/`$2'"
        "import '\.\./(\.\./)*(core/utils/[^']+)'" = "import 'package:harborleaf_radio_app/shared/utils/`$2'"
        "import '\.\./(\.\./)*(core/theme/[^']+)'" = "import 'package:harborleaf_radio_app/shared/theme/`$2'"
        "import '\.\./(\.\./)*(core/widgets/[^']+)'" = "import 'package:harborleaf_radio_app/shared/widgets/`$2'"
        
        # Fix injection imports
        "import '\.\./injection\.dart'" = "import 'package:harborleaf_radio_app/injection.dart'"
        "import '\.\./(\.\./)*(injection\.dart)'" = "import 'package:harborleaf_radio_app/injection.dart'"
    }
    
    foreach ($pattern in $patterns.GetEnumerator()) {
        if ($content -match $pattern.Key) {
            $content = $content -replace $pattern.Key, $pattern.Value
            $modified = $true
        }
    }
    
    # Save if modified
    if ($modified -and $content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixCount++
        $fileName = Split-Path $file.FullName -Leaf
        Write-Host "  ✓ Fixed: $fileName" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($fixCount -gt 0) {
    Write-Host "✅ Fixed $fixCount file(s)!" -ForegroundColor Green
} else {
    Write-Host "✅ No import issues found!" -ForegroundColor Green
}

Write-Host ""
Write-Host "💡 Tip: Run 'flutter pub get' if you see package import errors" -ForegroundColor Cyan
Write-Host "💡 Tip: Run 'flutter analyze' to check for any remaining issues" -ForegroundColor Cyan
