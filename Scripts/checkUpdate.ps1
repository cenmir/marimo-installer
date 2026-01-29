# checkUpdate.ps1
# This script checks for updates from GitHub releases.
# Designed to be dot-sourced from other scripts: . "$PSScriptRoot\checkUpdate.ps1"

function Test-MarimoUpdate {
    param(
        [string]$ScriptDir = $PSScriptRoot,
        [int]$CheckIntervalHours = 24,
        [int]$TimeoutSeconds = 3
    )

    $configPath = Join-Path $ScriptDir "config.json"
    $versionPath = Join-Path $ScriptDir "version.txt"
    $repoApi = "https://api.github.com/repos/cenmir/python-dev-installer/releases/latest"

    # Read local version
    if (-not (Test-Path $versionPath)) {
        return  # No version file, skip check
    }
    $localVersion = (Get-Content $versionPath -Raw).Trim()

    # Read config
    $config = $null
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            return  # Invalid config, skip check
        }
    } else {
        return  # No config file, skip check
    }

    # Check if enough time has passed since last check
    if ($config.lastUpdateCheck) {
        try {
            $lastCheck = [DateTime]::Parse($config.lastUpdateCheck)
            $hoursSinceCheck = ((Get-Date) - $lastCheck).TotalHours
            if ($hoursSinceCheck -lt $CheckIntervalHours) {
                return  # Checked recently, skip
            }
        } catch {
            # Invalid date, continue with check
        }
    }

    # Fetch latest release from GitHub (with timeout)
    try {
        $ProgressPreference = 'SilentlyContinue'
        $release = Invoke-RestMethod -Uri $repoApi -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        $latestVersion = $release.tag_name

        # Update last check time
        $config.lastUpdateCheck = (Get-Date).ToString("o")
        $config | ConvertTo-Json | Set-Content $configPath -Encoding UTF8

        # Compare versions (simple string comparison works for vX.Y.Z format)
        if ($latestVersion -ne $localVersion) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host " Update available: $localVersion -> $latestVersion" -ForegroundColor Yellow
            Write-Host " Run 'Update Marimo' from Start Menu" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        # Silently fail - user might be offline
        # Still update the check time to avoid repeated failures
        try {
            $config.lastUpdateCheck = (Get-Date).ToString("o")
            $config | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
        } catch {
            # Ignore errors when saving config
        }
    }
}

# Auto-run if executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Test-MarimoUpdate
}
