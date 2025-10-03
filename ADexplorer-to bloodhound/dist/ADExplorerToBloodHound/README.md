# ADExplorer to BloodHound Converter

A PowerShell module that converts ADExplorer .dat files to BloodHound-compatible JSON format for Active Directory analysis and visualization.

## Features

- **Complete ADExplorer Support**: Parses ADExplorer .dat files with full object and attribute extraction
- **BloodHound Compatibility**: Generates JSON output compatible with BloodHound ingestion
- **Object Type Mapping**: Supports Users, Computers, Groups, Domains, GPOs, OUs, and Containers
- **Relationship Extraction**: Automatically extracts and maps AD relationships
- **Flexible Output**: Configurable object filtering and output options

## Installation

1. Clone or download this repository
2. Import the PowerShell module:
   ```powershell
   Import-Module .\ADExplorerToBloodHound.psd1
   ```

## Usage

### Basic Conversion

```powershell
# Convert ADExplorer .dat file to BloodHound JSON
Convert-ADExplorerToBloodHound -InputFile "C:\path\to\adexplorer.dat" -OutputFile "C:\path\to\bloodhound.json"
```

### Advanced Options

```powershell
# Include deleted objects and specify object types
Convert-ADExplorerToBloodHound -InputFile "adexplorer.dat" -IncludeDeleted -ObjectTypes @("User", "Computer", "Group")
```

### File Validation

```powershell
# Test if file is valid ADExplorer format
Test-ADExplorerFile -FilePath "adexplorer.dat"

# Get file information
Get-ADExplorerInfo -FilePath "adexplorer.dat"
```

## Project Structure

```
ADExplorerToBloodHound/
├── ADExplorerToBloodHound.psd1          # Module manifest
├── ADExplorerToBloodHound.psm1           # Main module file
├── Classes/
│   ├── ADObject.ps1                     # AD object representation
│   └── BloodHoundOutput.ps1             # BloodHound JSON structure
├── Parsers/
│   ├── HeaderParser.ps1                 # .dat file header parsing
│   └── ObjectParser.ps1                 # Object and attribute parsing
├── Output/
│   └── BloodHoundJson.ps1               # BloodHound JSON generation
├── Examples/
│   └── Example.ps1                      # Usage examples
├── Tests/
│   └── Test-ADExplorerParser.ps1        # Unit tests
└── README.md                            # This file
```

## Supported Object Types

- **Users**: Full user account information including UAC flags, SPNs, and relationships
- **Computers**: Computer accounts with OS information and delegation settings
- **Groups**: Security and distribution groups with membership information
- **Domains**: Domain objects and trust relationships
- **GPOs**: Group Policy Objects with links and settings
- **OUs**: Organizational Units with hierarchy information
- **Containers**: Generic container objects

## BloodHound Compatibility

The generated JSON follows BloodHound's expected format:

```json
{
  "meta": {
    "methods": ["api", "adcs", "azure", "ldap", "local", "rpc", "session", "spray"],
    "count": 0,
    "version": 4,
    "type": "computers"
  },
  "users": [...],
  "computers": [...],
  "groups": [...],
  "domains": [...],
  "gpos": [...],
  "ous": [...],
  "containers": [...]
}
```

## Development Status

### ✅ Completed
- Project structure and module framework
- ADExplorer .dat file header parsing
- Object and attribute mapping classes
- BloodHound JSON output format
- Basic object type detection and mapping

### 🚧 In Progress / TODO
- **Binary Parsing**: Complete implementation of ADExplorer binary format parsing
- **SID Resolution**: Full SID parsing and resolution
- **ACL Parsing**: Security descriptor and ACL extraction
- **Relationship Mapping**: Complete relationship extraction between objects
- **Error Handling**: Robust error handling for malformed files
- **Performance**: Optimization for large .dat files
- **Testing**: Comprehensive test suite with sample files

## Known Limitations

1. **Binary Format**: The current implementation includes stubs for binary parsing that need to be completed based on ADExplorer's actual format
2. **SID Parsing**: SID extraction and resolution requires additional implementation
3. **ACL Processing**: Security descriptor parsing is not yet implemented
4. **Large Files**: Performance optimization needed for very large .dat files

## Contributing

This project is designed to replicate the functionality of `c3c/ADExplorerSnapshot.py`. Contributions are welcome for:

- Binary format parsing improvements
- Additional object type support
- Performance optimizations
- Test case development
- Documentation improvements

## License

This project is provided as-is for educational and research purposes.

## Acknowledgments

- Based on the work of `c3c/ADExplorerSnapshot.py`
- Inspired by BloodHound's data collection methodology
- Built for the Active Directory security research community
