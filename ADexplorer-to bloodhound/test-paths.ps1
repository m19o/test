# Test path resolution for ADExplorer files
# This script helps debug path issues

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

Write-Host "Path Resolution Test" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

Write-Host "`nOriginal input: $InputFile" -ForegroundColor Cyan
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
Write-Host "Script directory: $PSScriptRoot" -ForegroundColor Gray

# Test different path resolution methods
Write-Host "`nPath Resolution Tests:" -ForegroundColor Yellow

# Method 1: Resolve-Path
try {
    $resolvedPath = Resolve-Path $InputFile -ErrorAction Stop
    Write-Host "✓ Resolve-Path: $($resolvedPath.Path)" -ForegroundColor Green
} catch {
    Write-Host "✗ Resolve-Path failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 2: Get-Item
try {
    $item = Get-Item $InputFile -ErrorAction Stop
    Write-Host "✓ Get-Item: $($item.FullName)" -ForegroundColor Green
} catch {
    Write-Host "✗ Get-Item failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 3: Test-Path
$testResult = Test-Path $InputFile
Write-Host "Test-Path result: $testResult" -ForegroundColor $(if($testResult) {"Green"} else {"Red"})

# Method 4: Check relative to script directory
if ($PSScriptRoot) {
    $scriptRelativePath = Join-Path $PSScriptRoot $InputFile
    $scriptTestResult = Test-Path $scriptRelativePath
    Write-Host "Script relative path: $scriptRelativePath" -ForegroundColor Gray
    Write-Host "Script relative test: $scriptTestResult" -ForegroundColor $(if($scriptTestResult) {"Green"} else {"Red"})
}

# Method 5: Check relative to current directory
$currentRelativePath = Join-Path (Get-Location) $InputFile
$currentTestResult = Test-Path $currentRelativePath
Write-Host "Current relative path: $currentRelativePath" -ForegroundColor Gray
Write-Host "Current relative test: $currentTestResult" -ForegroundColor $(if($currentTestResult) {"Green"} else {"Red"})

# List files in current directory
Write-Host "`nFiles in current directory:" -ForegroundColor Yellow
Get-ChildItem -Path "." -Name | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

# List files in parent directory
Write-Host "`nFiles in parent directory:" -ForegroundColor Yellow
if (Test-Path "..") {
    Get-ChildItem -Path ".." -Name | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

Write-Host "`nPath resolution test completed!" -ForegroundColor Green
