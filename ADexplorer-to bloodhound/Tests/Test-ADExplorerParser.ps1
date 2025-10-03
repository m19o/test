# Test suite for ADExplorer to BloodHound Converter

# Import the module
Import-Module .\ADExplorerToBloodHound.psd1

Write-Host "ADExplorer to BloodHound Converter - Test Suite" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Test 1: Module Import
Write-Host "`nTest 1: Module Import" -ForegroundColor Yellow
try {
    $module = Get-Module -Name "ADExplorerToBloodHound"
    if ($module) {
        Write-Host "✓ Module imported successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Module import failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Module import error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Function Availability
Write-Host "`nTest 2: Function Availability" -ForegroundColor Yellow
$requiredFunctions = @(
    "Convert-ADExplorerToBloodHound",
    "Get-ADExplorerInfo", 
    "Test-ADExplorerFile"
)

foreach ($function in $requiredFunctions) {
    if (Get-Command $function -ErrorAction SilentlyContinue) {
        Write-Host "✓ Function $function is available" -ForegroundColor Green
    } else {
        Write-Host "✗ Function $function is not available" -ForegroundColor Red
    }
}

# Test 3: Class Definitions
Write-Host "`nTest 3: Class Definitions" -ForegroundColor Yellow
try {
    $adObject = [ADObject]::new()
    Write-Host "✓ ADObject class is available" -ForegroundColor Green
    
    $bloodHoundOutput = [BloodHoundOutput]::new()
    Write-Host "✓ BloodHoundOutput class is available" -ForegroundColor Green
}
catch {
    Write-Host "✗ Class definition error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: ADObject Properties
Write-Host "`nTest 4: ADObject Properties" -ForegroundColor Yellow
try {
    $adObject = [ADObject]::new()
    $adObject.DistinguishedName = "CN=Test User,OU=Users,DC=example,DC=com"
    $adObject.ObjectType = "User"
    $adObject.SamAccountName = "testuser"
    $adObject.AddProperty("mail", "test@example.com")
    $adObject.AddMember("CN=Test Group,OU=Groups,DC=example,DC=com")
    
    if ($adObject.DistinguishedName -eq "CN=Test User,OU=Users,DC=example,DC=com") {
        Write-Host "✓ ADObject property setting works" -ForegroundColor Green
    } else {
        Write-Host "✗ ADObject property setting failed" -ForegroundColor Red
    }
    
    if ($adObject.HasProperty("mail")) {
        Write-Host "✓ ADObject property checking works" -ForegroundColor Green
    } else {
        Write-Host "✗ ADObject property checking failed" -ForegroundColor Red
    }
    
    if ($adObject.Members.Count -eq 1) {
        Write-Host "✓ ADObject member management works" -ForegroundColor Green
    } else {
        Write-Host "✗ ADObject member management failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ ADObject test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: BloodHoundOutput Structure
Write-Host "`nTest 5: BloodHoundOutput Structure" -ForegroundColor Yellow
try {
    $bloodHoundOutput = [BloodHoundOutput]::new()
    
    # Test adding objects
    $testUser = @{
        "ObjectIdentifier" = "S-1-5-21-1234567890-1234567890-1234567890-1001"
        "ObjectType" = "User"
        "Properties" = @{
            "name" = "testuser"
            "domain" = "example.com"
        }
    }
    
    $bloodHoundOutput.AddObject($testUser)
    
    if ($bloodHoundOutput.Users.Count -eq 1) {
        Write-Host "✓ BloodHoundOutput object addition works" -ForegroundColor Green
    } else {
        Write-Host "✗ BloodHoundOutput object addition failed" -ForegroundColor Red
    }
    
    # Test JSON output
    $jsonOutput = $bloodHoundOutput.ToJson()
    if ($jsonOutput -and $jsonOutput.Length -gt 0) {
        Write-Host "✓ BloodHoundOutput JSON generation works" -ForegroundColor Green
    } else {
        Write-Host "✗ BloodHoundOutput JSON generation failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ BloodHoundOutput test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: File Validation (Mock)
Write-Host "`nTest 6: File Validation (Mock)" -ForegroundColor Yellow
try {
    # Create a mock ADExplorer file for testing
    $mockFile = ".\mock_adexplorer.dat"
    $mockData = [System.Text.Encoding]::ASCII.GetBytes("ADEX") + [System.Text.Encoding]::ASCII.GetBytes("TEST")
    [System.IO.File]::WriteAllBytes($mockFile, $mockData)
    
    $isValid = Test-ADExplorerFile -FilePath $mockFile
    if ($isValid) {
        Write-Host "✓ File validation works (mock file detected as valid)" -ForegroundColor Green
    } else {
        Write-Host "✗ File validation failed" -ForegroundColor Red
    }
    
    # Clean up mock file
    Remove-Item $mockFile -ErrorAction SilentlyContinue
}
catch {
    Write-Host "✗ File validation test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 7: Error Handling
Write-Host "`nTest 7: Error Handling" -ForegroundColor Yellow
try {
    # Test with non-existent file
    $result = Test-ADExplorerFile -FilePath "nonexistent.dat"
    if (-not $result) {
        Write-Host "✓ Error handling for non-existent files works" -ForegroundColor Green
    } else {
        Write-Host "✗ Error handling for non-existent files failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "✓ Error handling works (exception caught)" -ForegroundColor Green
}

# Test Summary
Write-Host "`nTest Summary" -ForegroundColor Green
Write-Host "============" -ForegroundColor Green
Write-Host "All basic functionality tests completed." -ForegroundColor Gray
Write-Host "For comprehensive testing with real ADExplorer files, use the Examples/Example.ps1 script." -ForegroundColor Gray

Write-Host "`nTest suite completed!" -ForegroundColor Green
