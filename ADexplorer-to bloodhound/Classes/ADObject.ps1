# ADObject class for representing Active Directory objects from ADExplorer
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
