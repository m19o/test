# BloodHound JSON output functions
function ConvertTo-BloodHoundObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ADObject]$ADObject
    )
    
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Objects
    )
    
    $relationships = @()
    
    foreach ($object in $Objects) {
        # Member relationships
        if ($object.Members) {
            foreach ($member in $object.Members) {
                $relationships += @{
                    "Source" = $object.SID
                    "Target" = $member
                    "RelationshipType" = "MemberOf"
                }
            }
        }
        
        # Manager relationships
        if ($object.Manager) {
            $relationships += @{
                "Source" = $object.SID
                "Target" = $object.Manager
                "RelationshipType" = "Manager"
            }
        }
        
        # Group membership relationships
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

function Export-BloodHoundJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [BloodHoundOutput]$BloodHoundData,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        $jsonOutput = $BloodHoundData.ToJson()
        $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "BloodHound JSON exported to: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Failed to export BloodHound JSON: $($_.Exception.Message)"
        return $false
    }
}
