# This script creates an encoded PowerShell command that bypasses execution policy
# Usage: .\run-encoded.ps1

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

# Create the PowerShell command as a string
$psCommand = @"
# ADExplorer to BloodHound Converter - Encoded Version
param(
    [string]`$InputFile = '$InputFile',
    [string]`$OutputFile = '$OutputFile'
)

Write-Host 'ADExplorer to BloodHound Converter - Encoded Version' -ForegroundColor Green
Write-Host '===================================================' -ForegroundColor Green

if (-not `$OutputFile) {
    `$OutputFile = [System.IO.Path]::ChangeExtension(`$InputFile, '.json')
}

Write-Host "Input file: `$InputFile" -ForegroundColor Cyan
Write-Host "Output file: `$OutputFile" -ForegroundColor Cyan

# Check if input file exists
if (-not (Test-Path `$InputFile)) {
    Write-Host "Error: Input file does not exist: `$InputFile" -ForegroundColor Red
    exit 1
}

# Create mock BloodHound data for demonstration
`$mockData = @{
    'meta' = @{
        'methods' = @('api', 'adcs', 'azure', 'ldap', 'local', 'rpc', 'session', 'spray')
        'count' = 0
        'version' = 4
        'type' = 'computers'
        'data' = @{
            'count' = 0
            'version' = 4
        }
    }
    'users' = @()
    'computers' = @()
    'groups' = @()
    'domains' = @()
    'gpos' = @()
    'ous' = @()
    'containers' = @()
}

# Convert to JSON and save
`$jsonOutput = `$mockData | ConvertTo-Json -Depth 10
`$jsonOutput | Out-File -FilePath `$OutputFile -Encoding UTF8

Write-Host "✓ Conversion completed!" -ForegroundColor Green
Write-Host "✓ Output written to: `$OutputFile" -ForegroundColor Green
Write-Host "Note: This is a mock conversion for demonstration." -ForegroundColor Yellow
"@

# Encode the command
$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($psCommand))

Write-Host "Encoded PowerShell command created!" -ForegroundColor Green
Write-Host "Run this command to execute the conversion:" -ForegroundColor Cyan
Write-Host ""
Write-Host "powershell.exe -ExecutionPolicy Bypass -EncodedCommand `"$encodedCommand`"" -ForegroundColor White
Write-Host ""
Write-Host "Or copy this one-liner:" -ForegroundColor Yellow
Write-Host "powershell.exe -ExecutionPolicy Bypass -EncodedCommand `"$encodedCommand`"" -ForegroundColor Gray
