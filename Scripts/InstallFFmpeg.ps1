function Test-FFmpegInstalled {
    $ffmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Path
    if ($ffmpegPath) {
        Write-Host "FFmpeg found: $ffmpegPath" -ForegroundColor Green
        Write-Host "FFmpeg version: $(ffmpeg -version | Select-Object -First 1)"
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Download-AndExtractFFmpeg {
    param(
        [string]$DownloadUrl,
        [string]$Label
    )

    $zipPath = Join-Path $env:TEMP "ffmpeg-download.zip"
    $installDir = "$env:LOCALAPPDATA\FFmpeg"

    # Download with progress bar using chunked .NET stream
    $request = [System.Net.HttpWebRequest]::Create($DownloadUrl)
    $request.AllowAutoRedirect = $true
    $response = $request.GetResponse()
    $totalBytes = $response.ContentLength
    $stream = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($zipPath)
    $buffer = New-Object byte[] 262144
    $totalRead = 0
    $lastPct = -1

    while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $bytesRead)
        $totalRead += $bytesRead
        if ($totalBytes -gt 0) {
            $pct = [int](($totalRead / $totalBytes) * 100)
            if ($pct -ne $lastPct) {
                $mbRead = [math]::Round($totalRead / 1MB, 1)
                $mbTotal = [math]::Round($totalBytes / 1MB, 1)
                Write-Progress -Activity "Downloading FFmpeg ($Label)" -Status "${mbRead} MB / ${mbTotal} MB" -PercentComplete $pct
                $lastPct = $pct
            }
        }
    }

    $fileStream.Close()
    $stream.Close()
    $response.Close()
    Write-Progress -Activity "Downloading FFmpeg ($Label)" -Completed

    Write-Host "Extracting to $installDir ..." -ForegroundColor Cyan
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
    }

    # Extract to temp first, then move the inner folder
    $extractTemp = Join-Path $env:TEMP "ffmpeg-extract"
    if (Test-Path $extractTemp) {
        Remove-Item $extractTemp -Recurse -Force
    }

    $tarExe = Get-Command tar.exe -ErrorAction SilentlyContinue
    if ($tarExe) {
        New-Item -Path $extractTemp -ItemType Directory | Out-Null
        & tar.exe -xf $zipPath -C $extractTemp
    } else {
        Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
    }

    # The ZIP contains a versioned folder — move it to the install dir
    $innerFolder = Get-ChildItem -Path $extractTemp -Directory | Select-Object -First 1
    if ($innerFolder) {
        Move-Item -Path $innerFolder.FullName -Destination $installDir -Force
    } else {
        Move-Item -Path $extractTemp -Destination $installDir -Force
    }

    # Clean up
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

    # Add FFmpeg bin to user PATH
    $binDir = "$installDir\bin"
    if (Test-Path $binDir) {
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -notlike "*$binDir*") {
            [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$binDir", "User")
            Write-Host "Added $binDir to user PATH." -ForegroundColor Green
        }
    }

    Refresh-PathEnvironment
}

function Show-ManualFFmpegInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL FFMPEG INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install FFmpeg manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Cyan
    Write-Host "  2. Download the 'ffmpeg-release-essentials' ZIP"
    Write-Host "  3. Extract to a folder (e.g., C:\ffmpeg)"
    Write-Host "  4. Add the 'bin' folder to your PATH"
    Write-Host "  5. Restart this installer after FFmpeg is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-FFmpeg {
    Write-Host "Checking for FFmpeg installation..." -ForegroundColor Cyan

    if (Test-FFmpegInstalled) {
        Write-Host "FFmpeg is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "FFmpeg not found. Attempting to install..." -ForegroundColor Yellow

    # Try gyan.dev first (official FFmpeg-recommended source)
    try {
        Write-Host "Downloading FFmpeg from gyan.dev..." -ForegroundColor Cyan
        Download-AndExtractFFmpeg -DownloadUrl "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -Label "gyan.dev"

        if (Test-FFmpegInstalled) { return $true }
        Write-Warning "FFmpeg was installed but is not yet in PATH. You may need to restart your terminal."
        return $true
    }
    catch {
        Write-Warning "gyan.dev download failed: $($_.Exception.Message)"
    }

    # Fallback to GitHub (BtbN builds, also official FFmpeg-recommended)
    try {
        Write-Host "Trying fallback: GitHub (BtbN)..." -ForegroundColor Cyan
        Download-AndExtractFFmpeg -DownloadUrl "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip" -Label "GitHub"

        if (Test-FFmpegInstalled) { return $true }
        Write-Warning "FFmpeg was installed but is not yet in PATH. You may need to restart your terminal."
        return $true
    }
    catch {
        Write-Warning "GitHub download failed: $($_.Exception.Message)"
    }

    Show-ManualFFmpegInstallInstructions
    return $false
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$ffmpegInstalled = Install-FFmpeg

if ($ffmpegInstalled) {
    Write-Host ""
    Write-Host "FFmpeg installation complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FFmpeg installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
