# Mechanical Engineering Python Development Setup - One-liner bootstrap script
# Usage: irm https://raw.githubusercontent.com/cenmir/python-dev-installer/main/download.ps1 | iex

$ErrorActionPreference = "Stop"

# Force TLS 1.2 (required by GitHub, not default on older PowerShell)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoUrl = "https://github.com/cenmir/python-dev-installer/archive/refs/heads/main.zip"
$tempDir = Join-Path $env:TEMP "python-dev-installer-$(Get-Random)"
$zipPath = Join-Path $tempDir "python-dev-installer.zip"

try {
    Write-Host "Downloading installer..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Disable progress bar for faster download
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
    $ProgressPreference = 'Continue'

    if (-not (Test-Path $zipPath)) {
        throw "Download failed - ZIP file not found"
    }

    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    $extractedDir = Join-Path $tempDir "python-dev-installer-main"
    $installScript = Join-Path $extractedDir "Scripts\Install.ps1"

    if (-not (Test-Path $installScript)) {
        throw "Extraction failed - installer script not found at $installScript"
    }

    Write-Host "Running installer..." -ForegroundColor Cyan
    & $installScript

    Write-Host ""
    Write-Host "Installation finished." -ForegroundColor Green
    Write-Host "You can now find Marimo in your Start Menu."
    Write-Host "NOTE: You may need to sign out and back in for the context menu changes to appear everywhere."
}
catch {
    Write-Host ""
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "If the problem persists, try the manual installation:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://github.com/cenmir/python-dev-installer/archive/refs/heads/main.zip"
    Write-Host "  2. Extract and run setup.bat"
    throw
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
