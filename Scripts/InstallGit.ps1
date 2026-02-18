function Test-GitInstalled {
    $gitPath = (Get-Command git -ErrorAction SilentlyContinue).Path
    if ($gitPath) {
        Write-Host "Git found: $gitPath" -ForegroundColor Green
        Write-Host "Git version: $(git --version)"
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
    # Refresh PATH from registry to pick up changes from installers
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Install-GitWithWinget {
    Write-Host "Installing Git using winget..." -ForegroundColor Cyan

    try {
        winget install Git.Git --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Git installed successfully via winget." -ForegroundColor Green

            # Refresh PATH to pick up the new git installation
            Refresh-PathEnvironment

            # Verify git is now available
            if (Test-GitInstalled) {
                return $true
            } else {
                Write-Warning "Git was installed but is not yet in PATH. You may need to restart your terminal."
                return $true  # Installation succeeded, just PATH issue
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

function Show-ManualInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL GIT INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "winget is not available on this system."
    Write-Host "Please install Git manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host "  2. Download the installer for your system (64-bit recommended)"
    Write-Host "  3. Run the installer with default settings"
    Write-Host "  4. Restart this installer after Git is installed"
    Write-Host ""
    Write-Host "Alternatively, if you have access to Microsoft Store:"
    Write-Host "  - Install 'App Installer' to get winget"
    Write-Host "  - Then re-run this installer"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-Git {
    Write-Host "Checking for Git installation..." -ForegroundColor Cyan

    # Check if git is already installed
    if (Test-GitInstalled) {
        Write-Host "Git is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "Git not found. Attempting to install..." -ForegroundColor Yellow

    # Check if winget is available
    if (Test-WingetAvailable) {
        Write-Host "winget is available." -ForegroundColor Green
        return Install-GitWithWinget
    } else {
        Write-Warning "winget is not available on this system."
        Show-ManualInstallInstructions
        return $false
    }
}

function Test-GitConfigured {
    $userName = git config --global user.name 2>$null
    $userEmail = git config --global user.email 2>$null

    if ($userName -and $userEmail) {
        return $true
    }
    return $false
}

function Set-GitConfig {
    Write-Host ""
    Write-Host "Git Configuration" -ForegroundColor Cyan
    Write-Host "-----------------" -ForegroundColor Cyan

    # Check if already configured
    $existingName = git config --global user.name 2>$null
    $existingEmail = git config --global user.email 2>$null

    if ($existingName -and $existingEmail) {
        Write-Host "Git is already configured:" -ForegroundColor Green
        Write-Host "  Name:  $existingName"
        Write-Host "  Email: $existingEmail"

        $reconfigure = Read-Host "Do you want to change these settings? (y/N)"
        if ($reconfigure -notmatch '^[Yy]') {
            Write-Host "Keeping existing configuration." -ForegroundColor Green
            return $true
        }
    }

    Write-Host ""
    Write-Host "Please enter your details for Git commits:" -ForegroundColor Yellow
    Write-Host "(This identifies you as the author of your code)"
    Write-Host ""

    # Prompt for name
    $userName = Read-Host "Your name (e.g., 'John Doe')"
    if ([string]::IsNullOrWhiteSpace($userName)) {
        Write-Warning "Name cannot be empty. Git configuration skipped."
        Write-Host "You can configure later with: git config --global user.name 'Your Name'"
        return $false
    }

    # Prompt for email
    $userEmail = Read-Host "Your email (e.g., 'john.doe@example.com')"
    if ([string]::IsNullOrWhiteSpace($userEmail)) {
        Write-Warning "Email cannot be empty. Git configuration skipped."
        Write-Host "You can configure later with: git config --global user.email 'your@email.com'"
        return $false
    }

    # Set the configuration
    try {
        git config --global user.name $userName
        git config --global user.email $userEmail

        Write-Host ""
        Write-Host "Git configured successfully!" -ForegroundColor Green
        Write-Host "  Name:  $userName"
        Write-Host "  Email: $userEmail"
        return $true
    }
    catch {
        Write-Error "Failed to configure Git: $($_.Exception.Message)"
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$gitInstalled = Install-Git

if ($gitInstalled) {
    Write-Host ""
    Write-Host "Git installation complete!" -ForegroundColor Green

    # Configure git user.name and user.email
    Set-GitConfig
} else {
    Write-Host ""
    Write-Host "Git installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}