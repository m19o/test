# Build script for ADExplorer to BloodHound Converter

param(
    [switch]$Clean,
    [switch]$Test,
    [switch]$Package
)

Write-Host "ADExplorer to BloodHound Converter - Build Script" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Clean build artifacts
if ($Clean) {
    Write-Host "`nCleaning build artifacts..." -ForegroundColor Yellow
    Remove-Item -Path ".\dist" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ".\*.zip" -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Clean completed" -ForegroundColor Green
}

# Create distribution directory
Write-Host "`nCreating distribution structure..." -ForegroundColor Yellow
$distDir = ".\dist\ADExplorerToBloodHound"
New-Item -Path $distDir -ItemType Directory -Force | Out-Null
New-Item -Path "$distDir\Classes" -ItemType Directory -Force | Out-Null
New-Item -Path "$distDir\Parsers" -ItemType Directory -Force | Out-Null
New-Item -Path "$distDir\Output" -ItemType Directory -Force | Out-Null
New-Item -Path "$distDir\Examples" -ItemType Directory -Force | Out-Null
New-Item -Path "$distDir\Tests" -ItemType Directory -Force | Out-Null
Write-Host "✓ Distribution structure created" -ForegroundColor Green

# Copy module files
Write-Host "`nCopying module files..." -ForegroundColor Yellow
Copy-Item -Path ".\ADExplorerToBloodHound.psd1" -Destination "$distDir\" -Force
Copy-Item -Path ".\ADExplorerToBloodHound.psm1" -Destination "$distDir\" -Force
Copy-Item -Path ".\Classes\*.ps1" -Destination "$distDir\Classes\" -Force
Copy-Item -Path ".\Parsers\*.ps1" -Destination "$distDir\Parsers\" -Force
Copy-Item -Path ".\Output\*.ps1" -Destination "$distDir\Output\" -Force
Copy-Item -Path ".\Examples\*.ps1" -Destination "$distDir\Examples\" -Force
Copy-Item -Path ".\Tests\*.ps1" -Destination "$distDir\Tests\" -Force
Copy-Item -Path ".\README.md" -Destination "$distDir\" -Force
Write-Host "✓ Module files copied" -ForegroundColor Green

# Run tests if requested
if ($Test) {
    Write-Host "`nRunning tests..." -ForegroundColor Yellow
    try {
        Set-Location $distDir
        .\Tests\Test-ADExplorerParser.ps1
        Set-Location "..\.."
        Write-Host "✓ Tests completed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Tests failed: $($_.Exception.Message)" -ForegroundColor Red
        Set-Location "..\.."
    }
}

# Create package if requested
if ($Package) {
    Write-Host "`nCreating package..." -ForegroundColor Yellow
    $packageName = "ADExplorerToBloodHound-v1.0.0.zip"
    $packagePath = ".\$packageName"
    
    # Remove existing package
    if (Test-Path $packagePath) {
        Remove-Item $packagePath -Force
    }
    
    # Create ZIP package
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($distDir, $packagePath)
    
    Write-Host "✓ Package created: $packageName" -ForegroundColor Green
    Write-Host "  Package size: $((Get-Item $packagePath).Length / 1KB) KB" -ForegroundColor Gray
}

# Build summary
Write-Host "`nBuild Summary" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green
Write-Host "Distribution directory: $distDir" -ForegroundColor Gray
Write-Host "Module files: $(Get-ChildItem $distDir -Recurse -File | Measure-Object).Count" -ForegroundColor Gray

if ($Package) {
    Write-Host "Package: $packageName" -ForegroundColor Gray
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
