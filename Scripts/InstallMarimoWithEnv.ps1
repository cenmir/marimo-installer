# Mechanical Engineering Python Development Setup

# --- Set Execution Policy for Current User ---
# This allows PowerShell scripts to run without being blocked
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne 'Bypass' -and $currentPolicy -ne 'Unrestricted') {
    Write-Host "Setting PowerShell execution policy to Bypass for current user..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
    Write-Host "Execution policy updated. Scripts will now run without issues." -ForegroundColor Green
}

# --- Define Paths ---
$InstallDir = "$env:USERPROFILE\marimo"
$SourceDir = $PSScriptRoot
$StartMenuPath = [System.Environment]::GetFolderPath('Programs')
$MarimoStartMenuFolder = Join-Path $StartMenuPath "Marimo"

# Check for administrative privileges
#if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#    Write-Warning "This script needs to be run with Administrator privileges to install Marimo and modify system settings."
#    Write-Host "Please right-click on the script and select 'Run as administrator'."
#    Read-Host -Prompt "Press Enter to exit..."
#    exit 1
#}

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Mechanical Engineering Python Development Setup"         -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "By Mirza Cenanovic"                                      -ForegroundColor Cyan
Write-Host "January 2026"
Write-Host ""
Write-Host "This will install the following (if not already installed):"                             -ForegroundColor Cyan
Write-Host " 1. Git"                                                                                 -ForegroundColor Cyan
Write-Host " 2. VS Code"                                                                             -ForegroundColor Cyan
Write-Host " 3. uv and python"                                                                       -ForegroundColor Cyan
Write-Host " 4. Create a virtual environment in %USERPROFILE%\.venvs\default"                        -ForegroundColor Cyan
Write-Host " 5. Copy Marimo files to %USERPROFILE%\marimo"                                           -ForegroundColor Cyan
Write-Host " 6. Create Start Menu folder and shortcuts"                                              -ForegroundColor Cyan
Write-Host " 7. Add context menu entries for Marimo and VS Code"                                     -ForegroundColor Cyan
Write-Host " 8. Add the marimo install folder to your user PATH"                                     -ForegroundColor Cyan


Read-Host "Press Enter to continue or Ctrl+C to cancel..."

# 1. Install Git
Write-Host "Installing Git..."
& "$SourceDir\InstallGit.ps1"

# 2. Install VS Code
Write-Host "Installing VS Code..."
& "$SourceDir\InstallVSCode.ps1"

# 3. Install uv and Python
Write-Host "Installing Python..."
& "$SourceDir\InstallPython.ps1"

# 4. Create default venv and install packages
Write-Host "Creating virtual environment and installing packages..."
& "$SourceDir\createDefaultVenvAndInstallPackages.ps1"

Write-Host "Setting up installation directory and shortcuts..."
# 5. Create installation directory and copy files
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}
Get-ChildItem -Path $SourceDir | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $InstallDir -Force
}

# 6. Create Start Menu folder
if (-not (Test-Path $MarimoStartMenuFolder)) {
    New-Item -Path $MarimoStartMenuFolder -ItemType Directory | Out-Null
}

# 7. Create Shortcuts using WScript.Shell COM object
$WshShell = New-Object -ComObject WScript.Shell

# Marimo Launcher Shortcut
$Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Marimo.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimo.ps1`" `"$env:USERPROFILE`""
$Shortcut.IconLocation = "$InstallDir\mo.ico"
$Shortcut.Description = "Launch Marimo"
$Shortcut.Save()


# Uninstall Shortcut
$Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Uninstall Marimo.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\uninstall.ps1`""
$Shortcut.IconLocation = "$InstallDir\mo.ico"
$Shortcut.Description = "Uninstall Marimo"
$Shortcut.Save()

Write-Host "Adding 'Open with Marimo' to context menus, this may take a minute..."
# For Files: "Open with Marimo"
$regKeyFile = "HKCU:\Software\Classes\*\shell\Open with Marimo"
$regCommandFile = "$regKeyFile\command"
New-Item -Path $regKeyFile -Force | Out-Null
New-Item -Path $regCommandFile -Force | Out-Null
Set-ItemProperty -Path $regKeyFile -Name "(Default)" -Value "Open with Marimo"
Set-ItemProperty -Path $regKeyFile -Name "Icon" -Value "$InstallDir\mo.ico"
$commandValueFile = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimoFile.ps1`" `"%1`""
Set-ItemProperty -Path $regCommandFile -Name "(Default)" -Value $commandValueFile


# For Folder Backgrounds: "Open in Marimo"
$regKeyDir = "HKCU:\Software\Classes\Directory\Background\shell\Marimo"
$regCommandDir = "$regKeyDir\command"
New-Item -Path $regKeyDir -Force | Out-Null
New-Item -Path $regCommandDir -Force | Out-Null
Set-ItemProperty -Path $regKeyDir -Name "(Default)" -Value "Open in Marimo"
Set-ItemProperty -Path $regKeyDir -Name "Icon" -Value "$InstallDir\mo.ico"
$commandValueDir = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimo.ps1`" `"%V`""
Set-ItemProperty -Path $regCommandDir -Name "(Default)" -Value $commandValueDir

Write-Host "Adding Marimo to your user PATH..."
Push-Location -Path $InstallDir
. ".\activate.ps1" "install"
Pop-Location

Write-Host "Setup complete."
