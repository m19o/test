# Quick conversion script - no module loading required
# Usage: .\quick-convert.ps1 -InputFile "adexplorer.dat" -OutputFile "bloodhound.json"

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

# Set default output file if not specified
if (-not $OutputFile) {
    $OutputFile = [System.IO.Path]::ChangeExtension($InputFile, ".json")
}

Write-Host "ADExplorer to BloodHound Quick Converter" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "Error: Input file does not exist: $InputFile" -ForegroundColor Red
    exit 1
}

Write-Host "Input file: $InputFile" -ForegroundColor Cyan
Write-Host "Output file: $OutputFile" -ForegroundColor Cyan

# Create a simple mock conversion for demonstration
# In a real implementation, you would parse the actual .dat file here

$mockBloodHoundData = @{
    "meta" = @{
        "methods" = @("api", "adcs", "azure", "ldap", "local", "rpc", "session", "spray")
        "count" = 0
        "version" = 4
        "type" = "computers"
        "data" = @{
            "count" = 0
            "version" = 4
        }
    }
    "users" = @()
    "computers" = @()
    "groups" = @()
    "domains" = @()
    "gpos" = @()
    "ous" = @()
    "containers" = @()
}

# Convert to JSON and save
$jsonOutput = $mockBloodHoundData | ConvertTo-Json -Depth 10
$jsonOutput | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "`n✓ Conversion completed!" -ForegroundColor Green
Write-Host "✓ Output written to: $OutputFile" -ForegroundColor Green
Write-Host "`nNote: This is a mock conversion. For full functionality, use the complete module." -ForegroundColor Yellow
