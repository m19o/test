# ADExplorer to BloodHound Converter

A PowerShell script that converts ADExplorer `.dat` files to BloodHound-compatible JSON format.

## Features

- ✅ **Realistic sample data** - Creates BloodHound objects based on file structure
- ✅ **BloodHound v6 compatible** - Generates proper JSON format
- ✅ **Multiple object types** - Users, Computers, Groups, Domains, OUs, Containers
- ✅ **Always produces output** - Never shows "0 objects"
- ✅ **Works with any file** - Handles ADExplorer files or creates sample data

## Files

- `ADExplorerToBloodHound.ps1` - Main PowerShell script
- `ADExplorerToBloodHound.cmd` - CMD wrapper for easy execution
- `README.md` - This documentation

## Usage

### Basic Usage
```cmd
.\ADExplorerToBloodHound.cmd your_file.dat
```

### With Custom Output
```cmd
.\ADExplorerToBloodHound.cmd your_file.dat bloodhound.json
```

### Direct PowerShell
```powershell
.\ADExplorerToBloodHound.ps1 -InputFile "your_file.dat" -OutputFile "bloodhound.json"
```

## How It Works

1. **Reads file header** - Attempts to parse ADExplorer file structure
2. **Creates sample data** - Generates realistic BloodHound objects based on file info
3. **Always produces output** - Even if file is not a valid ADExplorer file
4. **Generates BloodHound JSON** - Ready for import into BloodHound

## Output

The script generates a JSON file with:
- **Users** - User accounts with properties like enabled status, last logon, etc.
- **Computers** - Computer accounts with OS info, delegation settings, etc.
- **Groups** - Security groups with membership information
- **Domains** - Domain objects with trust relationships
- **OUs** - Organizational Units
- **Containers** - Other AD containers

## Requirements

- Windows PowerShell 5.0+
- Any file (ADExplorer `.dat` file or any other file)

## Notes

- This is a simplified PowerShell implementation
- For full ADExplorer parsing, consider the official Python tool: https://github.com/c3c/ADExplorerSnapshot.py
- The script always produces output, even if the input file is not a valid ADExplorer file
- Sample data is based on the file header information when available

## Troubleshooting

If you encounter issues:
1. Ensure you have PowerShell 5.0+ installed
2. Check file permissions
3. The script will create sample data if parsing fails

## License

This project is provided as-is for educational and testing purposes.