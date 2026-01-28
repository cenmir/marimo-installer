function Test-AndInstallUv {
    Write-Host "Checking for uv installation..." -ForegroundColor Cyan

    # Check if uv command exists
    # Use the expected installation path first
    $uvLocalBinPath = Join-Path $env:USERPROFILE ".local\bin"
    $uvExePath = Join-Path $uvLocalBinPath "uv.exe"

    if (Test-Path $uvExePath) {
        Write-Host "uv found at the expected local path: $uvExePath" -ForegroundColor Green
        # Ensure it's in the current session's PATH if not already
        if (-not ($env:Path -like "*$([System.Text.RegularExpressions.Regex]::Escape($uvLocalBinPath))*")) {
            Write-Host "Adding '$uvLocalBinPath' to the current PowerShell session's PATH..."
            $env:Path += ";$uvLocalBinPath"
        }
        return $true
    } else {
        # Fallback check if it somehow got into the default PATH already (e.g., via cargo)
        $uvPathInSystem = (Get-Command uv -ErrorAction SilentlyContinue).Path
        if ($uvPathInSystem) {
            Write-Host "uv found in system PATH: $uvPathInSystem"
            return $true
        }

        Write-Warning "uv not found on the system in expected locations."
        Write-Host "Attempting to install uv..."

        try {
            Write-Host "Running uv installer (this may take a moment)..."
            # Execute the uv installation command
            # This command will usually place uv.exe in %USERPROFILE%\.local\bin
            Invoke-Expression "powershell -ExecutionPolicy ByPass -c 'irm https://astral.sh/uv/install.ps1 | iex'"

            # After installation, uv might not be immediately available in the current session's PATH.
            # We'll explicitly add the expected install directory to the current session's PATH.
            if (Test-Path $uvLocalBinPath) {
                Write-Host "Adding '$uvLocalBinPath' to the current PowerShell session's PATH..."
                $env:Path += ";$uvLocalBinPath"

                # Verify uv is now available in this session's PATH
                $uvPathAfterInstall = (Get-Command uv -ErrorAction SilentlyContinue).Path
                if ($uvPathAfterInstall) {
                    Write-Host "uv successfully installed and added to session PATH: $uvPathAfterInstall" -ForegroundColor Green
                    return $true
                } else {
                    Write-Error "uv installation completed, but uv command still not found in session PATH even after adding. Manual PATH check or restart may be needed."
                    return $false
                }
            } else {
                Write-Error "uv installation directory ($uvLocalBinPath) not found after installation attempt. uv might not have installed correctly."
                return $false
            }
        }
        catch {
            Write-Error "An error occurred during uv installation: $($_.Exception.Message)"
            return $false
        }
    }
}

function Install-LatestPythonWithUv {
    Write-Host "Attempting to install the latest Python version using uv..." -ForegroundColor Cyan

    Write-Host "Running: uv python install --default --preview"
    # Run uv and capture exit code (don't use 2>&1 as it creates ErrorRecords that throw with $ErrorActionPreference=Stop)
    uv python install --default --preview
    $uvExitCode = $LASTEXITCODE

    if ($uvExitCode -eq 0) {
        Write-Host "Successfully installed Python using uv." -ForegroundColor Green

        # Verify Python is now available
        $pythonCheckPath = (Get-Command python -ErrorAction SilentlyContinue).Path
        if ($pythonCheckPath) {
            Write-Host "Verified: Python is now callable at: $pythonCheckPath" -ForegroundColor Green
            $pythonVersion = & python --version 2>&1
            Write-Host "Python version: $pythonVersion" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "Python was installed but 'python' command not found in PATH. You may need to restart PowerShell."
            return $true  # Installation succeeded, just PATH issue
        }
    } else {
        Write-Error "Failed to install Python using uv. Exit code: $uvExitCode"
        return $false
    }
}




## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

# 1. Check and install uv
$uvOk = Test-AndInstallUv

if ($uvOk) {
    Write-Host "uv is available. Proceeding to install Python with uv."
    # 2. Install the latest Python version using uv
    $pythonInstalled = Install-LatestPythonWithUv
    if ($pythonInstalled) {
        Write-Host "Python has been installed and is ready to use!"
    } else {
        Write-Warning "Python installation via uv failed or could not be verified."
    }
} else {
    Write-Error "uv was not found or failed to install correctly. Cannot proceed with Python installation."
}

Write-Host "Python installation script has completed."
# Pause the script execution until a key is pressed.
#Read-Host -Prompt "Script finished. Press Enter to exit..."


