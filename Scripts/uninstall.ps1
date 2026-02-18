# Uninstaller for Python Development Environment
Write-Host "Starting Python Development Environment uninstallation..."

# --- Define Paths ---
$InstallDir = "$env:USERPROFILE\marimo"
$StartMenuPath = [System.Environment]::GetFolderPath('Programs')
$MarimoStartMenuFolder = Join-Path $StartMenuPath "Marimo"

# --- Remove Registry Keys ---
$regKeyFile = "HKCU:\Software\Classes\*\shell\Open with Marimo"
$regKeyDir = "HKCU:\Software\Classes\Directory\Background\shell\Marimo"

if (Test-Path $regKeyFile) {
    Write-Host "Removing file context menu registry key..."
    Remove-Item -Path $regKeyFile -Recurse -Force
}
if (Test-Path $regKeyDir) {
    Write-Host "Removing directory context menu registry key..."
    Remove-Item -Path $regKeyDir -Recurse -Force
}

# --- Remove Start Menu Shortcuts and Folder ---
if (Test-Path $MarimoStartMenuFolder) {
    Write-Host "Removing Start Menu shortcuts and folder..."
    Remove-Item -Path $MarimoStartMenuFolder -Recurse -Force
}

# --- Optional: Remove default venv ---
$VenvDir = "$env:USERPROFILE\.venvs\default"
if (Test-Path $VenvDir) {
    Write-Host "Removing default virtual environment: $VenvDir"
    Remove-Item -Path $VenvDir -Recurse -Force
}

# --- Remove marimo from user PATH ---
Write-Host "Removing marimo from user PATH..."
$CurrentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentUserPath) {
    $pathEntries = $CurrentUserPath -split ";" | Where-Object {
        $_ -ne $InstallDir -and $_ -ne "$InstallDir\"
    }
    $NewUserPath = ($pathEntries -join ";").TrimEnd(";")
    [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
    Write-Host "Removed '$InstallDir' from user PATH." -ForegroundColor Green
}

# --- Final Step: Self-destruct the installation directory ---
# We can't delete the directory we are running from.
# So, we create a temporary batch file in %TEMP% to do it after this script exits.
Write-Host "Finalizing uninstallation..."

$TempBatchFile = Join-Path $env:TEMP "cleanup_marimo.bat"

# The batch file will wait 2 seconds for this script to close, 
# remove the installation directory, and then delete itself.
$BatchContent = @"
@echo off
timeout /t 2 /nobreak > NUL
rmdir /s /q "$InstallDir"
(goto) 2>nul & del "%~f0"
"@

$BatchContent | Out-File -FilePath $TempBatchFile -Encoding ascii

# Launch the batch file in a new, hidden window and exit this script immediately.
Start-Process cmd.exe -ArgumentList "/c `"$TempBatchFile`"" -WindowStyle Hidden

Write-Host "Python Development Environment uninstallation is complete."
# The final Read-Host is removed so this script can exit and unlock the directory.