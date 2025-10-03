@echo off
REM Simple batch file to run the ADExplorer conversion
REM Usage: run-conversion.bat inputfile.dat [outputfile.json]

if "%1"=="" (
    echo Usage: run-conversion.bat inputfile.dat [outputfile.json]
    echo.
    echo Examples:
    echo   run-conversion.bat adexplorer.dat
    echo   run-conversion.bat adexplorer.dat bloodhound.json
    pause
    exit /b 1
)

if "%2"=="" (
    powershell -ExecutionPolicy Bypass -File "Convert-ADExplorer.ps1" -InputFile "%1"
) else (
    powershell -ExecutionPolicy Bypass -File "Convert-ADExplorer.ps1" -InputFile "%1" -OutputFile "%2"
)

pause
