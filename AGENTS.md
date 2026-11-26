# AGENTS.md — open-fonts-installer

## Overview
Zero-dependency interactive and CLI installer scripts for downloading, installing, and uninstalling 19 popular open-source fonts across three categories (**Persian/Arabic RTL**, **Coding/Monospace**, **UI/Sans-Serif**) on **macOS**, **Linux**, and **Windows**. Fetches the latest GitHub Releases automatically with pinned fallback URLs for rate-limit resilience.

## Tech Stack & Requirements
- **macOS / Linux**: Bash (`#!/usr/bin/env bash`, `set -euo pipefail`), `curl`, `unzip`, `find` (plus `fc-cache` on Linux)
- **Windows**: PowerShell 7+ (`#Requires -Version 7.0`, `Set-StrictMode -Version Latest`), inline C# P/Invoke (`gdi32.dll` `AddFontResourceW`/`RemoveFontResourceW`, `user32.dll` `SendMessageTimeoutW` for `WM_FONTCHANGE`)

## Repository Structure
```text
open-fonts-installer/
├── install-fonts.sh    # macOS, Linux, and Git Bash/WSL Bash installer (755 lines)
├── install-fonts.ps1   # Native Windows PowerShell 7 installer (669 lines, no admin required)
├── README.md           # Quick start, CLI examples, and full 19-font catalog table
└── LICENSE             # MIT License (fonts retain their upstream licenses)
```

## Architecture & Key Flows
- **Dual-Script Parity**: Both `install-fonts.sh` and `install-fonts.ps1` embed the exact same 19-entry `FONT_CATALOG` (`persian`: 7 fonts, `code`: 8 fonts, `ui`: 4 fonts), each specifying `id`, display name, category, GitHub `owner/repo`, release asset regex, pinned fallback URL, and description.
- **Install Flow**:
  1. Resolve target fonts via interactive multi-select menu (supports numbers, ranges like `1-3,8`, or category names) or non-interactive CLI flags.
  2. Query GitHub Releases API (`latest`) for an asset matching the font's regex; fall back to the pinned release URL on API failure/rate-limit.
  3. Extract `.ttf`/`.otf` files into an isolated per-font subfolder (`<FONT_BASE_DIR>/<font-id>/`) so uninstalling is clean and exact.
  4. Refresh OS font caches: macOS discovers user fonts automatically; Linux runs `fc-cache -f`; Windows writes per-user entries to `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts` and broadcasts `WM_FONTCHANGE` (no admin rights or reboot needed).
- **Default Install Paths**:
  - macOS: `~/Library/Fonts/open-fonts/<font-id>/`
  - Linux: `${XDG_DATA_HOME:-$HOME/.local/share}/fonts/open-fonts/<font-id>/`
  - Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\open-fonts\<font-id>\`

## Development & Commands
- **macOS / Linux (`install-fonts.sh`)**:
  ```bash
  ./install-fonts.sh                                  # Interactive selector
  ./install-fonts.sh --list                           # List all fonts & IDs
  ./install-fonts.sh --installed                      # Show installed fonts
  ./install-fonts.sh --category persian               # Install category (persian | code | ui)
  ./install-fonts.sh --dry-run vazirmatn dastkhat     # Preview without downloading
  ./install-fonts.sh --dir ~/my-fonts vazirmatn       # Custom install directory
  ./install-fonts.sh --uninstall vazirmatn,inter      # Uninstall specific fonts
  ```
- **Windows PowerShell 7 (`install-fonts.ps1`)**:
  ```powershell
  pwsh -ExecutionPolicy Bypass -File .\install-fonts.ps1
  .\install-fonts.ps1 -List
  .\install-fonts.ps1 -Installed
  .\install-fonts.ps1 -Fonts vazirmatn,dastkhat,jetbrains-mono
  .\install-fonts.ps1 -Category code
  .\install-fonts.ps1 -All -DryRun
  .\install-fonts.ps1 -Dir "$HOME\my-fonts" -Fonts vazirmatn
  .\install-fonts.ps1 -Uninstall vazirmatn,inter
  ```
- **Syntax checks**:
  ```bash
  bash -n install-fonts.sh
  pwsh -NoProfile -Command '$null = [System.Management.Automation.Language.Parser]::ParseFile("install-fonts.ps1", [ref]$null, [ref]$errors); $errors'
  ```

## Configuration & Environment
- `GITHUB_TOKEN`: Optional GitHub personal access token (env var on both macOS/Linux and Windows) to avoid GitHub's 60 req/hr unauthenticated API limit.
- `NO_COLOR=1`: Disables ANSI color output in `install-fonts.sh`.
- `XDG_DATA_HOME`: Respected on Linux for the default font base directory.

## Conventions & Gotchas
- **Keep both scripts in sync**: Any new font, updated fallback URL, regex fix, or CLI flag MUST be mirrored across `install-fonts.sh`, `install-fonts.ps1`, and the table in `README.md`.
- **Regex syntax differences**: `install-fonts.sh` uses POSIX/grep regexes on pipe-delimited catalog strings, while `install-fonts.ps1` uses .NET regexes in `[PSCustomObject]` entries. Test asset regex matching against real GitHub Release asset URLs on both.
- **No external dependencies**: Do not introduce `jq`, `python`, or PowerShell modules — both scripts are meant to run via `curl | bash` and `irm | iex`.
- **Temp cleanup**: `install-fonts.sh` cleans up `TMP_DIR` via `trap cleanup EXIT INT TERM`; ensure temporary extraction directories in both scripts are always cleaned up on failure.
