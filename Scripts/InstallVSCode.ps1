function Test-VSCodeInstalled {
    # Check common installation paths
    $vscodePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    )

    foreach ($path in $vscodePaths) {
        if (Test-Path $path) {
            Write-Host "VS Code found: $path" -ForegroundColor Green
            return $true
        }
    }

    # Also check if 'code' command is in PATH
    $codePath = (Get-Command code -ErrorAction SilentlyContinue).Path
    if ($codePath) {
        Write-Host "VS Code found in PATH: $codePath" -ForegroundColor Green
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

function Install-VSCodeWithWinget {
    Write-Host "Installing VS Code using winget..." -ForegroundColor Cyan

    try {
        winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "VS Code installed successfully via winget." -ForegroundColor Green
            Refresh-PathEnvironment

            if (Test-VSCodeInstalled) {
                return $true
            } else {
                Write-Warning "VS Code was installed but may need a terminal restart to be in PATH."
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

function Show-ManualVSCodeInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL VS CODE INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "winget is not available on this system."
    Write-Host "Please install VS Code manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://code.visualstudio.com/download" -ForegroundColor Cyan
    Write-Host "  2. Download the installer for Windows"
    Write-Host "  3. Run the installer"
    Write-Host "  4. IMPORTANT: Check 'Add to PATH' during installation"
    Write-Host "  5. Restart this installer after VS Code is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-VSCodeExtensions {
    Write-Host "Installing VS Code extensions..." -ForegroundColor Cyan

    $extensions = @(
        "ms-python.python",
        "ms-toolsai.jupyter"
    )

    # Check if 'code' command is available
    $codePath = (Get-Command code -ErrorAction SilentlyContinue).Path
    if (-not $codePath) {
        Write-Warning "VS Code 'code' command not found in PATH. Extensions not installed."
        Write-Host "You may need to restart your terminal and run the installer again." -ForegroundColor Yellow
        return $false
    }

    foreach ($ext in $extensions) {
        Write-Host "  Installing $ext..." -ForegroundColor Gray
        code --install-extension $ext --force 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Installed $ext" -ForegroundColor Green
        } else {
            Write-Warning "  Failed to install $ext"
        }
    }

    Write-Host "VS Code extensions installation complete." -ForegroundColor Green
    return $true
}

function Set-VSCodePythonSettings {
    Write-Host "Configuring VS Code Python settings..." -ForegroundColor Cyan

    $settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
    $settingsDir = Split-Path $settingsPath -Parent

    # Ensure the directory exists
    if (-not (Test-Path $settingsDir)) {
        New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
    }

    # Read existing settings or create empty object
    $settings = @{}
    if (Test-Path $settingsPath) {
        try {
            $content = Get-Content $settingsPath -Raw
            if ($content) {
                $settings = $content | ConvertFrom-Json -AsHashtable
            }
        }
        catch {
            Write-Warning "Could not parse existing settings.json. Creating backup and starting fresh."
            Copy-Item $settingsPath "$settingsPath.backup" -Force
            $settings = @{}
        }
    }

    # Set Python interpreter path using VS Code variable
    $venvPythonPath = "`${userHome}\.venvs\default\Scripts\python.exe"
    $settings["python.defaultInterpreterPath"] = $venvPythonPath

    # Write settings back
    try {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "VS Code configured to use default venv at ~/.venvs/default" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to write VS Code settings: $($_.Exception.Message)"
        return $false
    }
}

function Add-VSCodeContextMenu {
    Write-Host "Adding 'Open with VS Code' to folder context menu..." -ForegroundColor Cyan

    try {
        # Find VS Code executable
        $vscodePath = $null
        $possiblePaths = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
            "$env:ProgramFiles\Microsoft VS Code\Code.exe",
            "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $vscodePath = $path
                break
            }
        }

        if (-not $vscodePath) {
            Write-Warning "Could not find VS Code executable. Context menu not added."
            return $false
        }

        # Add context menu for folder backgrounds (right-click inside folder)
        $regKeyDir = "HKCU:\Software\Classes\Directory\Background\shell\VSCode"
        $regCommandDir = "$regKeyDir\command"
        New-Item -Path $regKeyDir -Force | Out-Null
        New-Item -Path $regCommandDir -Force | Out-Null
        Set-ItemProperty -Path $regKeyDir -Name "(Default)" -Value "Open with VS Code"
        Set-ItemProperty -Path $regKeyDir -Name "Icon" -Value "`"$vscodePath`""
        Set-ItemProperty -Path $regCommandDir -Name "(Default)" -Value "`"$vscodePath`" `"%V`""

        # Add context menu for folders (right-click on folder)
        $regKeyFolder = "HKCU:\Software\Classes\Directory\shell\VSCode"
        $regCommandFolder = "$regKeyFolder\command"
        New-Item -Path $regKeyFolder -Force | Out-Null
        New-Item -Path $regCommandFolder -Force | Out-Null
        Set-ItemProperty -Path $regKeyFolder -Name "(Default)" -Value "Open with VS Code"
        Set-ItemProperty -Path $regKeyFolder -Name "Icon" -Value "`"$vscodePath`""
        Set-ItemProperty -Path $regCommandFolder -Name "(Default)" -Value "`"$vscodePath`" `"%V`""

        Write-Host "VS Code context menu entries added successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to add context menu: $($_.Exception.Message)"
        return $false
    }
}

function Install-VSCode {
    Write-Host "Checking for VS Code installation..." -ForegroundColor Cyan

    if (Test-VSCodeInstalled) {
        Write-Host "VS Code is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "VS Code not found. Attempting to install..." -ForegroundColor Yellow

    if (Test-WingetAvailable) {
        Write-Host "winget is available." -ForegroundColor Green
        return Install-VSCodeWithWinget
    } else {
        Write-Warning "winget is not available on this system."
        Show-ManualVSCodeInstallInstructions
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$vscodeInstalled = Install-VSCode

if ($vscodeInstalled) {
    Write-Host ""
    Write-Host "VS Code installation complete!" -ForegroundColor Green

    # Add context menu entry
    Add-VSCodeContextMenu

    # Install extensions (Python, Jupyter)
    Install-VSCodeExtensions

    # Configure Python settings
    Set-VSCodePythonSettings
} else {
    Write-Host ""
    Write-Host "VS Code installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
