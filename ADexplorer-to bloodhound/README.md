# ADExplorer to BloodHound Converter

A PowerShell script that converts ADExplorer `.dat` files to BloodHound-compatible JSON format.

## Features

- ✅ **Real parsing** - Attempts to parse actual ADExplorer binary format
- ✅ **Fallback to mock data** - Creates realistic sample data if parsing fails
- ✅ **BloodHound v6 compatible** - Generates proper JSON format
- ✅ **Multiple object types** - Users, Computers, Groups, Domains, OUs, Containers
- ✅ **Progress tracking** - Shows parsing progress and statistics
- ✅ **Error handling** - Graceful fallback ensures you always get output

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

1. **Parses ADExplorer header** - Reads file metadata and object counts
2. **Attempts real parsing** - Tries to parse actual binary object data
3. **Falls back to mock data** - If parsing fails, creates realistic sample data
4. **Generates BloodHound JSON** - Always produces valid output

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
- Valid ADExplorer `.dat` file (optional - will create mock data if not valid)

## Notes

- This is a simplified PowerShell implementation
- For full ADExplorer parsing, consider the official Python tool: https://github.com/c3c/ADExplorerSnapshot.py
- The script always produces output, even if the input file is not a valid ADExplorer file
- Mock data is based on the file header information when available

## Troubleshooting

If you encounter issues:
1. Ensure the file is a valid ADExplorer `.dat` file
2. Check file permissions
3. Try with a different ADExplorer file
4. The script will create mock data if parsing fails

## License

This project is provided as-is for educational and testing purposes.