# BloodHoundOutput class for managing BloodHound JSON structure
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
