<#
.SYNOPSIS
  Parses a basic AD Explorer .dat snapshot and outputs minimal info for BloodHound.

.DESCRIPTION
  This script demonstrates how to open and parse the binary header of an AD Explorer .dat file,
  following the structure reverse engineered by c3c/ADExplorerSnapshot.py.
  You will need to extend this with detailed record parsing and BloodHound field mapping
  if you want full feature parity with the Python tool.

.PARAMETER DatFile
  Path to the AD Explorer .dat snapshot file.

.PARAMETER OutputJson
  Path to write a minimal BloodHound-compatible JSON file.

.EXAMPLE
  .\ADExplorerDat2Bloodhound.ps1 -DatFile .\snapshot.dat -OutputJson .\output.json
#>

param(
    [Parameter(Mandatory)]
    [string]$DatFile,
    [Parameter(Mandatory)]
    [string]$OutputJson
)

function Read-WideString {
    param([System.IO.BinaryReader]$br, [int]$numChars)
    $bytes = $br.ReadBytes($numChars * 2)
    return [System.Text.Encoding]::Unicode.GetString($bytes).Trim([char]0)
}

$fs = [System.IO.File]::OpenRead($DatFile)
$br = New-Object System.IO.BinaryReader($fs)

# -- Parse Header based on reverse-engineered struct --
# struct Header {
#     char winAdSig[10];
#     int marker;
#     uint64 filetime;
#     wchar optionalDescription[260];
#     wchar  server[260];
#     uint32 numObjects;
#     uint32 numAttributes;
#     uint32 fileoffsetLow;
#     uint32 fileoffsetHigh;
#     uint32 fileoffsetEnd;
#     int unk0x43a;
# };

$magic = $br.ReadBytes(10)
$marker = $br.ReadInt32()
$filetime = $br.ReadUInt64()
$optionalDescription = Read-WideString $br 260
$server = Read-WideString $br 260
$numObjects = $br.ReadUInt32()
$numAttributes = $br.ReadUInt32()
$fileoffsetLow = $br.ReadUInt32()
$fileoffsetHigh = $br.ReadUInt32()
$fileoffsetEnd = $br.ReadUInt32()
$unk0x43a = $br.ReadInt32()

Write-Host "Magic: $([System.Text.Encoding]::ASCII.GetString($magic))"
Write-Host "Server: $server"
Write-Host "numObjects: $numObjects"
Write-Host "numAttributes: $numAttributes"

# -- At this point, you'd parse the attribute/property/class tables, object offsets, and objects,
#    following the logic in adexpsnapshot/parser/classes.py and structure.py.
#    This is a nontrivial effort and not feasible to fully implement in one reply. --

# --- Example: Output a minimal BloodHound node (stub) ---
# This demonstrates the kind of output file you'd produce for ingestion by BloodHound.

$bloodhoundEntry = @{
    "name" = $server
    "objectType" = "domain"
    "properties" = @{
        "description" = $optionalDescription
        "objectCount" = $numObjects
        "attributesCount" = $numAttributes
    }
}

Set-Content -Path $OutputJson -Value ($bloodhoundEntry | ConvertTo-Json -Depth 5)

$br.Close()
$fs.Close()

Write-Host "Parsed header and wrote minimal output to $OutputJson"
