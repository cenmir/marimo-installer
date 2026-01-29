# runMarimoTemp.ps1

# This script launches Marimo with a new file with a random memorable name.
# The target directory is read from config.json in the same folder.

# --- Check for Updates ---
. "$PSScriptRoot\checkUpdate.ps1"
Test-MarimoUpdate -ScriptDir $PSScriptRoot

# --- Configuration ---
$venvPath = Join-Path -Path $env:USERPROFILE -ChildPath ".venvs\default"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path -Path $scriptDir -ChildPath "config.json"

# Word lists for random name generation
$adjectives = @(
    "quick", "swift", "bright", "calm", "bold", "cool", "warm", "wild",
    "deep", "soft", "sharp", "clear", "fresh", "light", "dark", "pure",
    "keen", "wise", "free", "true", "fair", "kind", "rare", "rich",
    "blue", "red", "green", "gold", "silver", "amber", "jade", "coral"
)

$nouns = @(
    "river", "mountain", "forest", "ocean", "cloud", "storm", "wind", "rain",
    "star", "moon", "sun", "sky", "leaf", "stone", "wave", "flame",
    "bird", "wolf", "bear", "fox", "hawk", "owl", "deer", "lion",
    "path", "dream", "spark", "dawn", "dusk", "tide", "frost", "bloom"
)

# --- Read Config ---
$targetDir = $env:USERPROFILE  # Default fallback

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($config.tempDirectory) {
            # Expand environment variables like %USERPROFILE%
            $targetDir = [System.Environment]::ExpandEnvironmentVariables($config.tempDirectory)
        }
    } catch {
        Write-Host "Warning: Could not read config.json, using default directory." -ForegroundColor Yellow
    }
}

# --- Script Logic ---
$activateScriptPath = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"

if (-not (Test-Path -Path $activateScriptPath)) {
    Write-Host "Error: Virtual environment activation script not found at:" -ForegroundColor Red
    Write-Host "$activateScriptPath" -ForegroundColor Red
    Write-Host "Please ensure this path is correct and Marimo is installed in that environment." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 1
}

# Check target directory exists
if (-not (Test-Path -Path $targetDir)) {
    Write-Host "Error: Target directory not found:" -ForegroundColor Red
    Write-Host "$targetDir" -ForegroundColor Red
    Write-Host "Please update config.json with a valid directory path." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 1
}

try {
    Write-Host "Activating virtual environment: $venvPath" -ForegroundColor Cyan
    . $activateScriptPath

    Write-Host "Changing directory to: $targetDir" -ForegroundColor Cyan
    Set-Location -Path $targetDir

    # Generate a random memorable filename
    $adj = $adjectives | Get-Random
    $noun = $nouns | Get-Random
    $tempFileName = "marimo_${adj}_${noun}.py"
    $tempFilePath = Join-Path -Path $targetDir -ChildPath $tempFileName

    # If file already exists, add a number
    $counter = 2
    while (Test-Path -Path $tempFilePath) {
        $tempFileName = "marimo_${adj}_${noun}_${counter}.py"
        $tempFilePath = Join-Path -Path $targetDir -ChildPath $tempFileName
        $counter++
    }

    Write-Host "Creating: $tempFileName" -ForegroundColor Green
    Write-Host "Press Ctrl+C in this window to stop Marimo." -ForegroundColor Yellow

    marimo edit --no-token $tempFilePath

} catch {
    Write-Host "An error occurred during script execution:" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please review the error message above." -ForegroundColor Yellow
}

Read-Host "Marimo session ended. Press Enter to close this window..."
