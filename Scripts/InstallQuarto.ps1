function Test-QuartoInstalled {
    $quartoPath = (Get-Command quarto -ErrorAction SilentlyContinue).Path
    if ($quartoPath) {
        Write-Host "Quarto found: $quartoPath" -ForegroundColor Green
        Write-Host "Quarto version: $(quarto --version)"
        return $true
    }
    return $false
}

function Test-WingetAvailable {
    $wingetPath = (Get-Command winget -ErrorAction SilentlyContinue).Path
    if ($wingetPath) {
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Install-QuartoWithWinget {
    Write-Host "Installing Quarto using winget..." -ForegroundColor Cyan

    try {
        winget install Posit.Quarto --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Quarto installed successfully via winget." -ForegroundColor Green
            Refresh-PathEnvironment

            if (Test-QuartoInstalled) {
                return $true
            } else {
                Write-Warning "Quarto was installed but is not yet in PATH. You may need to restart your terminal."
                return $true
            }
        } else {
            Write-Error "winget install failed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Error during winget installation: $($_.Exception.Message)"
        return $false
    }
}

function Show-ManualQuartoInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL QUARTO INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "winget is not available on this system."
    Write-Host "Please install Quarto manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://quarto.org/docs/get-started/" -ForegroundColor Cyan
    Write-Host "  2. Download the Windows installer"
    Write-Host "  3. Run the installer with default settings"
    Write-Host "  4. Restart this installer after Quarto is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-Quarto {
    Write-Host "Checking for Quarto installation..." -ForegroundColor Cyan

    if (Test-QuartoInstalled) {
        Write-Host "Quarto is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "Quarto not found. Attempting to install..." -ForegroundColor Yellow

    if (Test-WingetAvailable) {
        Write-Host "winget is available." -ForegroundColor Green
        return Install-QuartoWithWinget
    } else {
        Write-Warning "winget is not available on this system."
        Show-ManualQuartoInstallInstructions
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$quartoInstalled = Install-Quarto

if ($quartoInstalled) {
    Write-Host ""
    Write-Host "Quarto installation complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Quarto installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
