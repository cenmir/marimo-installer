@echo off
echo Starting Python Development Environment installation...
echo.

set "SCRIPT_DIR=%~dp0"

REM Run the main PowerShell installation script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Scripts\Install.ps1"

REM Check if the previous command was successful
if %ERRORLEVEL% neq 0 (
    echo.
    echo PowerShell script failed to execute. Installation aborted.
    echo Please ensure the original ZIP file was "Unblocked" in its properties before extracting.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Installation finished.
echo You can now find Marimo in your Start Menu.
echo NOTE: You may need to sign out and back in for the context menu changes to appear everywhere.
echo.
pause