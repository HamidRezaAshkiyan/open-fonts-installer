# Open Fonts Installer

A zero-dependency interactive Bash script to download and install famous open-source fonts — including Persian/Arabic, Coding/Monospace, and UI/Sans-Serif typefaces — on **macOS**, **Linux**, and **Windows (Git Bash / WSL)**.

## Features

- **Interactive multi-select menu** — pick individual fonts, ranges (`1-3,8`), or entire categories (`persian`, `code`, `ui`)
- **CLI flags for scripting** — install or uninstall non-interactively
- **Always up-to-date** — automatically fetches the latest GitHub Release for each font (with pinned fallback URLs if GitHub API is rate-limited)
- **Clean & organized** — installs each font into its own subfolder so uninstalling is trivial
- **Zero dependencies** — uses only `bash`, `curl`, `unzip`, and `find` (plus `fc-cache` on Linux)

## Quick Start

### Run directly via `curl`

```bash
curl -fsSL https://raw.githubusercontent.com/HamidRezaAshkiyan/open-fonts-installer/main/install-fonts.sh | bash
```

### Or clone and run locally

```bash
git clone https://github.com/HamidRezaAshkiyan/open-fonts-installer.git
cd open-fonts-installer
./install-fonts.sh
```

## Usage

```bash
# Interactive selector
./install-fonts.sh

# List all available fonts and their IDs
./install-fonts.sh --list

# Install specific fonts by ID
./install-fonts.sh vazirmatn dastkhat jetbrains-mono

# Install an entire category (persian | code | ui)
./install-fonts.sh --category persian
./install-fonts.sh --category code

# Install all fonts
./install-fonts.sh --all

# Preview without downloading or installing
./install-fonts.sh --dry-run vazirmatn dastkhat

# Install to a custom directory
./install-fonts.sh --dir ~/my-fonts vazirmatn

# Uninstall specific fonts
./install-fonts.sh --uninstall vazirmatn,inter
```

> **Tip:** If you hit GitHub API rate limits (60 requests/hour unauthenticated), you can pass a token via `GITHUB_TOKEN=ghp_... ./install-fonts.sh`, or let the script automatically fall back to its verified release URLs.

## Included Fonts

### Persian / Arabic (RTL)

| Font | ID | Repository | Description |
| :--- | :--- | :--- | :--- |
| **Vazirmatn** | `vazirmatn` | [rastikerdar/vazirmatn](https://github.com/rastikerdar/vazirmatn) | Modern Persian/Arabic & Latin UI typeface |
| **Dastkhat** | `dastkhat` | [dastyar-io/dastkhat-font](https://github.com/dastyar-io/dastkhat-font) | Persian & Latin typeface with dot variants & Mono |
| **Estedad** | `estedad` | [aminabedi68/Estedad](https://github.com/aminabedi68/Estedad) | Clean geometric Persian & Latin sans-serif |
| **Shabnam** | `shabnam` | [rastikerdar/shabnam-font](https://github.com/rastikerdar/shabnam-font) | Popular Persian UI typeface |
| **Sahel** | `sahel` | [rastikerdar/sahel-font](https://github.com/rastikerdar/sahel-font) | Readable Persian typeface for body & UI |
| **Samim** | `samim` | [rastikerdar/samim-font](https://github.com/rastikerdar/samim-font) | Clean and balanced Persian typeface |
| **Vazir Code** | `vazir-code` | [rastikerdar/vazir-code-font](https://github.com/rastikerdar/vazir-code-font) | Monospace coding font with Persian support |

### Coding / Monospace

| Font | ID | Repository | Description |
| :--- | :--- | :--- | :--- |
| **JetBrains Mono** | `jetbrains-mono` | [JetBrains/JetBrainsMono](https://github.com/JetBrains/JetBrainsMono) | Developer monospace font with ligatures |
| **JetBrainsMono Nerd Font** | `jetbrains-mono-nf` | [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) | JetBrains Mono patched with Nerd Font icons |
| **Fira Code** | `fira-code` | [tonsky/FiraCode](https://github.com/tonsky/FiraCode) | Monospace font with programming ligatures |
| **Cascadia Code** | `cascadia-code` | [microsoft/cascadia-code](https://github.com/microsoft/cascadia-code) | Microsoft modern terminal & coding font |
| **Monaspace** | `monaspace` | [githubnext/monaspace](https://github.com/githubnext/monaspace) | GitHub Next 5-family coding superfamilies |
| **Hack** | `hack` | [source-foundry/Hack](https://github.com/source-foundry/Hack) | Crisp monospace typeface designed for source code |
| **Maple Mono** | `maple-mono` | [subframe7536/maple-font](https://github.com/subframe7536/maple-font) | Rounded monospace font with ligatures |
| **Source Code Pro** | `source-code-pro` | [adobe-fonts/source-code-pro](https://github.com/adobe-fonts/source-code-pro) | Adobe open-source monospace font |

### UI / Sans-Serif

| Font | ID | Repository | Description |
| :--- | :--- | :--- | :--- |
| **Inter** | `inter` | [rsms/inter](https://github.com/rsms/inter) | Carefully crafted typeface for computer screens |
| **Geist** | `geist` | [vercel/geist-font](https://github.com/vercel/geist-font) | Vercel minimalist sans & mono typeface |
| **IBM Plex Sans** | `ibm-plex-sans` | [IBM/plex](https://github.com/IBM/plex) | IBM open-source corporate sans-serif |
| **Roboto** | `roboto` | [googlefonts/roboto-2](https://github.com/googlefonts/roboto-2) | Google classic neo-grotesque sans-serif |

## Installation Paths

- **macOS:** `~/Library/Fonts/open-fonts/<font-id>/`
- **Linux:** `~/.local/share/fonts/open-fonts/<font-id>/` (followed by `fc-cache -f`)
- **Windows (Git Bash / MSYS2):** `%LOCALAPPDATA%\Microsoft\Windows\Fonts\open-fonts\<font-id>\`

## License

This installer script is licensed under the [MIT License](LICENSE). Each downloaded font remains under its own respective open-source license (typically SIL OFL 1.1 or Apache 2.0).
