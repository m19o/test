@echo off
REM ADExplorer to BloodHound Converter - CMD Version
REM This bypasses PowerShell execution policy issues

echo ADExplorer to BloodHound Converter
echo ==================================

if "%1"=="" (
    echo Usage: convert-adexplorer.cmd inputfile.dat [outputfile.json]
    echo.
    echo Examples:
    echo   convert-adexplorer.cmd adexplorer.dat
    echo   convert-adexplorer.cmd adexplorer.dat bloodhound.json
    pause
    exit /b 1
)

set INPUT_FILE=%1
set OUTPUT_FILE=%2

if "%OUTPUT_FILE%"=="" (
    set OUTPUT_FILE=%~n1.json
)

echo Input file: %INPUT_FILE%
echo Output file: %OUTPUT_FILE%
echo.

REM Check if input file exists
if not exist "%INPUT_FILE%" (
    echo Error: Input file does not exist: %INPUT_FILE%
    pause
    exit /b 1
)

REM Use PowerShell with execution policy bypass
echo Converting ADExplorer file to BloodHound format...
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& {. '%~dp0Convert-ADExplorer.ps1' -InputFile '%INPUT_FILE%' -OutputFile '%OUTPUT_FILE%'}"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Conversion completed successfully!
    echo ✓ Output written to: %OUTPUT_FILE%
) else (
    echo.
    echo ✗ Conversion failed with error code: %ERRORLEVEL%
)

echo.
pause
