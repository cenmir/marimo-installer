# runMarimoFile.ps1

# This script is designed to be called from a Windows right-click context menu
# to open a Python file with Marimo in the same PowerShell window.

# --- Check for Updates ---
. "$PSScriptRoot\checkUpdate.ps1"
Test-MarimoUpdate -ScriptDir $PSScriptRoot

# --- Configuration ---
# Define the path to your default virtual environment.
# IMPORTANT: Make sure this path is correct for your system.
# Example: $env:USERPROFILE\venvs\default
$venvPath = Join-Path -Path $env:USERPROFILE -ChildPath ".venvs\default"

# --- Script Logic ---

# Get the full path of the clicked Python file from the arguments.
# $args[0] contains the path passed by the right-click context menu.
$filePath = $args[0]

# Get the directory and file name from the full path.
$fileDir = Split-Path -Path $filePath -Parent
$fileName = Split-Path -Path $filePath -Leaf

# Define the path to the virtual environment activation script.
$activateScriptPath = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"

# Check if the virtual environment activation script exists.
# If not, display an error and keep the window open for the user to read.
if (-not (Test-Path -Path $activateScriptPath)) {
    Write-Host "Error: Virtual environment activation script not found at:" -ForegroundColor Red
    Write-Host "$activateScriptPath" -ForegroundColor Red
    Write-Host "Please ensure this path is correct and Marimo is installed in that environment." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 1 # Exit with an error code if the venv isn't found
}

# Use a try-catch block to handle potential errors during activation or Marimo launch.
# This ensures the window stays open to display any error messages.
try {
    Write-Host "Activating virtual environment: $venvPath" -ForegroundColor Cyan
    # Activate the virtual environment.
    # The '.' operator runs the script in the current scope, making 'marimo' available.
    . $activateScriptPath

    Write-Host "Changing directory to: $fileDir" -ForegroundColor Cyan
    # Change to the directory of the clicked Python file.
    # This is important for Marimo to resolve relative paths in your notebook.
    Set-Location -Path $fileDir

    Write-Host "Launching Marimo for: $fileName" -ForegroundColor Green
    Write-Host "Press Ctrl+C in this window to stop Marimo." -ForegroundColor Yellow
    # Launch Marimo directly in the current console window.
    # This replaces 'Start-Process' to keep the output in the same window.
    # The -NoToken flag disables authentication for local development.
    # If you want authentication, remove --no-token.
    marimo edit "$fileName" --no-token

} catch {
    # If an error occurs in the try block, catch it here.
    Write-Host "An error occurred during script execution:" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please review the error message above." -ForegroundColor Yellow
}

# This Read-Host will ensure the PowerShell window remains open
# after Marimo exits (either successfully or due to an error/Ctrl+C).
# The user must press Enter to close the window.
Read-Host "Marimo session ended. Press Enter to close this window..."
