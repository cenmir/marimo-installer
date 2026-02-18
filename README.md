# Mechanical Engineering Python Development Setup

This repository contains installation files for setting up a Python development environment for Mechanical Engineering courses at JTH (School of Engineering, Jönköping University). It installs Git, VS Code, Quarto, Python, and the Marimo notebook editor on Windows.

For Mac or Linux users, please refer to the [Marimo installation guide for Mac/Linux](https://python.ju.se/python_installation.html#manual-python-installation).

## Quick Install

Open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/cenmir/python-dev-installer/main/install.ps1 | iex
```

> **Execution policy error?** If PowerShell blocks the script, run this first to allow scripts for the current user:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## Alternative: Manual download

1. Download the repo as a ZIP file and extract it
2. Run `setup.bat` by double-clicking it
3. Follow the on-screen instructions

## What the installer does

### Software Installation
- **Git** - Version control (prompts for name/email configuration)
- **VS Code** - Code editor with context menu integration
- **Quarto** - Scientific and technical publishing
- **uv** - Fast Python package manager
- **Python** - Latest version via uv

### VS Code Configuration
- Installs **Python extension** (ms-python.python)
- Installs **Jupyter extension** (ms-toolsai.jupyter)
- Sets default Python interpreter to `~/.venvs/default`

### Python Environment
- Creates virtual environment at `C:\Users\username\.venvs\default`
- Installs packages: numpy, sympy, scipy, matplotlib, marimo, imageio, pyqt6, pyqtgraph, pandas, ipykernel, MechanicsKit
- Packages are configurable via `requirements.txt`

### Marimo Setup
- Copies run scripts to `C:\Users\username\marimo`
- Adds marimo folder to user PATH
- Creates Start Menu shortcuts
- Adds "Open with Marimo" context menu
- Configures dark mode by default (`~/.marimo.toml`)

### Windows Configuration
- Adds "Open with VS Code" context menu
- Enables classic context menu (removes Windows 11 "Show more options")

## Usage

- **Launch Marimo**: Right-click in a folder and select "Open in Marimo", or use the Start Menu shortcut, or type `m` in the command line
- **Open in VS Code**: Right-click on any folder and select "Open with VS Code"
- **Update packages**: Double-click `update.bat` in `C:\Users\username\marimo`
- **Uninstall**: Double-click `uninstall.bat` in `C:\Users\username\marimo`

## Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| Marimo config | `~/.marimo.toml` | Theme and display settings |
| VS Code settings | `%APPDATA%\Code\User\settings.json` | Python interpreter path |
| Package list | `requirements.txt` | Packages to install in venv |

## Project-specific Virtual Environments

For VS Code users who want separate dependencies per project: copy `Scripts/init.bat` to your project folder and double-click it. This creates a `.venv` folder that VS Code will automatically detect and use.
