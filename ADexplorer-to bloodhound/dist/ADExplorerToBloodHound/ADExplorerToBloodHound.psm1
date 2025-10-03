# ADExplorer to BloodHound Converter Module
# Converts ADExplorer .dat files to BloodHound-compatible JSON format

# Import required classes and functions
. "$PSScriptRoot\Classes\ADObject.ps1"
. "$PSScriptRoot\Classes\BloodHoundOutput.ps1"
. "$PSScriptRoot\Parsers\HeaderParser.ps1"
. "$PSScriptRoot\Parsers\ObjectParser.ps1"
. "$PSScriptRoot\Output\BloodHoundJson.ps1"

# Main conversion function
function Convert-ADExplorerToBloodHound {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputFile,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Verbose,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDeleted,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ObjectTypes = @('User', 'Computer', 'Group', 'Domain', 'GPO', 'OU', 'Container')
    )
    
    begin {
        Write-Verbose "Starting ADExplorer to BloodHound conversion"
        
        # Validate input file
        if (-not (Test-Path $InputFile)) {
            throw "Input file does not exist: $InputFile"
        }
        
        # Set default output file if not specified
        if (-not $OutputFile) {
            $OutputFile = [System.IO.Path]::ChangeExtension($InputFile, ".json")
        }
        
        # Initialize BloodHound output structure
        $bloodHoundData = [BloodHoundOutput]::new()
    }
    
    process {
        try {
            Write-Verbose "Parsing ADExplorer file: $InputFile"
            
            # Parse the .dat file header
            $headerInfo = Get-ADExplorerHeader -FilePath $InputFile
            Write-Verbose "File version: $($headerInfo.Version), Object count: $($headerInfo.ObjectCount)"
            
            # Parse objects from the file
            $objects = Get-ADExplorerObjects -FilePath $InputFile -IncludeDeleted:$IncludeDeleted
            
            Write-Verbose "Parsed $($objects.Count) objects from file"
            
            # Convert to BloodHound format
            foreach ($object in $objects) {
                if ($object.ObjectType -in $ObjectTypes) {
                    $bloodHoundObject = ConvertTo-BloodHoundObject -ADObject $object
                    if ($bloodHoundObject) {
                        $bloodHoundData.AddObject($bloodHoundObject)
                    }
                }
            }
            
            # Generate relationships
            $relationships = Get-BloodHoundRelationships -Objects $objects
            foreach ($relationship in $relationships) {
                $bloodHoundData.AddRelationship($relationship)
            }
            
            # Output to JSON
            $jsonOutput = $bloodHoundData.ToJson()
            
            # Write to file
            $jsonOutput | Out-File -FilePath $OutputFile -Encoding UTF8
            Write-Verbose "Output written to: $OutputFile"
            
            return $jsonOutput
        }
        catch {
            Write-Error "Failed to convert ADExplorer file: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Conversion completed"
    }
}

# Function to get basic info about an ADExplorer file
function Get-ADExplorerInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        throw "File does not exist: $FilePath"
    }
    
    try {
        $headerInfo = Get-ADExplorerHeader -FilePath $FilePath
        return $headerInfo
    }
    catch {
        Write-Error "Failed to read ADExplorer file: $($_.Exception.Message)"
        throw
    }
}

# Function to test if a file is a valid ADExplorer .dat file
function Test-ADExplorerFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    try {
        $headerInfo = Get-ADExplorerHeader -FilePath $FilePath
        return $headerInfo.IsValid
    }
    catch {
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Convert-ADExplorerToBloodHound',
    'Get-ADExplorerInfo',
    'Test-ADExplorerFile'
)
