@echo off
REM ADExplorer to BloodHound Converter - CMD Version

echo ADExplorer to BloodHound Converter
echo ==================================

if "%1"=="" (
    echo Error: Input file parameter is required
    echo.
    echo Usage: ADExplorerToBloodHound.cmd inputfile.dat [outputfile.json]
    echo.
    echo Examples:
    echo   ADExplorerToBloodHound.cmd AD.dat
    echo   ADExplorerToBloodHound.cmd AD.dat bloodhound.json
    echo   ADExplorerToBloodHound.cmd "C:\path\to\adexplorer.dat"
    echo.
    pause
    exit /b 1
)

set INPUT_FILE=%1
set OUTPUT_FILE=%2

echo Input file: %INPUT_FILE%
echo Output file: %OUTPUT_FILE%
echo.

REM Check if input file exists
if not exist "%INPUT_FILE%" (
    echo Error: Input file does not exist: %INPUT_FILE%
    echo.
    echo Please check:
    echo 1. The file path is correct
    echo 2. The file exists and you have read permissions
    echo 3. The file is a valid ADExplorer .dat file
    echo.
    pause
    exit /b 1
)

echo Input file exists, proceeding with conversion...
echo.

REM Use PowerShell with execution policy bypass
echo Converting ADExplorer file to BloodHound format...
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& {. '%~dp0ADExplorerToBloodHound.ps1' -InputFile '%INPUT_FILE%' -OutputFile '%OUTPUT_FILE%'}"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Conversion completed successfully!
    echo ✓ Output written to: %OUTPUT_FILE%
    echo.
    echo You can now import this JSON file into BloodHound.
    echo.
    echo The converted file contains:
    echo - Users, Computers, Groups, Domains, GPOs, OUs, and Containers
    echo - Sample data based on your ADExplorer file structure
    echo - BloodHound-compatible JSON format
) else (
    echo.
    echo ✗ Conversion failed with error code: %ERRORLEVEL%
    echo.
    echo Check the error messages above for troubleshooting.
    echo.
    echo Common issues:
    echo 1. File is not a valid ADExplorer .dat file
    echo 2. File is corrupted or incomplete
    echo 3. File permissions issue
    echo 4. File is in a different format than expected
)

echo.
pause
