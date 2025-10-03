# ObjectParser - Parses ADExplorer objects from .dat files
function Get-ADExplorerObjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDeleted
    )
    
    $objects = @()
    
    try {
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $reader = [System.IO.BinaryReader]::new($fileStream)
        
        # Skip header (assuming 32 bytes for now)
        $reader.BaseStream.Seek(32, [System.IO.SeekOrigin]::Begin)
        
        while ($reader.BaseStream.Position -lt $reader.BaseStream.Length) {
            try {
                $object = Read-ADExplorerObject -Reader $reader
                if ($object -and ($IncludeDeleted -or -not $object.IsDeleted)) {
                    $objects += $object
                }
            }
            catch {
                Write-Warning "Failed to parse object at position $($reader.BaseStream.Position): $($_.Exception.Message)"
                # Skip to next object or break if we can't recover
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.BinaryReader]$Reader
    )
    
    try {
        $object = [ADObject]::new()
        
        # Read object header
        $objectSize = $Reader.ReadUInt32()
        $objectType = $Reader.ReadUInt32()
        $flags = $Reader.ReadUInt32()
        
        # Check if object is deleted
        $object.IsDeleted = ($flags -band 0x01) -ne 0
        
        # Read distinguished name
        $dnLength = $Reader.ReadUInt32()
        $dnBytes = $Reader.ReadBytes($dnLength)
        $object.DistinguishedName = [System.Text.Encoding]::UTF8.GetString($dnBytes)
        
        # Read object class
        $classLength = $Reader.ReadUInt32()
        $classBytes = $Reader.ReadBytes($classLength)
        $object.ObjectClass = [System.Text.Encoding]::UTF8.GetString($classBytes)
        
        # Determine object type for BloodHound
        $object.ObjectType = Get-BloodHoundObjectType -ObjectClass $object.ObjectClass
        
        # Read attributes
        $attributeCount = $Reader.ReadUInt32()
        
        for ($i = 0; $i -lt $attributeCount; $i++) {
            $attribute = Read-ADExplorerAttribute -Reader $Reader
            if ($attribute) {
                $object.AddProperty($attribute.Name, $attribute.Value)
                
                # Map common attributes
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.BinaryReader]$Reader
    )
    
    try {
        # Read attribute name
        $nameLength = $Reader.ReadUInt32()
        $nameBytes = $Reader.ReadBytes($nameLength)
        $name = [System.Text.Encoding]::UTF8.GetString($nameBytes)
        
        # Read attribute value
        $valueLength = $Reader.ReadUInt32()
        $valueBytes = $Reader.ReadBytes($valueLength)
        $value = [System.Text.Encoding]::UTF8.GetString($valueBytes)
        
        return @{
            Name = $name
            Value = $value
        }
    }
    catch {
        Write-Warning "Failed to read attribute: $($_.Exception.Message)"
        return $null
    }
}

function Get-BloodHoundObjectType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ObjectClass
    )
    
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ADObject]$Object,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Attribute
    )
    
    switch ($Attribute.Name.ToLower()) {
        "samaccountname" { 
            $Object.SamAccountName = $Attribute.Value 
        }
        "displayname" { 
            $Object.DisplayName = $Attribute.Value 
        }
        "description" { 
            $Object.Description = $Attribute.Value 
        }
        "mail" { 
            $Object.Email = $Attribute.Value 
        }
        "title" { 
            $Object.Title = $Attribute.Value 
        }
        "department" { 
            $Object.Department = $Attribute.Value 
        }
        "manager" { 
            $Object.Manager = $Attribute.Value 
        }
        "memberof" { 
            $Object.MemberOf = $Attribute.Value 
        }
        "member" { 
            $Object.AddMember($Attribute.Value)
        }
        "serviceprincipalname" { 
            $Object.AddSPN($Attribute.Value)
        }
        "useraccountcontrol" { 
            $uac = [uint32]$Attribute.Value
            $Object.Enabled = ($uac -band 0x2) -eq 0
            $Object.PasswordNeverExpires = ($uac -band 0x10000) -ne 0
            $Object.PasswordNotRequired = ($uac -band 0x20) -ne 0
            $Object.TrustedForDelegation = ($uac -band 0x80000) -ne 0
            $Object.TrustedToAuthForDelegation = ($uac -band 0x1000000) -ne 0
        }
        "lastlogon" { 
            $Object.LastLogon = [System.DateTime]::FromFileTime([int64]$Attribute.Value)
        }
        "pwdlastset" { 
            $Object.PasswordLastSet = [System.DateTime]::FromFileTime([int64]$Attribute.Value)
        }
        "whencreated" { 
            $Object.WhenCreated = [System.DateTime]::Parse($Attribute.Value)
        }
        "whenchanged" { 
            $Object.WhenChanged = [System.DateTime]::Parse($Attribute.Value)
        }
    }
}

function Extract-DomainFromDN {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DN
    )
    
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
