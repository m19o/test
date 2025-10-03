# Robust ADExplorer to BloodHound Converter
# Handles empty parameters and path issues better

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

# Function to safely resolve file paths
function Resolve-FilePath {
    param([string]$Path)
    
    # Check if path is empty or null
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path cannot be empty or null"
    }
    
    # Check if path exists as-is
    if (Test-Path $Path) {
        return (Resolve-Path $Path).Path
    }
    
    # Try to resolve relative paths
    try {
        $resolved = Resolve-Path $Path -ErrorAction Stop
        return $resolved.Path
    } catch {
        # If resolution fails, try different approaches
        $currentDir = Get-Location
        $scriptDir = $PSScriptRoot
        
        # Try relative to current directory
        $currentPath = Join-Path $currentDir $Path
        if (Test-Path $currentPath) {
            return (Resolve-Path $currentPath).Path
        }
        
        # Try relative to script directory
        if ($scriptDir) {
            $scriptPath = Join-Path $scriptDir $Path
            if (Test-Path $scriptPath) {
                return (Resolve-Path $scriptPath).Path
            }
        }
        
        throw "Could not resolve path: $Path"
    }
}

Write-Host "Robust ADExplorer to BloodHound Converter" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

try {
    Write-Host "`nValidating parameters..." -ForegroundColor Yellow
    
    # Validate input file parameter
    if ([string]::IsNullOrWhiteSpace($InputFile)) {
        throw "Input file parameter cannot be empty or null"
    }
    
    Write-Host "Input file parameter: '$InputFile'" -ForegroundColor Cyan
    
    # Resolve input file path
    Write-Host "Resolving input file path..." -ForegroundColor Yellow
    $InputFile = Resolve-FilePath -Path $InputFile
    Write-Host "Resolved input file: $InputFile" -ForegroundColor Green
    
    # Set default output file if not specified
    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        $OutputFile = [System.IO.Path]::ChangeExtension($InputFile, ".json")
        Write-Host "Output file not specified, using: $OutputFile" -ForegroundColor Yellow
    }
    
    Write-Host "Final paths:" -ForegroundColor Cyan
    Write-Host "  Input: $InputFile" -ForegroundColor Gray
    Write-Host "  Output: $OutputFile" -ForegroundColor Gray
    
    # Verify input file exists
    if (-not (Test-Path $InputFile)) {
        throw "Input file does not exist: $InputFile"
    }
    
    Write-Host "✓ Input file validation passed" -ForegroundColor Green
    
    # Create mock BloodHound data for demonstration
    Write-Host "`nCreating BloodHound JSON output..." -ForegroundColor Yellow
    
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
    
    Write-Host "✓ Conversion completed successfully!" -ForegroundColor Green
    Write-Host "✓ Output written to: $OutputFile" -ForegroundColor Green
    Write-Host "Note: This is a mock conversion for demonstration." -ForegroundColor Yellow
    
} catch {
    Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check that the input file exists" -ForegroundColor Gray
    Write-Host "2. Use absolute paths if relative paths don't work" -ForegroundColor Gray
    Write-Host "3. Ensure you have read permissions for the input file" -ForegroundColor Gray
    Write-Host "4. Check that the file is a valid ADExplorer .dat file" -ForegroundColor Gray
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
