# ADExplorer to BloodHound Converter

Converts ADExplorer .dat files to BloodHound-compatible JSON format.

## Files

- **`Real-ADExplorer-Converter.ps1`** - Main PowerShell converter script
- **`Real-ADExplorer-Converter.cmd`** - Windows batch file wrapper
- **`README.md`** - This file

## Usage

### Method 1: CMD Batch File (Recommended)
```cmd
Real-ADExplorer-Converter.cmd yourfile.dat output.json
```

### Method 2: PowerShell Direct
```powershell
.\Real-ADExplorer-Converter.ps1 -InputFile "yourfile.dat" -OutputFile "output.json"
```

## What It Does

- Parses real ADExplorer .dat file structure
- Extracts all objects (Users, Computers, Groups, etc.)
- Converts to BloodHound JSON format
- Handles SIDs, timestamps, and all attribute types

## Requirements

- PowerShell 5.1+
- Windows (for .cmd file)
- Valid ADExplorer .dat file

That's it. Simple and clean.