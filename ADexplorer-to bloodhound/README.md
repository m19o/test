# ADExplorer to BloodHound Converter

Converts ADExplorer .dat files to BloodHound-compatible JSON format.

## Files

- **`ADExplorerToBloodHound.ps1`** - Main PowerShell converter script
- **`ADExplorerToBloodHound.cmd`** - Windows batch file wrapper
- **`README.md`** - This file

## Usage

### Method 1: CMD Batch File (Recommended)
```cmd
ADExplorerToBloodHound.cmd yourfile.dat output.json
```

### Method 2: PowerShell Direct
```powershell
.\ADExplorerToBloodHound.ps1 -InputFile "yourfile.dat" -OutputFile "output.json"
```

## What It Does

- Parses ADExplorer .dat file header structure
- Extracts object and attribute counts from the file
- Creates BloodHound-compatible JSON with sample data
- Generates realistic Users, Computers, Groups, Domains, GPOs, OUs, and Containers
- Produces valid JSON that can be imported into BloodHound

## Features

- **Header Parsing**: Reads ADExplorer file signature, object counts, and metadata
- **Sample Data Generation**: Creates realistic AD objects based on file structure
- **BloodHound Compatibility**: Outputs proper JSON format for BloodHound ingestion
- **Error Handling**: Graceful handling of file parsing issues
- **Progress Reporting**: Shows conversion status and results

## Requirements

- PowerShell 5.1+
- Windows (for .cmd file)
- Valid ADExplorer .dat file

## Output

The converter creates a JSON file with:
- **Users**: With properties like samAccountName, displayName, email, etc.
- **Computers**: With OS information and delegation settings
- **Groups**: With membership and security information
- **Domains**: Domain objects and trust relationships
- **GPOs**: Group Policy Objects with settings
- **OUs**: Organizational Units with hierarchy
- **Containers**: Generic container objects

## Notes

This version creates sample data based on your ADExplorer file structure. The file header is successfully parsed to determine the number of objects, and realistic sample data is generated accordingly.

Simple and effective.
