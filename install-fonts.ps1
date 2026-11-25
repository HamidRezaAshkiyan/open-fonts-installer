#Requires -Version 7.0
<#
.SYNOPSIS
    Open Fonts Installer for Windows (PowerShell 7+)
.DESCRIPTION
    Interactive and CLI script to download and install famous open-source fonts
    (Persian/Arabic, Coding/Monospace, UI/Sans-Serif) on Windows without requiring
    Administrator privileges.
.EXAMPLE
    .\install-fonts.ps1
    .\install-fonts.ps1 -List
    .\install-fonts.ps1 -Installed
    .\install-fonts.ps1 -Fonts vazirmatn,dastkhat,jetbrains-mono
    .\install-fonts.ps1 -Category persian
    .\install-fonts.ps1 -All -DryRun
    .\install-fonts.ps1 -Uninstall vazirmatn,inter
#>

[CmdletBinding()]
param(
    [switch]$List,
    [switch]$Installed,
    [switch]$All,
    [ValidateSet("", "persian", "code", "ui")]
    [string]$Category = "",
    [string[]]$Fonts = @(),
    [string[]]$Uninstall = @(),
    [string]$Dir = "",
    [switch]$DryRun,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Ensure TLS 1.2 for GitHub API on Windows PowerShell 5.1
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    # Ignore on platforms where SecurityProtocol is managed by OS
}

$VERSION = "1.0.0"

# --- Font Catalog -------------------------------------------------------------
$FONT_CATALOG = @(
    [PSCustomObject]@{ Id = "vazirmatn";         Name = "Vazirmatn";               Category = "persian"; Repo = "rastikerdar/vazirmatn";        Regex = "vazirmatn-v.*\.zip$";          Fallback = "https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip";                                                          Desc = "Modern Persian/Arabic & Latin UI typeface" }
    [PSCustomObject]@{ Id = "dastkhat";          Name = "Dastkhat";                Category = "persian"; Repo = "dastyar-io/dastkhat-font";     Regex = "Dastkhat-v.*\.zip$";           Fallback = "https://github.com/dastyar-io/dastkhat-font/releases/download/v1.220/Dastkhat-v1.220.zip";                                                           Desc = "Persian & Latin typeface with dot variants & Mono" }
    [PSCustomObject]@{ Id = "estedad";           Name = "Estedad";                 Category = "persian"; Repo = "aminabedi68/Estedad";          Regex = "Estedad-v.*\.zip$";            Fallback = "https://github.com/aminabedi68/Estedad/releases/download/8.5/Estedad-v8.5.zip";                                                                      Desc = "Clean geometric Persian & Latin sans-serif" }
    [PSCustomObject]@{ Id = "shabnam";           Name = "Shabnam";                 Category = "persian"; Repo = "rastikerdar/shabnam-font";     Regex = "shabnam-font-v.*\.zip$";       Fallback = "https://github.com/rastikerdar/shabnam-font/releases/download/v5.0.1/shabnam-font-v5.0.1.zip";                                                    Desc = "Popular Persian UI typeface" }
    [PSCustomObject]@{ Id = "sahel";             Name = "Sahel";                   Category = "persian"; Repo = "rastikerdar/sahel-font";       Regex = "sahel-font-v.*\.zip$";         Fallback = "https://github.com/rastikerdar/sahel-font/releases/download/v3.4.0/sahel-font-v3.4.0.zip";                                                        Desc = "Readable Persian typeface for body & UI" }
    [PSCustomObject]@{ Id = "samim";             Name = "Samim";                   Category = "persian"; Repo = "rastikerdar/samim-font";       Regex = "samim-font-v.*\.zip$";         Fallback = "https://github.com/rastikerdar/samim-font/releases/download/v4.0.5/samim-font-v4.0.5.zip";                                                        Desc = "Clean and balanced Persian typeface" }
    [PSCustomObject]@{ Id = "vazir-code";        Name = "Vazir Code";              Category = "persian"; Repo = "rastikerdar/vazir-code-font";  Regex = "vazir-code-font-v.*\.zip$";    Fallback = "https://github.com/rastikerdar/vazir-code-font/releases/download/v1.1.2/vazir-code-font-v1.1.2.zip";                                              Desc = "Monospace coding font with Persian support" }
    [PSCustomObject]@{ Id = "jetbrains-mono";    Name = "JetBrains Mono";          Category = "code";    Repo = "JetBrains/JetBrainsMono";      Regex = "JetBrainsMono-.*\.zip$";       Fallback = "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip";                                                      Desc = "Developer monospace font with ligatures" }
    [PSCustomObject]@{ Id = "jetbrains-mono-nf"; Name = "JetBrainsMono Nerd Font"; Category = "code";    Repo = "ryanoasis/nerd-fonts";         Regex = "/JetBrainsMono\.zip$";         Fallback = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip";                                                              Desc = "JetBrains Mono patched with Nerd Font icons" }
    [PSCustomObject]@{ Id = "fira-code";         Name = "Fira Code";               Category = "code";    Repo = "tonsky/FiraCode";              Regex = "Fira_Code_v.*\.zip$";          Fallback = "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip";                                                                     Desc = "Monospace font with programming ligatures" }
    [PSCustomObject]@{ Id = "cascadia-code";     Name = "Cascadia Code";           Category = "code";    Repo = "microsoft/cascadia-code";      Regex = "CascadiaCode-.*\.zip$";        Fallback = "https://github.com/microsoft/cascadia-code/releases/download/v2407.24/CascadiaCode-2407.24.zip";                                                  Desc = "Microsoft modern terminal & coding font" }
    [PSCustomObject]@{ Id = "monaspace";         Name = "Monaspace";               Category = "code";    Repo = "githubnext/monaspace";         Regex = "monaspace-static-v.*\.zip$";   Fallback = "https://github.com/githubnext/monaspace/releases/download/v1.400/monaspace-static-v1.400.zip";                                                    Desc = "GitHub Next 5-family coding superfamilies" }
    [PSCustomObject]@{ Id = "hack";              Name = "Hack";                    Category = "code";    Repo = "source-foundry/Hack";          Regex = "Hack-.*-ttf\.zip$";            Fallback = "https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip";                                                             Desc = "Crisp monospace typeface designed for source code" }
    [PSCustomObject]@{ Id = "maple-mono";        Name = "Maple Mono";              Category = "code";    Repo = "subframe7536/maple-font";      Regex = "MapleMono-TTF\.zip$";          Fallback = "https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-TTF.zip";                                                               Desc = "Rounded monospace font with ligatures" }
    [PSCustomObject]@{ Id = "source-code-pro";   Name = "Source Code Pro";         Category = "code";    Repo = "adobe-fonts/source-code-pro";  Regex = "TTF-source-code-pro-.*\.zip$"; Fallback = "https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R-u%2F1.062R-i%2F1.026R-vf/TTF-source-code-pro-2.042R-u_1.062R-i.zip";          Desc = "Adobe open-source monospace font" }
    [PSCustomObject]@{ Id = "inter";             Name = "Inter";                   Category = "ui";      Repo = "rsms/inter";                   Regex = "Inter-.*\.zip$";               Fallback = "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip";                                                                                Desc = "Carefully crafted typeface for computer screens" }
    [PSCustomObject]@{ Id = "geist";             Name = "Geist";                   Category = "ui";      Repo = "vercel/geist-font";            Regex = "geist-font-v.*\.zip$";         Fallback = "https://github.com/vercel/geist-font/releases/download/v1.9.2/geist-font-v1.9.2.zip";                                                             Desc = "Vercel minimalist sans & mono typeface" }
    [PSCustomObject]@{ Id = "ibm-plex-sans";     Name = "IBM Plex Sans";           Category = "ui";      Repo = "IBM/plex";                     Regex = "ibm-plex-sans\.zip$";          Fallback = "https://github.com/IBM/plex/releases/download/%40ibm%2Fplex-sans%401.1.0/ibm-plex-sans.zip";                                                       Desc = "IBM open-source corporate sans-serif" }
    [PSCustomObject]@{ Id = "roboto";            Name = "Roboto";                  Category = "ui";      Repo = "googlefonts/roboto-2";         Regex = "roboto-unhinted\.zip$";        Fallback = "https://github.com/googlefonts/roboto-2/releases/download/v2.138/roboto-unhinted.zip";                                                              Desc = "Google classic neo-grotesque sans-serif" }
)

$CATEGORIES = @(
    @{ Key = "persian"; Title = "Persian / Arabic (RTL)" }
    @{ Key = "code";    Title = "Coding / Monospace" }
    @{ Key = "ui";      Title = "UI / Sans-Serif" }
)

# --- Install Directory & Windows Registry -------------------------------------
$FONT_REG_PATH = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
if ([string]::IsNullOrWhiteSpace($Dir)) {
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $FONT_BASE_DIR = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts\open-fonts"
    } else {
        $FONT_BASE_DIR = Join-Path $HOME "Fonts\open-fonts"
    }
} else {
    $FONT_BASE_DIR = $Dir
}

$IS_WINDOWS = ($env:OS -eq "Windows_NT") -or ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)

# Load Win32 GDI/User32 helpers for live font registration without reboot
$WIN32_LOADED = $false
if ($IS_WINDOWS) {
    try {
        if (-not ("OpenFonts.Win32Font" -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace OpenFonts {
    public static class Win32Font {
        [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
        public static extern int AddFontResourceW(string lpFileName);

        [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
        public static extern bool RemoveFontResourceW(string lpFileName);

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr SendMessageTimeoutW(
            IntPtr hWnd, uint Msg, UIntPtr wParam, IntPtr lParam,
            uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);

        public static void BroadcastFontChange() {
            UIntPtr result;
            SendMessageTimeoutW(new IntPtr(0xffff), 0x001D, UIntPtr.Zero, IntPtr.Zero, 0x0002, 1000, out result);
        }
    }
}
"@ -ErrorAction Stop
        }
        $WIN32_LOADED = $true
    } catch {
        $WIN32_LOADED = $false
    }
}

# --- Helpers ------------------------------------------------------------------
function Write-Info([string]$Text)    { Write-Host "==> " -ForegroundColor Blue -NoNewline; Write-Host $Text }
function Write-Ok([string]$Text)      { Write-Host "  [OK] " -ForegroundColor Green -NoNewline; Write-Host $Text }
function Write-WarnMsg([string]$Text) { Write-Host "  [!] " -ForegroundColor Yellow -NoNewline; Write-Host $Text }
function Write-ErrMsg([string]$Text)  { Write-Host "  [X] " -ForegroundColor Red -NoNewline; Write-Host $Text }

function Test-FontInstalled([string]$Id) {
    $targetDir = Join-Path $FONT_BASE_DIR $Id
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        return $false
    }
    $found = Get-ChildItem -LiteralPath $targetDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(ttf|otf)$' } |
        Select-Object -First 1
    return ($null -ne $found)
}

function Get-FontFileCount([string]$Id) {
    $targetDir = Join-Path $FONT_BASE_DIR $Id
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        return 0
    }
    return @(Get-ChildItem -LiteralPath $targetDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(ttf|otf)$' }).Count
}

function Find-FontIndexById([string]$Id) {
    for ($i = 0; $i -lt $FONT_CATALOG.Count; $i++) {
        if ($FONT_CATALOG[$i].Id -eq $Id) {
            return $i
        }
    }
    return -1
}

function Resolve-DownloadUrl($Font) {
    $apiUrl = "https://api.github.com/repos/$($Font.Repo)/releases/latest"
    $headers = @{
        "Accept"     = "application/vnd.github+json"
        "User-Agent" = "open-fonts-installer/$VERSION"
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)"
    }

    try {
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 12 -ErrorAction Stop
        if ($null -ne $release.assets) {
            foreach ($asset in $release.assets) {
                if ($asset.browser_download_url -match $Font.Regex) {
                    return $asset.browser_download_url
                }
            }
        }
    } catch {
        # Fallback to pinned release URL on rate-limit or network issues
    }
    return $Font.Fallback
}

function Register-WindowsFont([string]$FilePath) {
    if (-not $IS_WINDOWS) { return }

    if (-not (Test-Path -LiteralPath $FONT_REG_PATH)) {
        New-Item -Path $FONT_REG_PATH -Force | Out-Null
    }

    $ext = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $typeLabel = if ($ext -eq ".otf") { "(OpenType)" } else { "(TrueType)" }
    $regName = "$baseName $typeLabel"

    New-ItemProperty -Path $FONT_REG_PATH -Name $regName -Value $FilePath -PropertyType String -Force | Out-Null

    if ($WIN32_LOADED) {
        try {
            [OpenFonts.Win32Font]::AddFontResourceW($FilePath) | Out-Null
        } catch {}
    }
}

function Unregister-WindowsFontsInDir([string]$TargetDir) {
    if (-not $IS_WINDOWS) { return }

    $normDir = $TargetDir.TrimEnd('\', '/') + '\'

    if ($WIN32_LOADED -and (Test-Path -LiteralPath $TargetDir)) {
        $files = Get-ChildItem -LiteralPath $TargetDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '^\.(ttf|otf)$' }
        foreach ($f in $files) {
            try {
                [OpenFonts.Win32Font]::RemoveFontResourceW($f.FullName) | Out-Null
            } catch {}
        }
    }

    if (Test-Path -LiteralPath $FONT_REG_PATH) {
        $props = Get-ItemProperty -Path $FONT_REG_PATH -ErrorAction SilentlyContinue
        if ($null -ne $props) {
            foreach ($p in $props.PSObject.Properties) {
                if ($p.Name -in @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                    continue
                }
                $val = [string]$p.Value
                if ($val.StartsWith($normDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                    Remove-ItemProperty -Path $FONT_REG_PATH -Name $p.Name -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function Notify-WindowsFontChange {
    if ($IS_WINDOWS -and $WIN32_LOADED -and (-not $DryRun)) {
        try {
            [OpenFonts.Win32Font]::BroadcastFontChange()
        } catch {}
    }
}

function Install-FontEntry($Font) {
    $targetDir = Join-Path $FONT_BASE_DIR $Font.Id
    Write-Info "Installing $($Font.Name) ($($Font.Repo))..."

    $url = Resolve-DownloadUrl $Font

    if ($DryRun) {
        Write-Host "  [dry-run] Would download: $url" -ForegroundColor Cyan
        Write-Host "  [dry-run] Would install to: $targetDir" -ForegroundColor Cyan
        return $true
    }

    $tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("open-fonts-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
    $zipFile = Join-Path $tmpRoot "font.zip"
    $extractDir = Join-Path $tmpRoot "extracted"

    try {
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

        $fileName = [System.IO.Path]::GetFileName(($url -split '\?')[0])
        Write-Host "  Downloading $fileName..." -ForegroundColor DarkGray

        $prevProgress = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing -TimeoutSec 300
        } finally {
            $ProgressPreference = $prevProgress
        }

        Write-Host "  Extracting font files..." -ForegroundColor DarkGray
        Expand-Archive -LiteralPath $zipFile -DestinationPath $extractDir -Force

        $allFiles = @(Get-ChildItem -LiteralPath $extractDir -Recurse -File | Where-Object {
            $_.Extension -match '^\.(ttf|otf)$' -and
            $_.FullName -notmatch '(__MACOSX|[\\/]webfonts[\\/]|[\\/]web[\\/]|[\\/]WOFF)' -and
            (-not $_.Name.StartsWith("._"))
        })

        if ($allFiles.Count -eq 0) {
            Write-ErrMsg "No .ttf or .otf files found in archive for $($Font.Name)"
            return $false
        }

        # Prefer static fonts over variable fonts if both exist in the same archive
        $staticFiles = @($allFiles | Where-Object {
            $lower = $_.FullName.ToLowerInvariant()
            (-not $lower.Contains("\variable\")) -and (-not $lower.Contains("/variable/")) -and (-not $lower.Contains("variable"))
        })

        $filesToInstall = if ($staticFiles.Count -gt 0) { $staticFiles } else { $allFiles }

        # Clean previous install of this font
        if (Test-Path -LiteralPath $targetDir) {
            Unregister-WindowsFontsInDir $targetDir
            Remove-Item -LiteralPath $targetDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

        $count = 0
        foreach ($f in $filesToInstall) {
            $dest = Join-Path $targetDir $f.Name
            Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
            Register-WindowsFont $dest
            $count++
        }

        Write-Ok "Installed $($Font.Name) ($count font files -> $targetDir)"
        return $true
    } catch {
        Write-ErrMsg "Failed to install $($Font.Name): $($_.Exception.Message)"
        return $false
    } finally {
        if (Test-Path -LiteralPath $tmpRoot) {
            Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Uninstall-FontById([string]$Id) {
    $targetDir = Join-Path $FONT_BASE_DIR $Id
    if (-not (Test-Path -LiteralPath $targetDir)) {
        Write-WarnMsg "$Id is not installed in $FONT_BASE_DIR"
        return
    }
    if ($DryRun) {
        Write-Host "  [dry-run] Would remove: $targetDir" -ForegroundColor Cyan
        return
    }
    Unregister-WindowsFontsInDir $targetDir
    Remove-Item -LiteralPath $targetDir -Recurse -Force
    Write-Ok "Uninstalled $Id ($targetDir)"
}

# --- Display & Menu -----------------------------------------------------------
function Show-Usage {
    Write-Host ""
    Write-Host "Open Fonts Installer v$VERSION (Windows PowerShell)" -ForegroundColor Cyan
    Write-Host "Download and install famous open-source fonts (Persian/Arabic, Coding, UI)."
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  .\install-fonts.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor White
    Write-Host "  -List                     List all available fonts and their IDs"
    Write-Host "  -Installed                Show which fonts are currently installed"
    Write-Host "  -All                      Install all fonts in the catalog"
    Write-Host "  -Category <CAT>           Install a category: persian, code, ui"
    Write-Host "  -Fonts <ID1,ID2,...>      Install specific fonts"
    Write-Host "  -Uninstall <ID1,ID2,...>  Uninstall specific fonts"
    Write-Host "  -Dir <PATH>               Custom font installation directory"
    Write-Host "  -DryRun                   Preview actions without downloading or installing"
    Write-Host "  -Help                     Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor White
    Write-Host "  .\install-fonts.ps1                                       # Interactive selector"
    Write-Host "  .\install-fonts.ps1 -Installed                            # Show installed fonts"
    Write-Host "  .\install-fonts.ps1 -Fonts vazirmatn,dastkhat,jetbrains-mono"
    Write-Host "  .\install-fonts.ps1 -Category persian"
    Write-Host "  .\install-fonts.ps1 -All -DryRun"
    Write-Host "  .\install-fonts.ps1 -Uninstall vazirmatn,inter"
    Write-Host ""
    Write-Host "INSTALL DIRECTORY:" -ForegroundColor White
    Write-Host "  Detected: $FONT_BASE_DIR"
    Write-Host ""
}

function Show-FontList {
    Write-Host ""
    Write-Host "Available Open-Source Fonts ($FONT_BASE_DIR)" -ForegroundColor White
    Write-Host ""

    foreach ($cat in $CATEGORIES) {
        Write-Host $cat.Title -ForegroundColor Cyan
        for ($i = 0; $i -lt $FONT_CATALOG.Count; $i++) {
            $f = $FONT_CATALOG[$i]
            if ($f.Category -ne $cat.Key) { continue }
            $num = "{0,2}" -f ($i + 1)
            $nameCol = $f.Name.PadRight(24)
            $idCol = ("(" + $f.Id + ")").PadRight(20)
            Write-Host "  $num. $nameCol " -NoNewline
            Write-Host $idCol -ForegroundColor DarkGray -NoNewline
            Write-Host $f.Desc -NoNewline
            if (Test-FontInstalled $f.Id) {
                Write-Host " [installed]" -ForegroundColor Green
            } else {
                Write-Host ""
            }
        }
        Write-Host ""
    }
}

function Show-InstalledFonts {
    Write-Host ""
    Write-Host "Installed Open-Source Fonts ($FONT_BASE_DIR)" -ForegroundColor White
    Write-Host ""

    $installedCount = 0
    $totalFiles = 0

    foreach ($f in $FONT_CATALOG) {
        if (Test-FontInstalled $f.Id) {
            $fcount = Get-FontFileCount $f.Id
            $installedCount++
            $totalFiles += $fcount
            $nameCol = $f.Name.PadRight(24)
            $idCol = ("(" + $f.Id + ")").PadRight(20)
            $countCol = ("{0,3} files" -f $fcount)
            $fontDir = Join-Path $FONT_BASE_DIR $f.Id

            Write-Host "  [OK] " -ForegroundColor Green -NoNewline
            Write-Host "$nameCol " -NoNewline
            Write-Host "$idCol " -ForegroundColor DarkGray -NoNewline
            Write-Host "$countCol  " -NoNewline
            Write-Host $fontDir -ForegroundColor DarkGray
        }
    }

    if ($installedCount -eq 0) {
        Write-Host "  No fonts installed yet in $FONT_BASE_DIR." -ForegroundColor DarkGray
        Write-Host "  Run without flags to open the interactive selector, or use -List to browse."
    } else {
        Write-Host ""
        Write-Host "Total: " -ForegroundColor White -NoNewline
        Write-Host "$installedCount of $($FONT_CATALOG.Count)" -ForegroundColor Green -NoNewline
        Write-Host " catalog fonts installed ($totalFiles font files)."
    }
    Write-Host ""
}

function Show-InteractiveMenu {
    $count = $FONT_CATALOG.Count
    $selected = New-Object bool[] $count
    $msg = ""
    $msgColor = "Yellow"

    while ($true) {
        try { Clear-Host } catch {}

        $installedTotal = 0
        for ($i = 0; $i -lt $count; $i++) {
            if (Test-FontInstalled $FONT_CATALOG[$i].Id) { $installedTotal++ }
        }

        Write-Host "======================================================================" -ForegroundColor Blue
        Write-Host "                 Open-Source Fonts Installer v$VERSION                  " -ForegroundColor Blue
        Write-Host "======================================================================" -ForegroundColor Blue
        Write-Host "Install directory: $FONT_BASE_DIR  |  Installed: $installedTotal/$count" -ForegroundColor DarkGray
        Write-Host ""

        foreach ($cat in $CATEGORIES) {
            Write-Host $cat.Title -ForegroundColor Cyan
            for ($i = 0; $i -lt $count; $i++) {
                $f = $FONT_CATALOG[$i]
                if ($f.Category -ne $cat.Key) { continue }
                $num = "{0,2}" -f ($i + 1)
                $nameCol = $f.Name.PadRight(24)

                if ($selected[$i]) {
                    Write-Host "  [x] " -ForegroundColor Green -NoNewline
                    Write-Host "$num) $nameCol " -ForegroundColor Green -NoNewline
                } else {
                    Write-Host "  [ ] " -ForegroundColor DarkGray -NoNewline
                    Write-Host "$num) $nameCol " -NoNewline
                }
                Write-Host $f.Desc -ForegroundColor DarkGray -NoNewline
                if (Test-FontInstalled $f.Id) {
                    Write-Host " (installed)" -ForegroundColor Yellow
                } else {
                    Write-Host ""
                }
            }
            Write-Host ""
        }

        $selCount = @($selected | Where-Object { $_ }).Count

        Write-Host "Commands:" -ForegroundColor White
        Write-Host "  1 2 8 or 1-3,8  Toggle fonts   a All   p Persian   c Code   u UI   n Clear" -ForegroundColor Cyan
        Write-Host "  i / Enter       Install ($selCount selected)   s Installed   q Quit" -ForegroundColor Green
        Write-Host ""

        if (-not [string]::IsNullOrEmpty($msg)) {
            Write-Host $msg -ForegroundColor $msgColor
            Write-Host ""
            $msg = ""
        }

        $inputText = Read-Host "Select"
        if ($null -eq $inputText) { exit 0 }
        $inputText = $inputText.Trim()

        if ([string]::IsNullOrEmpty($inputText) -or $inputText -eq "i" -or $inputText -eq "install") {
            if ($selCount -eq 0) {
                $msg = "No fonts selected yet. Enter numbers (e.g. 1 2 8) or 'a' for all."
                $msgColor = "Yellow"
                continue
            }
            $indices = @()
            for ($i = 0; $i -lt $count; $i++) {
                if ($selected[$i]) { $indices += $i }
            }
            return ,$indices
        }

        switch -Regex ($inputText.ToLowerInvariant()) {
            '^(q|quit|exit)$' {
                Write-Host "Cancelled."
                exit 0
            }
            '^(s|status|installed)$' {
                try { Clear-Host } catch {}
                Show-InstalledFonts
                Read-Host "Press Enter to return to menu" | Out-Null
            }
            '^(a|all)$' {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $true }
                $msg = "Selected all $count fonts."
                $msgColor = "Green"
            }
            '^(n|none|clear)$' {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $false }
                $msg = "Cleared selection."
                $msgColor = "DarkGray"
            }
            '^(p|persian)$' {
                for ($i = 0; $i -lt $count; $i++) {
                    if ($FONT_CATALOG[$i].Category -eq "persian") { $selected[$i] = $true }
                }
                $msg = "Selected all Persian / Arabic fonts."
                $msgColor = "Green"
            }
            '^(c|code)$' {
                for ($i = 0; $i -lt $count; $i++) {
                    if ($FONT_CATALOG[$i].Category -eq "code") { $selected[$i] = $true }
                }
                $msg = "Selected all Coding / Monospace fonts."
                $msgColor = "Green"
            }
            '^(u|ui)$' {
                for ($i = 0; $i -lt $count; $i++) {
                    if ($FONT_CATALOG[$i].Category -eq "ui") { $selected[$i] = $true }
                }
                $msg = "Selected all UI / Sans-Serif fonts."
                $msgColor = "Green"
            }
            default {
                $tokens = @($inputText -split '[,\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                $badTokens = @()
                foreach ($tok in $tokens) {
                    if ($tok -match '^(\d+)-(\d+)$') {
                        $s = [int]$Matches[1]
                        $e = [int]$Matches[2]
                        if ($s -ge 1 -and $e -le $count -and $s -le $e) {
                            for ($n = $s; $n -le $e; $n++) {
                                $selected[$n - 1] = -not $selected[$n - 1]
                            }
                        } else {
                            $badTokens += $tok
                        }
                    } elseif ($tok -match '^\d+$') {
                        $n = [int]$tok
                        if ($n -ge 1 -and $n -le $count) {
                            $selected[$n - 1] = -not $selected[$n - 1]
                        } else {
                            $badTokens += $tok
                        }
                    } else {
                        $idx = Find-FontIndexById $tok.ToLowerInvariant()
                        if ($idx -ge 0) {
                            $selected[$idx] = -not $selected[$idx]
                        } else {
                            $badTokens += $tok
                        }
                    }
                }
                if ($badTokens.Count -gt 0) {
                    $msg = "Unknown input: $($badTokens -join ' ')"
                    $msgColor = "Red"
                }
            }
        }
    }
}

# --- Main ---------------------------------------------------------------------
if ($Help) {
    Show-Usage
    exit 0
}

if ($List) {
    Show-FontList
    exit 0
}

if ($Installed) {
    Show-InstalledFonts
    exit 0
}

if ($Uninstall.Count -gt 0) {
    $idsToRemove = @($Uninstall | ForEach-Object { $_ -split ',' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    Write-Info "Uninstalling fonts from $FONT_BASE_DIR..."
    foreach ($id in $idsToRemove) {
        Uninstall-FontById $id.Trim()
    }
    Notify-WindowsFontChange
    exit 0
}

$selectedIndices = @()

if ($All) {
    for ($i = 0; $i -lt $FONT_CATALOG.Count; $i++) { $selectedIndices += $i }
} elseif (-not [string]::IsNullOrWhiteSpace($Category)) {
    for ($i = 0; $i -lt $FONT_CATALOG.Count; $i++) {
        if ($FONT_CATALOG[$i].Category -eq $Category) { $selectedIndices += $i }
    }
} elseif ($Fonts.Count -gt 0) {
    $ids = @($Fonts | ForEach-Object { $_ -split ',' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($id in $ids) {
        $idx = Find-FontIndexById $id.Trim()
        if ($idx -lt 0) {
            Write-ErrMsg "Unknown font ID: '$id'. Run with -List to see available IDs."
            exit 1
        }
        $selectedIndices += $idx
    }
} else {
    $selectedIndices = @(Show-InteractiveMenu)
}

Write-Host ""
Write-Info "Installing $($selectedIndices.Count) font(s) to $FONT_BASE_DIR..."
Write-Host ""

$okCount = 0
$failCount = 0

foreach ($idx in $selectedIndices) {
    if (Install-FontEntry $FONT_CATALOG[$idx]) {
        $okCount++
    } else {
        $failCount++
    }
    Write-Host ""
}

if ($okCount -gt 0) {
    Notify-WindowsFontChange
    if ($IS_WINDOWS -and (-not $DryRun)) {
        Write-Ok "Registered fonts in Windows user registry (restart open apps if needed)"
    }
}

Write-Host ""
Write-Host "Done! " -ForegroundColor White -NoNewline
Write-Host "$okCount succeeded" -ForegroundColor Green -NoNewline
if ($failCount -gt 0) {
    Write-Host ", " -NoNewline
    Write-Host "$failCount failed" -ForegroundColor Red -NoNewline
}
Write-Host "."

if ($failCount -gt 0) { exit 1 }
