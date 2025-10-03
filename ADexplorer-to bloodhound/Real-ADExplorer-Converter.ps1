# Real ADExplorer to BloodHound Converter
# Based on the actual ADExplorer file structure from the working Python parser

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

Write-Host "Real ADExplorer to BloodHound Converter" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# ADSTYPE constants from the Python parser
$ADSTYPE_INVALID = 0
$ADSTYPE_DN_STRING = 1
$ADSTYPE_CASE_EXACT_STRING = 2
$ADSTYPE_CASE_IGNORE_STRING = 3
$ADSTYPE_PRINTABLE_STRING = 4
$ADSTYPE_NUMERIC_STRING = 5
$ADSTYPE_BOOLEAN = 6
$ADSTYPE_INTEGER = 7
$ADSTYPE_OCTET_STRING = 8
$ADSTYPE_UTC_TIME = 9
$ADSTYPE_LARGE_INTEGER = 10
$ADSTYPE_PROV_SPECIFIC = 11
$ADSTYPE_OBJECT_CLASS = 12
$ADSTYPE_CASEIGNORE_LIST = 13
$ADSTYPE_OCTET_LIST = 14
$ADSTYPE_PATH = 15
$ADSTYPE_POSTALADDRESS = 16
$ADSTYPE_TIMESTAMP = 17
$ADSTYPE_BACKLINK = 18
$ADSTYPE_TYPEDNAME = 19
$ADSTYPE_HOLD = 20
$ADSTYPE_NETADDRESS = 21
$ADSTYPE_REPLICAPOINTER = 22
$ADSTYPE_FAXNUMBER = 23
$ADSTYPE_EMAIL = 24
$ADSTYPE_NT_SECURITY_DESCRIPTOR = 25
$ADSTYPE_UNKNOWN = 26
$ADSTYPE_DN_WITH_BINARY = 27
$ADSTYPE_DN_WITH_STRING = 28

# Helper function to convert Windows timestamp to Unix timestamp
function Convert-WinTimestampToUnix {
    param([long]$winTimestamp)
    # Windows timestamp is 100-nanosecond intervals since 1601-01-01
    # Unix timestamp is seconds since 1970-01-01
    $unixEpoch = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
    $winEpoch = [DateTime]::new(1601, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
    $ticks = $winTimestamp / 10000000
    $dateTime = $winEpoch.AddTicks($ticks)
    return [long]($dateTime - $unixEpoch).TotalSeconds
}

# Helper function to read UTF-16 string
function Read-UTF16String {
    param(
        [System.IO.BinaryReader]$Reader,
        [int]$Length
    )
    if ($Length -eq 0) { return "" }
    $bytes = $Reader.ReadBytes($Length)
    return [System.Text.Encoding]::Unicode.GetString($bytes).TrimEnd([char]0)
}

# Helper function to read UTF-8 string
function Read-UTF8String {
    param(
        [System.IO.BinaryReader]$Reader,
        [int]$Length
    )
    if ($Length -eq 0) { return "" }
    $bytes = $Reader.ReadBytes($Length)
    return [System.Text.Encoding]::UTF8.GetString($bytes).TrimEnd([char]0)
}

# Parse ADExplorer header
function Parse-ADExplorerHeader {
    param([System.IO.BinaryReader]$Reader)
    
    $header = @{}
    
    # Read winAdSig (10 bytes)
    $header.winAdSig = [System.Text.Encoding]::ASCII.GetString($Reader.ReadBytes(10))
    
    # Read marker (4 bytes)
    $header.marker = $Reader.ReadInt32()
    
    # Read filetime (8 bytes)
    $header.filetime = $Reader.ReadUInt64()
    $header.filetimeUnix = Convert-WinTimestampToUnix -winTimestamp $header.filetime
    
    # Read optionalDescription (260 * 2 bytes for UTF-16)
    $header.optionalDescription = Read-UTF16String -Reader $Reader -Length 520
    
    # Read server (260 * 2 bytes for UTF-16)
    $header.server = Read-UTF16String -Reader $Reader -Length 520
    
    # Read numObjects (4 bytes)
    $header.numObjects = $Reader.ReadUInt32()
    
    # Read numAttributes (4 bytes)
    $header.numAttributes = $Reader.ReadUInt32()
    
    # Read fileoffsetLow (4 bytes)
    $header.fileoffsetLow = $Reader.ReadUInt32()
    
    # Read fileoffsetHigh (4 bytes)
    $header.fileoffsetHigh = $Reader.ReadUInt32()
    
    # Read fileoffsetEnd (4 bytes)
    $header.fileoffsetEnd = $Reader.ReadUInt32()
    
    # Read unk0x43a (4 bytes)
    $header.unk0x43a = $Reader.ReadInt32()
    
    # Calculate mapping offset
    $header.mappingOffset = ($header.fileoffsetHigh -shl 32) -bor $header.fileoffsetLow
    
    return $header
}

# Parse properties
function Parse-Properties {
    param(
        [System.IO.BinaryReader]$Reader,
        [int]$numProperties
    )
    
    $properties = @()
    $propertyDict = @{}
    
    for ($i = 0; $i -lt $numProperties; $i++) {
        $prop = @{}
        
        # Read lenPropName (4 bytes)
        $lenPropName = $Reader.ReadUInt32()
        
        # Read propName (UTF-16 string)
        $prop.propName = Read-UTF16String -Reader $Reader -Length $lenPropName
        
        # Read unk1 (4 bytes)
        $prop.unk1 = $Reader.ReadInt32()
        
        # Read adsType (4 bytes)
        $prop.adsType = $Reader.ReadUInt32()
        
        # Read lenDN (4 bytes)
        $lenDN = $Reader.ReadUInt32()
        
        # Read DN (UTF-16 string)
        $prop.DN = Read-UTF16String -Reader $Reader -Length $lenDN
        
        # Read schemaIDGUID (16 bytes)
        $prop.schemaIDGUID = $Reader.ReadBytes(16)
        
        # Read attributeSecurityGUID (16 bytes)
        $prop.attributeSecurityGUID = $Reader.ReadBytes(16)
        
        # Read blob (4 bytes)
        $prop.blob = $Reader.ReadBytes(4)
        
        $properties += $prop
        
        # Add to dictionary for quick lookup
        $propertyDict[$prop.propName] = $i
        $propertyDict[$prop.DN] = $i
        if ($prop.DN -match '^CN=([^,]+),') {
            $propertyDict[$matches[1]] = $i
        }
    }
    
    return @{
        Properties = $properties
        PropertyDict = $propertyDict
    }
}

# Parse object offsets
function Parse-ObjectOffsets {
    param(
        [System.IO.BinaryReader]$Reader,
        [int]$numObjects
    )
    
    $objectOffsets = @()
    
    for ($i = 0; $i -lt $numObjects; $i++) {
        $pos = $Reader.BaseStream.Position
        $objSize = $Reader.ReadUInt32()
        $objectOffsets += $pos
        $Reader.BaseStream.Seek($pos + $objSize, [System.IO.SeekOrigin]::Begin)
    }
    
    return $objectOffsets
}

# Parse individual object
function Parse-Object {
    param(
        [System.IO.BinaryReader]$Reader,
        [array]$properties,
        [hashtable]$propertyDict
    )
    
    $obj = @{}
    
    # Read objSize (4 bytes)
    $obj.objSize = $Reader.ReadUInt32()
    
    # Read tableSize (4 bytes)
    $obj.tableSize = $Reader.ReadUInt32()
    
    # Read mapping table
    $obj.mappingTable = @()
    for ($i = 0; $i -lt $obj.tableSize; $i++) {
        $mapping = @{}
        $mapping.attrIndex = $Reader.ReadUInt32()
        $mapping.attrOffset = $Reader.ReadInt32()
        $obj.mappingTable += $mapping
    }
    
    # Calculate file offset
    $obj.fileOffset = $Reader.BaseStream.Position - 4 - 4 - ($obj.tableSize * 8)
    
    # Move to next object
    $Reader.BaseStream.Seek($obj.fileOffset + $obj.objSize, [System.IO.SeekOrigin]::Begin)
    
    # Parse attributes
    $obj.attributes = Parse-ObjectAttributes -Reader $Reader -Object $obj -Properties $properties -PropertyDict $propertyDict
    
    return $obj
}

# Parse object attributes
function Parse-ObjectAttributes {
    param(
        [System.IO.BinaryReader]$Reader,
        [hashtable]$Object,
        [array]$Properties,
        [hashtable]$PropertyDict
    )
    
    $attributes = @{}
    
    foreach ($mapping in $Object.mappingTable) {
        $prop = $Properties[$mapping.attrIndex]
        $attrName = $prop.propName.ToLower()
        $attrType = $prop.adsType
        
        # Seek to attribute offset
        $fileAttrOffset = $Object.fileOffset + $mapping.attrOffset
        $Reader.BaseStream.Seek($fileAttrOffset, [System.IO.SeekOrigin]::Begin)
        
        # Read number of values
        $numValues = $Reader.ReadUInt32()
        $values = @()
        
        # Process based on attribute type
        switch ($attrType) {
            { $_ -in @($ADSTYPE_DN_STRING, $ADSTYPE_CASE_IGNORE_STRING, $ADSTYPE_PRINTABLE_STRING, $ADSTYPE_NUMERIC_STRING, $ADSTYPE_OBJECT_CLASS) } {
                # Read offsets for each value
                $offsets = @()
                for ($v = 0; $v -lt $numValues; $v++) {
                    $offsets += $Reader.ReadUInt32()
                }
                
                # Read each value
                for ($v = 0; $v -lt $numValues; $v++) {
                    $Reader.BaseStream.Seek($fileAttrOffset + $offsets[$v], [System.IO.SeekOrigin]::Begin)
                    $val = Read-UTF16String -Reader $Reader -Length 0
                    $values += $val
                }
            }
            $ADSTYPE_OCTET_STRING {
                # Read lengths for each value
                $lengths = @()
                for ($v = 0; $v -lt $numValues; $v++) {
                    $lengths += $Reader.ReadUInt32()
                }
                
                # Read each value
                for ($v = 0; $v -lt $numValues; $v++) {
                    $val = $Reader.ReadBytes($lengths[$v])
                    if ($attrName -eq 'objectsid' -and $val.Length -eq 28) {
                        # Convert SID to string format
                        $val = Convert-SidToString -sidBytes $val
                    }
                    $values += $val
                }
            }
            $ADSTYPE_BOOLEAN {
                for ($v = 0; $v -lt $numValues; $v++) {
                    $val = [bool]$Reader.ReadUInt32()
                    $values += $val
                }
            }
            $ADSTYPE_INTEGER {
                for ($v = 0; $v -lt $numValues; $v++) {
                    $val = $Reader.ReadUInt32()
                    $values += $val
                }
            }
            $ADSTYPE_LARGE_INTEGER {
                for ($v = 0; $v -lt $numValues; $v++) {
                    $val = $Reader.ReadInt64()
                    $values += $val
                }
            }
            $ADSTYPE_UTC_TIME {
                for ($v = 0; $v -lt $numValues; $v++) {
                    # Read SystemTime structure
                    $year = $Reader.ReadUInt16()
                    $month = $Reader.ReadUInt16()
                    $dayOfWeek = $Reader.ReadUInt16()
                    $day = $Reader.ReadUInt16()
                    $hour = $Reader.ReadUInt16()
                    $minute = $Reader.ReadUInt16()
                    $second = $Reader.ReadUInt16()
                    $milliseconds = $Reader.ReadUInt16()
                    
                    $dateTime = [DateTime]::new($year, $month, $day, $hour, $minute, $second, $milliseconds)
                    $val = [long]($dateTime - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalSeconds
                    $values += $val
                }
            }
            default {
                Write-Warning "Unhandled adsType: $attrName -> $attrType"
            }
        }
        
        $attributes[$attrName] = $values
    }
    
    return $attributes
}

# Convert SID bytes to string
function Convert-SidToString {
    param([byte[]]$sidBytes)
    
    if ($sidBytes.Length -lt 8) { return "" }
    
    $revision = $sidBytes[0]
    $subAuthorityCount = $sidBytes[1]
    $identifierAuthority = [byte[]]($sidBytes[2..7])
    
    $sid = "S-$revision-"
    
    # Convert identifier authority
    $ia = 0
    for ($i = 0; $i -lt 6; $i++) {
        $ia = ($ia -shl 8) + $identifierAuthority[$i]
    }
    $sid += $ia
    
    # Add sub-authorities
    for ($i = 0; $i -lt $subAuthorityCount; $i++) {
        $offset = 8 + ($i * 4)
        if ($offset + 4 -le $sidBytes.Length) {
            $subAuth = [BitConverter]::ToUInt32($sidBytes, $offset)
            $sid += "-$subAuth"
        }
    }
    
    return $sid
}

# Convert object to BloodHound format
function ConvertTo-BloodHoundObject {
    param([hashtable]$Object)
    
    $attributes = $Object.attributes
    $dn = $attributes.distinguishedname[0]
    $objectClass = $attributes.objectclass[0]
    
    # Determine object type
    $objectType = "Container"
    if ($objectClass -like "*user*") { $objectType = "User" }
    elseif ($objectClass -like "*computer*") { $objectType = "Computer" }
    elseif ($objectClass -like "*group*") { $objectType = "Group" }
    elseif ($objectClass -like "*domain*") { $objectType = "Domain" }
    elseif ($objectClass -like "*groupPolicyContainer*") { $objectType = "GPO" }
    elseif ($objectClass -like "*organizationalUnit*") { $objectType = "OU" }
    
    $bloodHoundObject = @{
        "ObjectIdentifier" = $attributes.objectsid[0]
        "ObjectType" = $objectType
        "Properties" = @{
            "name" = $attributes.name[0]
            "distinguishedname" = $dn
            "domain" = ($dn -split "," | Where-Object { $_ -like "DC=*" } | ForEach-Object { $_.Substring(3) }) -join "."
            "enabled" = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x2) -eq 0 } else { $true }
            "whencreated" = if ($attributes.whencreated) { [DateTime]::FromFileTime($attributes.whencreated[0]).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { "1970-01-01T00:00:00.000Z" }
            "whenchanged" = if ($attributes.whenchanged) { [DateTime]::FromFileTime($attributes.whenchanged[0]).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { "1970-01-01T00:00:00.000Z" }
        }
    }
    
    # Add type-specific properties
    switch ($objectType) {
        "User" {
            $bloodHoundObject.Properties["samaccountname"] = $attributes.samaccountname[0]
            $bloodHoundObject.Properties["displayname"] = $attributes.displayname[0]
            $bloodHoundObject.Properties["email"] = $attributes.mail[0]
            $bloodHoundObject.Properties["title"] = $attributes.title[0]
            $bloodHoundObject.Properties["department"] = $attributes.department[0]
            $bloodHoundObject.Properties["manager"] = $attributes.manager[0]
            $bloodHoundObject.Properties["memberof"] = $attributes.memberof -join ","
            $bloodHoundObject.Properties["pwdlastset"] = if ($attributes.pwdlastset) { [DateTime]::FromFileTime($attributes.pwdlastset[0]).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { "1970-01-01T00:00:00.000Z" }
            $bloodHoundObject.Properties["lastlogon"] = if ($attributes.lastlogon) { [DateTime]::FromFileTime($attributes.lastlogon[0]).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { "1970-01-01T00:00:00.000Z" }
            $bloodHoundObject.Properties["passwordneverexpires"] = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x10000) -ne 0 } else { $false }
            $bloodHoundObject.Properties["passwordnotrequired"] = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x20) -ne 0 } else { $false }
            $bloodHoundObject.Properties["trustedfordelegation"] = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x80000) -ne 0 } else { $false }
            $bloodHoundObject.Properties["trustedtoauthfordelegation"] = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x1000000) -ne 0 } else { $false }
            $bloodHoundObject.Properties["hasspn"] = if ($attributes.serviceprincipalname) { $attributes.serviceprincipalname.Count -gt 0 } else { $false }
            $bloodHoundObject.Properties["spns"] = $attributes.serviceprincipalname
        }
        "Computer" {
            $bloodHoundObject.Properties["samaccountname"] = $attributes.samaccountname[0]
            $bloodHoundObject.Properties["operatingsystem"] = $attributes.operatingsystem[0]
            $bloodHoundObject.Properties["operatingsystemversion"] = $attributes.operatingsystemversion[0]
            $bloodHoundObject.Properties["lastlogon"] = if ($attributes.lastlogon) { [DateTime]::FromFileTime($attributes.lastlogon[0]).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { "1970-01-01T00:00:00.000Z" }
            $bloodHoundObject.Properties["pwdlastset"] = if ($attributes.pwdlastset) { [DateTime]::FromFileTime($attributes.pwdlastset[0]).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") } else { "1970-01-01T00:00:00.000Z" }
            $bloodHoundObject.Properties["trustedfordelegation"] = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x80000) -ne 0 } else { $false }
            $bloodHoundObject.Properties["trustedtoauthfordelegation"] = if ($attributes.useraccountcontrol) { ($attributes.useraccountcontrol[0] -band 0x1000000) -ne 0 } else { $false }
            $bloodHoundObject.Properties["hasspn"] = if ($attributes.serviceprincipalname) { $attributes.serviceprincipalname.Count -gt 0 } else { $false }
            $bloodHoundObject.Properties["spns"] = $attributes.serviceprincipalname
        }
        "Group" {
            $bloodHoundObject.Properties["samaccountname"] = $attributes.samaccountname[0]
            $bloodHoundObject.Properties["description"] = $attributes.description[0]
            $bloodHoundObject.Properties["members"] = $attributes.member
        }
        "Domain" {
            $bloodHoundObject.Properties["name"] = ($dn -split "," | Where-Object { $_ -like "DC=*" } | ForEach-Object { $_.Substring(3) }) -join "."
            $bloodHoundObject.Properties["distinguishedname"] = $dn
        }
        "GPO" {
            $bloodHoundObject.Properties["name"] = $attributes.name[0]
            $bloodHoundObject.Properties["displayname"] = $attributes.displayname[0]
            $bloodHoundObject.Properties["description"] = $attributes.description[0]
        }
        "OU" {
            $bloodHoundObject.Properties["name"] = $attributes.name[0]
            $bloodHoundObject.Properties["description"] = $attributes.description[0]
        }
        "Container" {
            $bloodHoundObject.Properties["name"] = $attributes.name[0]
            $bloodHoundObject.Properties["description"] = $attributes.description[0]
        }
    }
    
    return $bloodHoundObject
}

# Main execution
try {
    Write-Host "`nValidating input file..." -ForegroundColor Yellow
    
    # Validate input file parameter
    if ([string]::IsNullOrWhiteSpace($InputFile)) {
        throw "Input file parameter cannot be empty or null"
    }
    
    # Resolve input file path
    try {
        $resolvedPath = Resolve-Path $InputFile -ErrorAction Stop
        $InputFile = $resolvedPath.Path
    } catch {
        throw "Input file does not exist or cannot be resolved: $InputFile"
    }
    
    Write-Host "Input file: $InputFile" -ForegroundColor Cyan
    Write-Host "Output file: $OutputFile" -ForegroundColor Cyan
    
    # Check if input file exists
    if (-not (Test-Path $InputFile)) {
        throw "Input file does not exist: $InputFile"
    }
    
    # Open file for reading
    $fileStream = [System.IO.File]::OpenRead($InputFile)
    $reader = [System.IO.BinaryReader]::new($fileStream)
    
    Write-Host "`nParsing ADExplorer file..." -ForegroundColor Yellow
    
    # Parse header
    $header = Parse-ADExplorerHeader -Reader $reader
    Write-Host "✓ Header parsed - Objects: $($header.numObjects), Attributes: $($header.numAttributes)" -ForegroundColor Green
    
    # Parse properties
    $reader.BaseStream.Seek($header.mappingOffset, [System.IO.SeekOrigin]::Begin)
    $properties = Parse-Properties -Reader $reader -numProperties $header.numAttributes
    Write-Host "✓ Properties parsed - $($properties.Properties.Count) properties" -ForegroundColor Green
    
    # Parse object offsets
    $reader.BaseStream.Seek(0x43e, [System.IO.SeekOrigin]::Begin)
    $objectOffsets = Parse-ObjectOffsets -Reader $reader -numObjects $header.numObjects
    Write-Host "✓ Object offsets parsed - $($objectOffsets.Count) objects" -ForegroundColor Green
    
    # Parse objects and convert to BloodHound format
    $bloodHoundData = @{
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
    
    Write-Host "`nConverting objects to BloodHound format..." -ForegroundColor Yellow
    
    $convertedCount = 0
    for ($i = 0; $i -lt $objectOffsets.Count; $i++) {
        $reader.BaseStream.Seek($objectOffsets[$i], [System.IO.SeekOrigin]::Begin)
        $object = Parse-Object -Reader $reader -properties $properties.Properties -propertyDict $properties.PropertyDict
        
        $bloodHoundObject = ConvertTo-BloodHoundObject -Object $object
        if ($bloodHoundObject) {
            $objectType = $bloodHoundObject.ObjectType
            $bloodHoundData[$objectType.ToLower() + "s"] += $bloodHoundObject
            $bloodHoundData.meta.count++
            $convertedCount++
        }
        
        if (($i + 1) % 100 -eq 0) {
            Write-Host "Processed $($i + 1)/$($objectOffsets.Count) objects..." -ForegroundColor Gray
        }
    }
    
    $bloodHoundData.meta.data.count = $bloodHoundData.meta.count
    
    # Close file
    $reader.Close()
    $fileStream.Close()
    
    # Convert to JSON and save
    Write-Host "`nGenerating BloodHound JSON..." -ForegroundColor Yellow
    $jsonOutput = $bloodHoundData | ConvertTo-Json -Depth 10
    $jsonOutput | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "✓ Conversion completed successfully!" -ForegroundColor Green
    Write-Host "✓ Output written to: $OutputFile" -ForegroundColor Green
    Write-Host "✓ Converted $convertedCount objects" -ForegroundColor Green
    
    # Show summary
    Write-Host "`nConversion Summary:" -ForegroundColor Yellow
    Write-Host "  Users: $($bloodHoundData.users.Count)" -ForegroundColor Gray
    Write-Host "  Computers: $($bloodHoundData.computers.Count)" -ForegroundColor Gray
    Write-Host "  Groups: $($bloodHoundData.groups.Count)" -ForegroundColor Gray
    Write-Host "  Domains: $($bloodHoundData.domains.Count)" -ForegroundColor Gray
    Write-Host "  GPOs: $($bloodHoundData.gpos.Count)" -ForegroundColor Gray
    Write-Host "  OUs: $($bloodHoundData.ous.Count)" -ForegroundColor Gray
    Write-Host "  Containers: $($bloodHoundData.containers.Count)" -ForegroundColor Gray
    
} catch {
    Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Ensure the file is a valid ADExplorer .dat file" -ForegroundColor Gray
    Write-Host "2. Check file permissions" -ForegroundColor Gray
    Write-Host "3. Try with a different ADExplorer file" -ForegroundColor Gray
    Write-Host "4. Contact support if the issue persists" -ForegroundColor Gray
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
