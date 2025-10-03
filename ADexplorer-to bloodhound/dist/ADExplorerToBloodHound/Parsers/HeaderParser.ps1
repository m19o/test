# HeaderParser - Parses ADExplorer .dat file headers
function Get-ADExplorerHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $reader = [System.IO.BinaryReader]::new($fileStream)
        
        # Read magic bytes to identify ADExplorer format
        $magicBytes = $reader.ReadBytes(4)
        $magicString = [System.Text.Encoding]::ASCII.GetString($magicBytes)
        
        if ($magicString -ne "ADEX") {
            throw "Invalid ADExplorer file format. Expected magic bytes 'ADEX'"
        }
        
        # Read version
        $version = $reader.ReadUInt32()
        
        # Read object count
        $objectCount = $reader.ReadUInt32()
        
        # Read timestamp
        $timestamp = $reader.ReadUInt64()
        $dateTime = [System.DateTime]::FromFileTime($timestamp)
        
        # Read additional header fields
        $headerSize = $reader.ReadUInt32()
        $dataOffset = $reader.ReadUInt32()
        
        $reader.Close()
        $fileStream.Close()
        
        return @{
            IsValid = $true
            Version = $version
            ObjectCount = $objectCount
            Timestamp = $dateTime
            HeaderSize = $headerSize
            DataOffset = $dataOffset
            MagicBytes = $magicString
        }
    }
    catch {
        Write-Error "Failed to parse ADExplorer header: $($_.Exception.Message)"
        return @{
            IsValid = $false
            Error = $_.Exception.Message
        }
    }
}

# Function to validate ADExplorer file format
function Test-ADExplorerFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $header = Get-ADExplorerHeader -FilePath $FilePath
        return $header.IsValid
    }
    catch {
        return $false
    }
}
