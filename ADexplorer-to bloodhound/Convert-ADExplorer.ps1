# Standalone ADExplorer to BloodHound Converter
# This script can be run directly without module loading

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDeleted,
    
    [Parameter(Mandatory = $false)]
    [string[]]$ObjectTypes = @('User', 'Computer', 'Group', 'Domain', 'GPO', 'OU', 'Container'),
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Include all required classes and functions directly in this script
# ADObject class
class ADObject {
    [string]$DistinguishedName
    [string]$ObjectClass
    [string]$ObjectType
    [string]$Name
    [string]$SID
    [string]$GUID
    [string]$Domain
    [string]$SamAccountName
    [string]$DisplayName
    [string]$Description
    [string]$Email
    [string]$Title
    [string]$Department
    [string]$Manager
    [string]$MemberOf
    [string[]]$Members
    [string[]]$SPNs
    [bool]$Enabled
    [bool]$PasswordNeverExpires
    [bool]$PasswordNotRequired
    [bool]$TrustedForDelegation
    [bool]$TrustedToAuthForDelegation
    [bool]$HasSPN
    [bool]$IsDeleted
    [datetime]$LastLogon
    [datetime]$PasswordLastSet
    [datetime]$WhenCreated
    [datetime]$WhenChanged
    [hashtable]$Properties
    [string[]]$ACLs
    [string[]]$Relationships
    
    ADObject() {
        $this.Properties = @{}
        $this.Members = @()
        $this.SPNs = @()
        $this.ACLs = @()
        $this.Relationships = @()
        $this.Enabled = $true
        $this.IsDeleted = $false
    }
    
    [void] AddProperty([string]$Name, [object]$Value) {
        $this.Properties[$Name] = $Value
    }
    
    [object] GetProperty([string]$Name) {
        return $this.Properties[$Name]
    }
    
    [bool] HasProperty([string]$Name) {
        return $this.Properties.ContainsKey($Name)
    }
    
    [void] AddMember([string]$Member) {
        if ($Member -and $Member -notin $this.Members) {
            $this.Members += $Member
        }
    }
    
    [void] AddSPN([string]$SPN) {
        if ($SPN -and $SPN -notin $this.SPNs) {
            $this.SPNs += $SPN
        }
    }
    
    [void] AddACL([string]$ACL) {
        if ($ACL -and $ACL -notin $this.ACLs) {
            $this.ACLs += $ACL
        }
    }
    
    [void] AddRelationship([string]$Relationship) {
        if ($Relationship -and $Relationship -notin $this.Relationships) {
            $this.Relationships += $Relationship
        }
    }
    
    [string] ToString() {
        return "ADObject: $($this.DistinguishedName) ($($this.ObjectType))"
    }
}

# BloodHoundOutput class
class BloodHoundOutput {
    [hashtable]$Meta
    [array]$Users
    [array]$Computers
    [array]$Groups
    [array]$Domains
    [array]$GPOs
    [array]$OUs
    [array]$Containers
    [array]$Relationships
    
    BloodHoundOutput() {
        $this.Meta = @{
            "methods" = @("api", "adcs", "azure", "ldap", "local", "rpc", "session", "spray")
            "count" = 0
            "version" = 4
            "type" = "computers"
            "data" = @{
                "count" = 0
                "version" = 4
            }
        }
        $this.Users = @()
        $this.Computers = @()
        $this.Groups = @()
        $this.Domains = @()
        $this.GPOs = @()
        $this.OUs = @()
        $this.Containers = @()
        $this.Relationships = @()
    }
    
    [void] AddObject([hashtable]$Object) {
        $objectType = $Object["ObjectType"]
        
        switch ($objectType) {
            "User" { 
                $this.Users += $Object
                $this.Meta.count++
            }
            "Computer" { 
                $this.Computers += $Object
                $this.Meta.count++
            }
            "Group" { 
                $this.Groups += $Object
                $this.Meta.count++
            }
            "Domain" { 
                $this.Domains += $Object
                $this.Meta.count++
            }
            "GPO" { 
                $this.GPOs += $Object
                $this.Meta.count++
            }
            "OU" { 
                $this.OUs += $Object
                $this.Meta.count++
            }
            "Container" { 
                $this.Containers += $Object
                $this.Meta.count++
            }
        }
        
        $this.Meta.data.count = $this.Meta.count
    }
    
    [void] AddRelationship([hashtable]$Relationship) {
        $this.Relationships += $Relationship
    }
    
    [string] ToJson() {
        $output = @{
            "meta" = $this.Meta
            "users" = $this.Users
            "computers" = $this.Computers
            "groups" = $this.Groups
            "domains" = $this.Domains
            "gpos" = $this.GPOs
            "ous" = $this.OUs
            "containers" = $this.Containers
        }
        
        return ($output | ConvertTo-Json -Depth 10)
    }
}

# Header parsing function
function Get-ADExplorerHeader {
    param([string]$FilePath)
    
    try {
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $reader = [System.IO.BinaryReader]::new($fileStream)
        
        # Read magic bytes
        $magicBytes = $reader.ReadBytes(4)
        $magicString = [System.Text.Encoding]::ASCII.GetString($magicBytes)
        
        if ($magicString -ne "ADEX") {
            throw "Invalid ADExplorer file format. Expected magic bytes 'ADEX'"
        }
        
        # Read version and object count
        $version = $reader.ReadUInt32()
        $objectCount = $reader.ReadUInt32()
        $timestamp = $reader.ReadUInt64()
        $dateTime = [System.DateTime]::FromFileTime($timestamp)
        
        $reader.Close()
        $fileStream.Close()
        
        return @{
            IsValid = $true
            Version = $version
            ObjectCount = $objectCount
            Timestamp = $dateTime
        }
    }
    catch {
        Write-Error "Failed to parse ADExplorer header: $($_.Exception.Message)"
        return @{ IsValid = $false; Error = $_.Exception.Message }
    }
}

# Object parsing function
function Get-ADExplorerObjects {
    param(
        [string]$FilePath,
        [switch]$IncludeDeleted
    )
    
    $objects = @()
    
    try {
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $reader = [System.IO.BinaryReader]::new($fileStream)
        
        # Skip header
        $reader.BaseStream.Seek(32, [System.IO.SeekOrigin]::Begin)
        
        while ($reader.BaseStream.Position -lt $reader.BaseStream.Length) {
            try {
                $object = Read-ADExplorerObject -Reader $reader
                if ($object -and ($IncludeDeleted -or -not $object.IsDeleted)) {
                    $objects += $object
                }
            }
            catch {
                Write-Warning "Failed to parse object: $($_.Exception.Message)"
                break
            }
        }
        
        $reader.Close()
        $fileStream.Close()
        
        return $objects
    }
    catch {
        Write-Error "Failed to parse ADExplorer objects: $($_.Exception.Message)"
        return @()
    }
}

function Read-ADExplorerObject {
    param([System.IO.BinaryReader]$Reader)
    
    try {
        $object = [ADObject]::new()
        
        # Read object header
        $objectSize = $Reader.ReadUInt32()
        $objectType = $Reader.ReadUInt32()
        $flags = $Reader.ReadUInt32()
        
        $object.IsDeleted = ($flags -band 0x01) -ne 0
        
        # Read distinguished name
        $dnLength = $Reader.ReadUInt32()
        $dnBytes = $Reader.ReadBytes($dnLength)
        $object.DistinguishedName = [System.Text.Encoding]::UTF8.GetString($dnBytes)
        
        # Read object class
        $classLength = $Reader.ReadUInt32()
        $classBytes = $Reader.ReadBytes($classLength)
        $object.ObjectClass = [System.Text.Encoding]::UTF8.GetString($classBytes)
        
        # Determine object type
        $object.ObjectType = Get-BloodHoundObjectType -ObjectClass $object.ObjectClass
        
        # Read attributes
        $attributeCount = $Reader.ReadUInt32()
        
        for ($i = 0; $i -lt $attributeCount; $i++) {
            $attribute = Read-ADExplorerAttribute -Reader $Reader
            if ($attribute) {
                $object.AddProperty($attribute.Name, $attribute.Value)
                Map-CommonAttributes -Object $object -Attribute $attribute
            }
        }
        
        # Extract domain from DN
        $object.Domain = Extract-DomainFromDN -DN $object.DistinguishedName
        
        return $object
    }
    catch {
        Write-Warning "Failed to read ADExplorer object: $($_.Exception.Message)"
        return $null
    }
}

function Read-ADExplorerAttribute {
    param([System.IO.BinaryReader]$Reader)
    
    try {
        $nameLength = $Reader.ReadUInt32()
        $nameBytes = $Reader.ReadBytes($nameLength)
        $name = [System.Text.Encoding]::UTF8.GetString($nameBytes)
        
        $valueLength = $Reader.ReadUInt32()
        $valueBytes = $Reader.ReadBytes($valueLength)
        $value = [System.Text.Encoding]::UTF8.GetString($valueBytes)
        
        return @{ Name = $name; Value = $value }
    }
    catch {
        Write-Warning "Failed to read attribute: $($_.Exception.Message)"
        return $null
    }
}

function Get-BloodHoundObjectType {
    param([string]$ObjectClass)
    
    switch ($ObjectClass.ToLower()) {
        "user" { return "User" }
        "computer" { return "Computer" }
        "group" { return "Group" }
        "domain" { return "Domain" }
        "groupPolicyContainer" { return "GPO" }
        "organizationalUnit" { return "OU" }
        "container" { return "Container" }
        default { return "Container" }
    }
}

function Map-CommonAttributes {
    param(
        [ADObject]$Object,
        [hashtable]$Attribute
    )
    
    switch ($Attribute.Name.ToLower()) {
        "samaccountname" { $Object.SamAccountName = $Attribute.Value }
        "displayname" { $Object.DisplayName = $Attribute.Value }
        "description" { $Object.Description = $Attribute.Value }
        "mail" { $Object.Email = $Attribute.Value }
        "title" { $Object.Title = $Attribute.Value }
        "department" { $Object.Department = $Attribute.Value }
        "manager" { $Object.Manager = $Attribute.Value }
        "memberof" { $Object.MemberOf = $Attribute.Value }
        "member" { $Object.AddMember($Attribute.Value) }
        "serviceprincipalname" { $Object.AddSPN($Attribute.Value) }
        "useraccountcontrol" { 
            $uac = [uint32]$Attribute.Value
            $Object.Enabled = ($uac -band 0x2) -eq 0
            $Object.PasswordNeverExpires = ($uac -band 0x10000) -ne 0
            $Object.PasswordNotRequired = ($uac -band 0x20) -ne 0
            $Object.TrustedForDelegation = ($uac -band 0x80000) -ne 0
            $Object.TrustedToAuthForDelegation = ($uac -band 0x1000000) -ne 0
        }
        "lastlogon" { $Object.LastLogon = [System.DateTime]::FromFileTime([int64]$Attribute.Value) }
        "pwdlastset" { $Object.PasswordLastSet = [System.DateTime]::FromFileTime([int64]$Attribute.Value) }
        "whencreated" { $Object.WhenCreated = [System.DateTime]::Parse($Attribute.Value) }
        "whenchanged" { $Object.WhenChanged = [System.DateTime]::Parse($Attribute.Value) }
    }
}

function Extract-DomainFromDN {
    param([string]$DN)
    
    try {
        $parts = $DN -split ","
        $dcParts = $parts | Where-Object { $_ -like "DC=*" }
        $domain = ($dcParts | ForEach-Object { $_.Substring(3) }) -join "."
        return $domain
    }
    catch {
        return ""
    }
}

function ConvertTo-BloodHoundObject {
    param([ADObject]$ADObject)
    
    $bloodHoundObject = @{
        "ObjectIdentifier" = $ADObject.SID
        "ObjectType" = $ADObject.ObjectType
        "Properties" = @{
            "name" = $ADObject.Name
            "distinguishedname" = $ADObject.DistinguishedName
            "domain" = $ADObject.Domain
            "enabled" = $ADObject.Enabled
            "whencreated" = $ADObject.WhenCreated.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            "whenchanged" = $ADObject.WhenChanged.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
    
    # Add type-specific properties
    switch ($ADObject.ObjectType) {
        "User" {
            $bloodHoundObject.Properties["samaccountname"] = $ADObject.SamAccountName
            $bloodHoundObject.Properties["displayname"] = $ADObject.DisplayName
            $bloodHoundObject.Properties["email"] = $ADObject.Email
            $bloodHoundObject.Properties["title"] = $ADObject.Title
            $bloodHoundObject.Properties["department"] = $ADObject.Department
            $bloodHoundObject.Properties["manager"] = $ADObject.Manager
            $bloodHoundObject.Properties["memberof"] = $ADObject.MemberOf
            $bloodHoundObject.Properties["pwdlastset"] = $ADObject.PasswordLastSet.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $bloodHoundObject.Properties["lastlogon"] = $ADObject.LastLogon.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $bloodHoundObject.Properties["passwordneverexpires"] = $ADObject.PasswordNeverExpires
            $bloodHoundObject.Properties["passwordnotrequired"] = $ADObject.PasswordNotRequired
            $bloodHoundObject.Properties["trustedfordelegation"] = $ADObject.TrustedForDelegation
            $bloodHoundObject.Properties["trustedtoauthfordelegation"] = $ADObject.TrustedToAuthForDelegation
            $bloodHoundObject.Properties["hasspn"] = $ADObject.HasSPN
            $bloodHoundObject.Properties["spns"] = $ADObject.SPNs
        }
        "Computer" {
            $bloodHoundObject.Properties["samaccountname"] = $ADObject.SamAccountName
            $bloodHoundObject.Properties["operatingsystem"] = $ADObject.GetProperty("operatingsystem")
            $bloodHoundObject.Properties["operatingsystemversion"] = $ADObject.GetProperty("operatingsystemversion")
            $bloodHoundObject.Properties["lastlogon"] = $ADObject.LastLogon.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $bloodHoundObject.Properties["pwdlastset"] = $ADObject.PasswordLastSet.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $bloodHoundObject.Properties["trustedfordelegation"] = $ADObject.TrustedForDelegation
            $bloodHoundObject.Properties["trustedtoauthfordelegation"] = $ADObject.TrustedToAuthForDelegation
            $bloodHoundObject.Properties["hasspn"] = $ADObject.HasSPN
            $bloodHoundObject.Properties["spns"] = $ADObject.SPNs
        }
        "Group" {
            $bloodHoundObject.Properties["samaccountname"] = $ADObject.SamAccountName
            $bloodHoundObject.Properties["description"] = $ADObject.Description
            $bloodHoundObject.Properties["members"] = $ADObject.Members
        }
        "Domain" {
            $bloodHoundObject.Properties["name"] = $ADObject.Domain
            $bloodHoundObject.Properties["distinguishedname"] = $ADObject.DistinguishedName
        }
        "GPO" {
            $bloodHoundObject.Properties["name"] = $ADObject.Name
            $bloodHoundObject.Properties["displayname"] = $ADObject.DisplayName
            $bloodHoundObject.Properties["description"] = $ADObject.Description
        }
        "OU" {
            $bloodHoundObject.Properties["name"] = $ADObject.Name
            $bloodHoundObject.Properties["description"] = $ADObject.Description
        }
        "Container" {
            $bloodHoundObject.Properties["name"] = $ADObject.Name
            $bloodHoundObject.Properties["description"] = $ADObject.Description
        }
    }
    
    # Add all custom properties
    foreach ($property in $ADObject.Properties.GetEnumerator()) {
        if ($property.Key -notin $bloodHoundObject.Properties.Keys) {
            $bloodHoundObject.Properties[$property.Key] = $property.Value
        }
    }
    
    return $bloodHoundObject
}

function Get-BloodHoundRelationships {
    param([array]$Objects)
    
    $relationships = @()
    
    foreach ($object in $Objects) {
        if ($object.Members) {
            foreach ($member in $object.Members) {
                $relationships += @{
                    "Source" = $object.SID
                    "Target" = $member
                    "RelationshipType" = "MemberOf"
                }
            }
        }
        
        if ($object.Manager) {
            $relationships += @{
                "Source" = $object.SID
                "Target" = $object.Manager
                "RelationshipType" = "Manager"
            }
        }
        
        if ($object.MemberOf) {
            $relationships += @{
                "Source" = $object.SID
                "Target" = $object.MemberOf
                "RelationshipType" = "MemberOf"
            }
        }
    }
    
    return $relationships
}

# Main execution logic
Write-Host "ADExplorer to BloodHound Converter - Standalone Script" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

try {
    Write-Host "`nStarting conversion process..." -ForegroundColor Yellow
    
    # Validate input file
    if (-not (Test-Path $InputFile)) {
        throw "Input file does not exist: $InputFile"
    }
    
    # Set default output file if not specified
    if (-not $OutputFile) {
        $OutputFile = [System.IO.Path]::ChangeExtension($InputFile, ".json")
    }
    
    Write-Host "Input file: $InputFile" -ForegroundColor Cyan
    Write-Host "Output file: $OutputFile" -ForegroundColor Cyan
    
    # Parse the .dat file header
    $headerInfo = Get-ADExplorerHeader -FilePath $InputFile
    if (-not $headerInfo.IsValid) {
        throw "Invalid ADExplorer file format: $($headerInfo.Error)"
    }
    
    Write-Host "File version: $($headerInfo.Version)" -ForegroundColor Gray
    Write-Host "Object count: $($headerInfo.ObjectCount)" -ForegroundColor Gray
    Write-Host "Timestamp: $($headerInfo.Timestamp)" -ForegroundColor Gray
    
    # Parse objects from the file
    $objects = Get-ADExplorerObjects -FilePath $InputFile -IncludeDeleted:$IncludeDeleted
    Write-Host "Parsed $($objects.Count) objects from file" -ForegroundColor Green
    
    # Initialize BloodHound output structure
    $bloodHoundData = [BloodHoundOutput]::new()
    
    # Convert to BloodHound format
    $convertedCount = 0
    foreach ($object in $objects) {
        if ($object.ObjectType -in $ObjectTypes) {
            $bloodHoundObject = ConvertTo-BloodHoundObject -ADObject $object
            if ($bloodHoundObject) {
                $bloodHoundData.AddObject($bloodHoundObject)
                $convertedCount++
            }
        }
    }
    
    Write-Host "Converted $convertedCount objects to BloodHound format" -ForegroundColor Green
    
    # Generate relationships
    $relationships = Get-BloodHoundRelationships -Objects $objects
    foreach ($relationship in $relationships) {
        $bloodHoundData.AddRelationship($relationship)
    }
    
    Write-Host "Generated $($relationships.Count) relationships" -ForegroundColor Green
    
    # Output to JSON
    $jsonOutput = $bloodHoundData.ToJson()
    
    # Write to file
    $jsonOutput | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "`n✓ Conversion completed successfully!" -ForegroundColor Green
    Write-Host "✓ Output written to: $OutputFile" -ForegroundColor Green
    
    # Show summary
    Write-Host "`nConversion Summary:" -ForegroundColor Yellow
    Write-Host "  Users: $($bloodHoundData.Users.Count)" -ForegroundColor Gray
    Write-Host "  Computers: $($bloodHoundData.Computers.Count)" -ForegroundColor Gray
    Write-Host "  Groups: $($bloodHoundData.Groups.Count)" -ForegroundColor Gray
    Write-Host "  Domains: $($bloodHoundData.Domains.Count)" -ForegroundColor Gray
    Write-Host "  GPOs: $($bloodHoundData.GPOs.Count)" -ForegroundColor Gray
    Write-Host "  OUs: $($bloodHoundData.OUs.Count)" -ForegroundColor Gray
    Write-Host "  Containers: $($bloodHoundData.Containers.Count)" -ForegroundColor Gray
    Write-Host "  Relationships: $($bloodHoundData.Relationships.Count)" -ForegroundColor Gray
    
}
catch {
    Write-Host "`n✗ Conversion failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
