$ErrorActionPreference = "SilentlyContinue"

Write-Host "Converting all imports to package imports..." -ForegroundColor Green

# Get all Dart files
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -File

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if (-not $content) { continue }
    
    $modified = $false
    $originalContent = $content
    
    # Convert relative imports to package imports
    # Pattern: import '../../...' to import 'package:harborleaf_radio_app/...'
    
    $content = $content -replace "import\s+'\.\./(\.\./)+(features/[^']+)'", "import 'package:harborleaf_radio_app/`$2'"
    $content = $content -replace "import\s+'\.\./(\.\./)+(shared/[^']+)'", "import 'package:harborleaf_radio_app/`$2'"
    $content = $content -replace "import\s+'injection\.dart'", "import 'package:harborleaf_radio_app/injection.dart'"
    $content = $content -replace "import\s+'\.\./(\.\./)*(injection\.dart)'", "import 'package:harborleaf_radio_app/injection.dart'"
    
    # For files inside features, convert local relative imports too
    if ($file.DirectoryName -like "*\features\*") {
        # Within same feature, keep relative but fix paths
        $relativePath = $file.FullName.Replace((Get-Location).Path + "\lib\", "").Replace("\", "/")
        $featureName = ($relativePath -split "/")[1]  # Get feature name (auth, radio, etc.)
        
        # Convert old-style imports to package imports
        $content = $content -replace "import\s+'\.\./(state/auth/[^']+)'", "import 'package:harborleaf_radio_app/features/auth/presentation/state/`$1'"
        $content = $content -replace "import\s+'\.\./(services/[^']+)'", "import 'package:harborleaf_radio_app/shared/services/`$1'"
    }
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fileName = Split-Path $file.FullName -Leaf
        Write-Host "  ✓ Fixed: $fileName" -ForegroundColor Yellow
        $modified = $true
    }
}

Write-Host "`n✓ Import conversion completed!" -ForegroundColor Green
Write-Host "Note: Some manual fixes may still be needed." -ForegroundColor Cyan
