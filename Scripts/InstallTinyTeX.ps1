function Test-LaTeXInstalled {
    $pdflatex = (Get-Command pdflatex -ErrorAction SilentlyContinue).Path
    if ($pdflatex) {
        Write-Host "LaTeX found: $pdflatex" -ForegroundColor Green
        Write-Host "pdflatex version: $(pdflatex --version | Select-Object -First 1)"
        return $true
    }
    $xelatex = (Get-Command xelatex -ErrorAction SilentlyContinue).Path
    if ($xelatex) {
        Write-Host "LaTeX found: $xelatex" -ForegroundColor Green
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Install-TinyTeXFromGitHub {
    Write-Host "Downloading TinyTeX from GitHub..." -ForegroundColor Cyan
    Write-Host "This may take a few minutes (~120 MB)." -ForegroundColor Yellow

    try {
        # Get the latest release download URL for TinyTeX-1 (includes common LaTeX packages)
        $releasesApi = "https://api.github.com/repos/rstudio/tinytex-releases/releases/latest"
        $ProgressPreference = 'SilentlyContinue'
        $release = Invoke-RestMethod -Uri $releasesApi -UseBasicParsing
        $ProgressPreference = 'Continue'

        $asset = $release.assets | Where-Object { $_.name -match '^TinyTeX-1-.*\.zip$' } | Select-Object -First 1
        if (-not $asset) {
            Write-Error "Could not find TinyTeX-1 ZIP in the latest release."
            return $false
        }

        $downloadUrl = $asset.browser_download_url
        $zipPath = Join-Path $env:TEMP "TinyTeX-1.zip"
        $installDir = "$env:APPDATA\TinyTeX"

        Write-Host "Downloading $($asset.name) ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

        Write-Host "Extracting to $installDir ..." -ForegroundColor Cyan
        if (Test-Path $installDir) {
            Remove-Item $installDir -Recurse -Force
        }
        Expand-Archive -Path $zipPath -DestinationPath $env:APPDATA -Force

        # Clean up ZIP
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        # Add TinyTeX bin to user PATH
        $binDir = "$installDir\bin\windows"
        if (-not (Test-Path $binDir)) {
            # Some releases use win32 instead of windows
            $binDir = "$installDir\bin\win32"
        }

        if (Test-Path $binDir) {
            $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            if ($userPath -notlike "*$binDir*") {
                [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$binDir", "User")
                Write-Host "Added $binDir to user PATH." -ForegroundColor Green
            }
        }

        Refresh-PathEnvironment

        if (Test-LaTeXInstalled) {
            return $true
        } else {
            Write-Warning "TinyTeX was installed but pdflatex is not yet in PATH. You may need to restart your terminal."
            return $true
        }
    }
    catch {
        Write-Error "Error during TinyTeX installation: $($_.Exception.Message)"
        return $false
    }
}

function Show-ManualTinyTeXInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL TINYTEX INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install TinyTeX manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://github.com/rstudio/tinytex-releases/releases" -ForegroundColor Cyan
    Write-Host "  2. Download TinyTeX-1-*.zip for Windows"
    Write-Host "  3. Extract to %APPDATA%\TinyTeX"
    Write-Host "  4. Add %APPDATA%\TinyTeX\bin\windows to your PATH"
    Write-Host "  5. Restart this installer after TinyTeX is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-TinyTeX {
    Write-Host "Checking for LaTeX installation..." -ForegroundColor Cyan

    if (Test-LaTeXInstalled) {
        Write-Host "A LaTeX distribution is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "No LaTeX distribution found. Attempting to install TinyTeX..." -ForegroundColor Yellow

    $result = Install-TinyTeXFromGitHub
    if ($result) {
        return $true
    } else {
        Show-ManualTinyTeXInstallInstructions
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$tinyTexInstalled = Install-TinyTeX

if ($tinyTexInstalled) {
    Write-Host ""
    Write-Host "TinyTeX installation complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "TinyTeX installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
