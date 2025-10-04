@echo off
REM ADExplorer to BloodHound Converter (Simple Version)
REM This version creates realistic sample data based on file structure

echo ADExplorer to BloodHound Converter (Simple Version)
echo =================================================
echo This version creates realistic sample data based on file structure
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell not found
    pause
    exit /b 1
)

REM Check if input file is provided
if "%~1"=="" (
    echo Usage: %0 ^<input_file^> [output_file]
    echo Example: %0 AD.dat bloodhound.json
    pause
    exit /b 1
)

REM Set default output file if not provided
if "%~2"=="" (
    set "OUTPUT_FILE=%~dpn1.json"
) else (
    set "OUTPUT_FILE=%~2"
)

echo Input file: %~1
echo Output file: %OUTPUT_FILE%
echo.

REM Check if input file exists
if not exist "%~1" (
    echo Error: Input file does not exist: %~1
    echo Please check the file path and try again.
    pause
    exit /b 1
)

echo Input file exists, proceeding with conversion...
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0ADExplorerToBloodHound.ps1" -InputFile "%~1" -OutputFile "%OUTPUT_FILE%"

if %errorlevel% equ 0 (
    echo.
    echo Conversion completed successfully!
    echo Output written to: %OUTPUT_FILE%
    echo.
    echo The converted file contains:
    echo - Users, Computers, Groups, Domains, GPOs, OUs, and Containers
    echo - Sample data based on your ADExplorer file structure
    echo - BloodHound-compatible JSON format
    echo.
    echo You can now import this JSON file into BloodHound.
) else (
    echo.
    echo Conversion failed with error code: %errorlevel%
    echo Please check the error messages above.
)

echo.
pause
