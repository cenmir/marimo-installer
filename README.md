# Mechanical Engineering Python Development Setup

This repository contains installation files for setting up a Python development environment for Mechanical Engineering courses at JTH (School of Engineering, Jönköping University). It installs Git, VS Code, Python, and the Marimo notebook editor on Windows.

For Mac or Linux users, please refer to the [Marimo installation guide for Mac/Linux](https://python.ju.se/python_installation.html#manual-python-installation).

## What the installer does

The installer will:
- Install Git (and configure your name/email for commits)
- Install VS Code with context menu integration
- Install the package manager uv
- Install the latest version of Python
- Create a virtual environment at `C:\Users\username\.venvs\default`
- Install packages, including Marimo, into the virtual environment along with numpy, sympy, matplotlib, pandas, pyqt6, pyqtgraph and scipy. This is configurable using the `requirements.txt` file.
- Copy the run scripts to a folder in `C:\Users\username\marimo` and put that folder in your user PATH environment variable
- Create shortcuts to launch Marimo
- Create context menu entries for Marimo and VS Code

## Installation Instructions

### Option 1: One-liner (recommended)

Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/cenmir/python-dev-installer/main/install.ps1 | iex
```

### Option 2: Manual download

1. Download the repo as a ZIP file and extract it to a folder on your computer.
2. Open the extracted folder and run the `setup.bat` file by double-clicking it.
3. Follow the on-screen instructions to complete the installation process.

## Usage

- You can launch Marimo by right-clicking in a folder and selecting "Open in Marimo" or by using the shortcut in the Start Menu.
- You can also run Marimo from the command line by typing `m`.
- You can open any folder in VS Code by right-clicking and selecting "Open with VS Code".
- To update Marimo and packages, double-click `update.bat` in `C:\Users\username\marimo`.
- To uninstall, double-click `uninstall.bat` in `C:\Users\username\marimo`.


### Easy .venv setup for new projects for vs-code users

There is a useful file in Scripts called `init.bat` which you can copy to a new project folder and double-clicking it will create a virtual environment (.venv) for that project and install the above mentioned packages. Useful if you want to keep dependencies separate between projects. VS-Code will automatically detect the .venv folder and use it as the Python interpreter for that project.
