# ADExplorer to BloodHound Converter - Usage Examples

# Import the module
Import-Module .\ADExplorerToBloodHound.psd1

Write-Host "ADExplorer to BloodHound Converter Examples" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Example 1: Basic file validation
Write-Host "`n1. Validating ADExplorer file..." -ForegroundColor Yellow
$testFile = "C:\path\to\your\adexplorer.dat"
if (Test-Path $testFile) {
    $isValid = Test-ADExplorerFile -FilePath $testFile
    Write-Host "File is valid ADExplorer format: $isValid" -ForegroundColor $(if($isValid) {"Green"} else {"Red"})
    
    if ($isValid) {
        $fileInfo = Get-ADExplorerInfo -FilePath $testFile
        Write-Host "File version: $($fileInfo.Version)"
        Write-Host "Object count: $($fileInfo.ObjectCount)"
        Write-Host "Timestamp: $($fileInfo.Timestamp)"
    }
}

# Example 2: Basic conversion
Write-Host "`n2. Basic conversion example..." -ForegroundColor Yellow
try {
    $outputFile = ".\bloodhound_output.json"
    $result = Convert-ADExplorerToBloodHound -InputFile $testFile -OutputFile $outputFile -Verbose
    Write-Host "Conversion completed successfully!" -ForegroundColor Green
    Write-Host "Output file: $outputFile"
}
catch {
    Write-Host "Conversion failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Example 3: Advanced conversion with options
Write-Host "`n3. Advanced conversion with options..." -ForegroundColor Yellow
try {
    $advancedOutput = ".\bloodhound_advanced.json"
    $result = Convert-ADExplorerToBloodHound -InputFile $testFile -OutputFile $advancedOutput -IncludeDeleted -ObjectTypes @("User", "Computer", "Group") -Verbose
    Write-Host "Advanced conversion completed!" -ForegroundColor Green
}
catch {
    Write-Host "Advanced conversion failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Example 4: Processing multiple files
Write-Host "`n4. Processing multiple files..." -ForegroundColor Yellow
$datFiles = Get-ChildItem -Path "C:\path\to\dat\files" -Filter "*.dat"
foreach ($file in $datFiles) {
    try {
        Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan
        $outputName = $file.BaseName + "_bloodhound.json"
        Convert-ADExplorerToBloodHound -InputFile $file.FullName -OutputFile $outputName
        Write-Host "Completed: $outputName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to process $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Example 5: Custom object filtering
Write-Host "`n5. Custom object filtering..." -ForegroundColor Yellow
try {
    # Only convert Users and Computers
    $filteredOutput = ".\bloodhound_filtered.json"
    $result = Convert-ADExplorerToBloodHound -InputFile $testFile -OutputFile $filteredOutput -ObjectTypes @("User", "Computer") -Verbose
    Write-Host "Filtered conversion completed!" -ForegroundColor Green
}
catch {
    Write-Host "Filtered conversion failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Example 6: Working with the output
Write-Host "`n6. Working with BloodHound output..." -ForegroundColor Yellow
if (Test-Path ".\bloodhound_output.json") {
    $bloodHoundData = Get-Content ".\bloodhound_output.json" | ConvertFrom-Json
    
    Write-Host "BloodHound Data Summary:" -ForegroundColor Cyan
    Write-Host "  Users: $($bloodHoundData.users.Count)"
    Write-Host "  Computers: $($bloodHoundData.computers.Count)"
    Write-Host "  Groups: $($bloodHoundData.groups.Count)"
    Write-Host "  Domains: $($bloodHoundData.domains.Count)"
    Write-Host "  GPOs: $($bloodHoundData.gpos.Count)"
    Write-Host "  OUs: $($bloodHoundData.ous.Count)"
    Write-Host "  Containers: $($bloodHoundData.containers.Count)"
    
    # Show sample user data
    if ($bloodHoundData.users.Count -gt 0) {
        Write-Host "`nSample User Data:" -ForegroundColor Cyan
        $sampleUser = $bloodHoundData.users[0]
        Write-Host "  Name: $($sampleUser.Properties.name)"
        Write-Host "  Domain: $($sampleUser.Properties.domain)"
        Write-Host "  Enabled: $($sampleUser.Properties.enabled)"
        Write-Host "  SPNs: $($sampleUser.Properties.spns -join ', ')"
    }
}

Write-Host "`nExamples completed!" -ForegroundColor Green
Write-Host "For more information, see the README.md file." -ForegroundColor Gray
