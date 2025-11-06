# PowerShell script to fix all import paths after folder restructuring

Write-Host "Starting import path fixes..." -ForegroundColor Green

# Get all Dart files in features and shared folders
$files = Get-ChildItem -Path "lib\features", "lib\shared" -Filter "*.dart" -Recurse -File

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Fix imports pointing to old structure
    # Change: import '../../data/models/' to '../../../../shared/data/models/'
    # Change: import '../../data/network/' to '../../../../shared/data/network/'
    # Change: import '../../data/local/' to '../../../../shared/data/local/'
    # Change: import '../../core/' to '../../../../shared/'
    # Change: import '../../../data/' to '../../../../shared/data/'
    # Change: import '../../../core/' to '../../../../shared/'
    
    # For files in features/*/data/repositories/
    if ($file.DirectoryName -like "*features*data*repositories*") {
        $content = $content -replace "import '../../core/constants/", "import '../../../../shared/constants/"
        $content = $content -replace "import '../../core/services/", "import '../../../../shared/services/"
        $content = $content -replace "import '../../data/models/", "import '../../data/models/"
    }
    
    # For files in features/*/presentation/screens/
    if ($file.DirectoryName -like "*features*presentation*screens*") {
        $content = $content -replace "import '../../../data/models/", "import '../../data/models/"
        $content = $content -replace "import '../../../data/network/", "import '../../../../../shared/data/network/"
        $content = $content -replace "import '../../../core/", "import '../../../../../shared/"
        $content = $content -replace "import '../../presentation/widgets/", "import '../../../../../shared/widgets/"
    }
    
    # For files in features/*/presentation/state/
    if ($file.DirectoryName -like "*features*presentation*state*") {
        $content = $content -replace "import '../../../data/repositories/", "import '../../data/repositories/"
        $content = $content -replace "import '../../../data/models/", "import '../../data/models/"
        $content = $content -replace "import '../../../core/services/", "import '../../../../../shared/services/"
        $content = $content -replace "import '../../../core/", "import '../../../../../shared/"
    }
    
    # Save only if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`nImport path fixes completed!" -ForegroundColor Green
