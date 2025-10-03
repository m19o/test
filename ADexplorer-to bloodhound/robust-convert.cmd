@echo off
REM Robust ADExplorer to BloodHound Converter - CMD Version
REM Handles empty parameters and path issues better

echo Robust ADExplorer to BloodHound Converter
echo =========================================

if "%1"=="" (
    echo Error: Input file parameter is required
    echo.
    echo Usage: robust-convert.cmd inputfile.dat [outputfile.json]
    echo.
    echo Examples:
    echo   robust-convert.cmd adexplorer.dat
    echo   robust-convert.cmd adexplorer.dat bloodhound.json
    echo   robust-convert.cmd "C:\path\to\adexplorer.dat"
    echo.
    pause
    exit /b 1
)

set INPUT_FILE=%1
set OUTPUT_FILE=%2

echo Input file parameter: "%INPUT_FILE%"
echo Output file parameter: "%OUTPUT_FILE%"
echo.

REM Check if input file parameter is empty
if "%INPUT_FILE%"=="" (
    echo Error: Input file parameter cannot be empty
    pause
    exit /b 1
)

REM Set default output file if not specified
if "%OUTPUT_FILE%"=="" (
    for %%f in ("%INPUT_FILE%") do set OUTPUT_FILE=%%~nf.json
    echo Output file not specified, using: %OUTPUT_FILE%
)

echo Final parameters:
echo   Input: %INPUT_FILE%
echo   Output: %OUTPUT_FILE%
echo.

REM Check if input file exists
if not exist "%INPUT_FILE%" (
    echo Error: Input file does not exist: %INPUT_FILE%
    echo.
    echo Troubleshooting tips:
    echo 1. Check the file path is correct
    echo 2. Use absolute paths if relative paths don't work
    echo 3. Ensure the file exists and you have read permissions
    echo 4. Check that the file is a valid ADExplorer .dat file
    echo.
    pause
    exit /b 1
)

echo Input file exists, proceeding with conversion...
echo.

REM Use PowerShell with execution policy bypass
echo Converting ADExplorer file to BloodHound format...
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& {. '%~dp0robust-convert.ps1' -InputFile '%INPUT_FILE%' -OutputFile '%OUTPUT_FILE%'}"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Conversion completed successfully!
    echo ✓ Output written to: %OUTPUT_FILE%
) else (
    echo.
    echo ✗ Conversion failed with error code: %ERRORLEVEL%
    echo.
    echo Check the error messages above for troubleshooting.
)

echo.
pause
