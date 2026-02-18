@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM  Self-Contained Project Initialization Script
REM
REM  This script automates environment setup using 'uv'.
REM  1. Ensures 'uv' is installed.
REM  2. Ensures a Python version is installed via 'uv python install'.
REM  3. Creates a fresh virtual environment and installs packages.
REM  4. Installs a predefined list of packages into the venv.
REM ============================================================================

echo --- Starting Project Initialization ---
echo .
echo This script will:
echo  1. Check for 'uv'; if not found, installs it via its official script.
echo  2. Ensure a Python version is installed via 'uv python install'.
echo  3. Create a fresh virtual environment in '.venv'.
echo  4. Install a predefined list of packages into the venv.
pause

:check_uv
echo.
echo [1/3] Checking for uv...
uv --version >nul 2>&1
if %errorlevel% equ 0 (
    echo 'uv' is already installed.
    goto :install_python
)

echo 'uv' not found. Attempting to install it now...
powershell -ExecutionPolicy ByPass -NoProfile -Command "irm https://astral.sh/uv/install.ps1 | iex"
if %errorlevel% neq 0 (
    echo ERROR: Failed to install 'uv' using the official installer script.
    goto :error
)

echo 'uv' has been installed. Adding it to the PATH for this session...
set "PATH=%USERPROFILE%\.local\bin;%PATH%"

rem Verify uv installation
uv --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: 'uv' was installed but is not available in the PATH.
    echo Please restart your terminal and run this script again.
    goto :error
)
echo 'uv' installed successfully.

:install_python
echo.
echo [2/3] Ensuring Python is available via uv...
uv python install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install or find a suitable Python version using 'uv'.
    goto :error
)
echo Python is available.

:create_env_and_install
echo.
echo [3/3] Creating virtual environment and installing packages...

uv venv .venv --clear --seed
if %errorlevel% neq 0 (
    echo ERROR: Failed to create the virtual environment.
    goto :error
)
echo Virtual environment created in '.\.venv'.

rem Define packages to be installed
set "packages=numpy sympy scipy matplotlib marimo imageio pandas pyqt6 pyqtgraph ipykernel MechanicsKit"

echo Installing packages: %packages%
call .\.venv\Scripts\activate.bat
uv pip install %packages%
if %errorlevel% neq 0 (
    echo ERROR: Failed to install packages.
    call .\.venv\Scripts\deactivate.bat
    goto :error
)
call .\.venv\Scripts\deactivate.bat

echo.
echo --- Initialization Complete! ---
echo Your project environment is ready in the '.venv' folder.
goto :end

:error
echo.
echo --- Initialization Failed ---
pause
exit /b 1

:end
endlocal
pause