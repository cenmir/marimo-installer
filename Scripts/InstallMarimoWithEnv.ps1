# Mechanical Engineering Python Development Setup

# --- Set Execution Policy for Current User ---
# This allows PowerShell scripts to run without being blocked
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne 'Bypass' -and $currentPolicy -ne 'Unrestricted') {
    Write-Host "Setting PowerShell execution policy to Bypass for current user..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Execution policy updated." -ForegroundColor Green
    }
    catch {
        # This can fail if a Group Policy overrides user settings - that's OK, continue anyway
        Write-Host "Could not change execution policy (may be controlled by Group Policy). Continuing..." -ForegroundColor Yellow
    }
}

# --- Define Paths ---
$InstallDir = "$env:USERPROFILE\marimo"
$SourceDir = $PSScriptRoot
$StartMenuPath = [System.Environment]::GetFolderPath('Programs')
$MarimoStartMenuFolder = Join-Path $StartMenuPath "Marimo"

# --- Interactive Selection Menu ---
function Show-InstallMenu {
    param(
        [string[]]$MenuItems
    )

    $selected = [bool[]](@($true) * $MenuItems.Count)
    $pos = 0

    [Console]::CursorVisible = $false
    $startPos = $Host.UI.RawUI.CursorPosition

    while ($true) {
        $Host.UI.RawUI.CursorPosition = $startPos
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            $check = if ($selected[$i]) { "X" } else { " " }
            $prefix = if ($i -eq $pos) { ">" } else { " " }
            $color = if ($i -eq $pos) { "Yellow" } else { "Cyan" }
            $text = " $prefix [$check] $($MenuItems[$i])"
            $pad = ' ' * [Math]::Max(0, [Console]::WindowWidth - $text.Length - 1)
            Write-Host "$text$pad" -ForegroundColor $color
        }
        Write-Host ""
        $help = "  Up/Down: navigate | Space: toggle | A: all | N: none | Enter: continue"
        Write-Host "$help$(' ' * [Math]::Max(0, [Console]::WindowWidth - $help.Length - 1))" -ForegroundColor DarkGray

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow'   { $pos = if ($pos -gt 0) { $pos - 1 } else { $MenuItems.Count - 1 } }
            'DownArrow' { $pos = if ($pos -lt $MenuItems.Count - 1) { $pos + 1 } else { 0 } }
            'Spacebar'  { $selected[$pos] = -not $selected[$pos] }
            'A'         { for ($i = 0; $i -lt $selected.Count; $i++) { $selected[$i] = $true } }
            'N'         { for ($i = 0; $i -lt $selected.Count; $i++) { $selected[$i] = $false } }
            'Enter'     { [Console]::CursorVisible = $true; Write-Host ""; return $selected }
        }
    }
}

# --- Banner ---
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Mechanical Engineering Python Development Setup"         -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "By Mirza Cenanovic"                                      -ForegroundColor Cyan
Write-Host "February 2026"
Write-Host ""
Write-Host "Select components to install:"                           -ForegroundColor Cyan
Write-Host ""

$menuItems = @(
    "Git"
    "VS Code with Python and Jupyter extensions"
    "Quarto (scientific publishing)"
    "TinyTeX (LaTeX for PDF rendering)"
    "uv and Python"
    "Virtual environment and packages"
    "Marimo files, shortcuts and context menus"
    "Marimo dark mode"
    "Classic context menu (Windows 11)"
)

$choices = Show-InstallMenu $menuItems

# 1. Install Git
if ($choices[0]) {
    Write-Host "Installing Git..."
    & "$SourceDir\InstallGit.ps1"
}

# 2. Install VS Code
if ($choices[1]) {
    Write-Host "Installing VS Code..."
    & "$SourceDir\InstallVSCode.ps1"
}

# 3. Install Quarto
if ($choices[2]) {
    Write-Host "Installing Quarto..."
    & "$SourceDir\InstallQuarto.ps1"
}

# 4. Install TinyTeX
if ($choices[3]) {
    Write-Host "Installing TinyTeX..."
    & "$SourceDir\InstallTinyTeX.ps1"
}

# 5. Install uv and Python
if ($choices[4]) {
    Write-Host "Installing Python..."
    & "$SourceDir\InstallPython.ps1"
}

# 6. Create default venv and install packages
if ($choices[5]) {
    Write-Host "Creating virtual environment and installing packages..."
    & "$SourceDir\createDefaultVenvAndInstallPackages.ps1"
}

# 7. Marimo files, shortcuts and context menus
if ($choices[6]) {
    Write-Host "Setting up installation directory and shortcuts..."

    # Create installation directory and copy files
    if (-not (Test-Path $InstallDir)) {
        New-Item -Path $InstallDir -ItemType Directory | Out-Null
    }
    Get-ChildItem -Path $SourceDir | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $InstallDir -Force
    }

    # Create Start Menu folder
    if (-not (Test-Path $MarimoStartMenuFolder)) {
        New-Item -Path $MarimoStartMenuFolder -ItemType Directory | Out-Null
    }

    # Create Shortcuts using WScript.Shell COM object
    $WshShell = New-Object -ComObject WScript.Shell

    # Marimo Launcher Shortcut
    $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Marimo.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimo.ps1`" `"$env:USERPROFILE`""
    $Shortcut.IconLocation = "$InstallDir\mo.ico"
    $Shortcut.Description = "Launch Marimo"
    $Shortcut.Save()

    # Marimo New Notebook Shortcut (creates a new file with random name)
    $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Marimo New Notebook.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimoTemp.ps1`""
    $Shortcut.IconLocation = "$InstallDir\mo.ico"
    $Shortcut.Description = "Launch Marimo with a new notebook"
    $Shortcut.Save()

    # Update Marimo Shortcut
    $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Update Marimo.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\updateScripts.ps1`""
    $Shortcut.IconLocation = "$InstallDir\mo.ico"
    $Shortcut.Description = "Update Marimo scripts to the latest version"
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
}

# 8. Configure Marimo dark mode
if ($choices[7]) {
    Write-Host "Configuring Marimo dark mode..."
    $marimoConfigPath = Join-Path $env:USERPROFILE ".marimo.toml"
    if (-not (Test-Path $marimoConfigPath)) {
        # Use ASCII encoding without BOM to avoid TOML parsing issues
        "[display]`ntheme = `"dark`"" | Set-Content $marimoConfigPath -Encoding ASCII -NoNewline
        # Add final newline
        Add-Content $marimoConfigPath ""
        Write-Host "Marimo configured to use dark mode." -ForegroundColor Green
    } else {
        Write-Host "Marimo config already exists, skipping dark mode setup." -ForegroundColor Yellow
    }
}

# 9. Enable classic context menu (Windows 11)
if ($choices[8]) {
    Write-Host "Enabling classic context menu (Windows 11)..."
    $classicMenuKey = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    try {
        New-Item -Path $classicMenuKey -Force | Out-Null
        Set-ItemProperty -Path $classicMenuKey -Name "(Default)" -Value ""
        Write-Host "Classic context menu enabled. Sign out and back in to apply." -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not enable classic context menu: $($_.Exception.Message)"
    }
}

Write-Host "Setup complete."
