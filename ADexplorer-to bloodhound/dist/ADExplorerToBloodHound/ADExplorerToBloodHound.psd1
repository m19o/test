@{
    # Module manifest for ADExplorerToBloodHound
    RootModule = 'ADExplorerToBloodHound.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'ADExplorer to BloodHound Converter'
    CompanyName = 'Security Tools'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'Converts ADExplorer .dat files to BloodHound-compatible JSON format'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    
    # Required modules
    RequiredModules = @()
    
    # Script files (.ps1) that are run in the caller's environment before importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Convert-ADExplorerToBloodHound',
        'Get-ADExplorerInfo',
        'Test-ADExplorerFile'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @(
        'ADExplorerToBloodHound.psm1',
        'Classes\ADObject.ps1',
        'Classes\BloodHoundOutput.ps1',
        'Parsers\HeaderParser.ps1',
        'Parsers\ObjectParser.ps1',
        'Output\BloodHoundJson.ps1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('ADExplorer', 'BloodHound', 'ActiveDirectory', 'Security', 'Forensics')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release - ADExplorer .dat file to BloodHound JSON converter'
        }
    }
}
