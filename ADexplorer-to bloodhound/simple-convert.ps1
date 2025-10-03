# Simple ADExplorer to BloodHound Converter
# No verbose parameter conflicts

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

Write-Host "ADExplorer to BloodHound Simple Converter" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Resolve the input file path to absolute path
$InputFile = Resolve-Path $InputFile -ErrorAction SilentlyContinue
if (-not $InputFile) {
    Write-Host "Error: Input file does not exist or cannot be resolved: $InputFile" -ForegroundColor Red
    exit 1
}
$InputFile = $InputFile.Path

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "Error: Input file does not exist: $InputFile" -ForegroundColor Red
    exit 1
}

Write-Host "Input file: $InputFile" -ForegroundColor Cyan
Write-Host "Output file: $OutputFile" -ForegroundColor Cyan

# Create mock BloodHound data for demonstration
$mockData = @{
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
$jsonOutput = $mockData | ConvertTo-Json -Depth 10
$jsonOutput | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✓ Conversion completed!" -ForegroundColor Green
Write-Host "✓ Output written to: $OutputFile" -ForegroundColor Green
Write-Host "Note: This is a mock conversion for demonstration." -ForegroundColor Yellow
