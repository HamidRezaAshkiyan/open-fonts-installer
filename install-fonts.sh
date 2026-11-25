#!/usr/bin/env bash
# ==============================================================================
# Open Fonts Installer
# Download and install famous open-source fonts (Persian/Arabic, Coding, UI)
# Supports macOS, Linux, and Windows (Git Bash / WSL)
# ==============================================================================

set -euo pipefail

VERSION="1.0.0"

# --- Colors & Styling ---------------------------------------------------------
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  MAGENTA=$'\033[0;35m'
  CYAN=$'\033[0;36m'
  RESET=$'\033[0m'
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" RESET=""
fi

# --- Font Catalog -------------------------------------------------------------
# Format: id|Display Name|Category|GitHub Repo|Asset Regex|Fallback URL|Description
FONT_CATALOG=(
  "vazirmatn|Vazirmatn|persian|rastikerdar/vazirmatn|vazirmatn-v.*\.zip|https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip|Modern Persian/Arabic & Latin UI typeface"
  "dastkhat|Dastkhat|persian|dastyar-io/dastkhat-font|Dastkhat-v.*\.zip|https://github.com/dastyar-io/dastkhat-font/releases/download/v1.220/Dastkhat-v1.220.zip|Persian & Latin typeface with dot variants & Mono"
  "estedad|Estedad|persian|aminabedi68/Estedad|Estedad-v.*\.zip|https://github.com/aminabedi68/Estedad/releases/download/8.5/Estedad-v8.5.zip|Clean geometric Persian & Latin sans-serif"
  "shabnam|Shabnam|persian|rastikerdar/shabnam-font|shabnam-font-v.*\.zip|https://github.com/rastikerdar/shabnam-font/releases/download/v5.0.1/shabnam-font-v5.0.1.zip|Popular Persian UI typeface"
  "sahel|Sahel|persian|rastikerdar/sahel-font|sahel-font-v.*\.zip|https://github.com/rastikerdar/sahel-font/releases/download/v3.4.0/sahel-font-v3.4.0.zip|Readable Persian typeface for body & UI"
  "samim|Samim|persian|rastikerdar/samim-font|samim-font-v.*\.zip|https://github.com/rastikerdar/samim-font/releases/download/v4.0.5/samim-font-v4.0.5.zip|Clean and balanced Persian typeface"
  "vazir-code|Vazir Code|persian|rastikerdar/vazir-code-font|vazir-code-font-v.*\.zip|https://github.com/rastikerdar/vazir-code-font/releases/download/v1.1.2/vazir-code-font-v1.1.2.zip|Monospace coding font with Persian support"
  "jetbrains-mono|JetBrains Mono|code|JetBrains/JetBrainsMono|JetBrainsMono-.*\.zip|https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip|Developer monospace font with ligatures"
  "jetbrains-mono-nf|JetBrainsMono Nerd Font|code|ryanoasis/nerd-fonts|/JetBrainsMono\.zip$|https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip|JetBrains Mono patched with Nerd Font icons"
  "fira-code|Fira Code|code|tonsky/FiraCode|Fira_Code_v.*\.zip|https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip|Monospace font with programming ligatures"
  "cascadia-code|Cascadia Code|code|microsoft/cascadia-code|CascadiaCode-.*\.zip|https://github.com/microsoft/cascadia-code/releases/download/v2407.24/CascadiaCode-2407.24.zip|Microsoft modern terminal & coding font"
  "monaspace|Monaspace|code|githubnext/monaspace|monaspace-static-v.*\.zip|https://github.com/githubnext/monaspace/releases/download/v1.400/monaspace-static-v1.400.zip|GitHub Next 5-family coding superfamilies"
  "hack|Hack|code|source-foundry/Hack|Hack-.*-ttf\.zip|https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip|Crisp monospace typeface designed for source code"
  "maple-mono|Maple Mono|code|subframe7536/maple-font|MapleMono-TTF\.zip$|https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-TTF.zip|Rounded monospace font with ligatures"
  "source-code-pro|Source Code Pro|code|adobe-fonts/source-code-pro|TTF-source-code-pro-.*\.zip|https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R-u%2F1.062R-i%2F1.026R-vf/TTF-source-code-pro-2.042R-u_1.062R-i.zip|Adobe open-source monospace font"
  "inter|Inter|ui|rsms/inter|Inter-.*\.zip|https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip|Carefully crafted typeface for computer screens"
  "geist|Geist|ui|vercel/geist-font|geist-font-v.*\.zip|https://github.com/vercel/geist-font/releases/download/v1.9.2/geist-font-v1.9.2.zip|Vercel minimalist sans & mono typeface"
  "ibm-plex-sans|IBM Plex Sans|ui|IBM/plex|ibm-plex-sans\.zip$|https://github.com/IBM/plex/releases/download/%40ibm%2Fplex-sans%401.1.0/ibm-plex-sans.zip|IBM open-source corporate sans-serif"
  "roboto|Roboto|ui|googlefonts/roboto-2|roboto-unhinted\.zip$|https://github.com/googlefonts/roboto-2/releases/download/v2.138/roboto-unhinted.zip|Google classic neo-grotesque sans-serif"
)

# --- Globals ------------------------------------------------------------------
DRY_RUN=0
CUSTOM_DIR=""
TMP_DIR=""
OS_TYPE=""
FONT_BASE_DIR=""
SELECTED_INDICES=()

# --- Cleanup ------------------------------------------------------------------
cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT INT TERM

# --- Helpers ------------------------------------------------------------------
info()    { printf "%s==>%s %s\n" "${BLUE}${BOLD}" "${RESET}" "$*"; }
success() { printf "%s  ✓%s %s\n" "${GREEN}${BOLD}" "${RESET}" "$*"; }
warn()    { printf "%s  !%s %s\n" "${YELLOW}${BOLD}" "${RESET}" "$*"; }
error()   { printf "%s  ✗%s %s\n" "${RED}${BOLD}" "${RESET}" "$*" >&2; }

check_dependencies() {
  local missing=()
  for cmd in curl unzip find; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    error "Missing required tools: ${missing[*]}"
    exit 1
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin)
      OS_TYPE="macos"
      FONT_BASE_DIR="${HOME}/Library/Fonts/open-fonts"
      ;;
    Linux)
      OS_TYPE="linux"
      FONT_BASE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/open-fonts"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      OS_TYPE="windows"
      if [[ -n "${LOCALAPPDATA:-}" ]]; then
        FONT_BASE_DIR="${LOCALAPPDATA}/Microsoft/Windows/Fonts/open-fonts"
      else
        FONT_BASE_DIR="${HOME}/Fonts/open-fonts"
      fi
      ;;
    *)
      OS_TYPE="unknown"
      FONT_BASE_DIR="${HOME}/.local/share/fonts/open-fonts"
      ;;
  esac

  if [[ -n "${CUSTOM_DIR}" ]]; then
    FONT_BASE_DIR="${CUSTOM_DIR}"
  fi
}

get_field() {
  local entry="$1"
  local field_num="$2"
  printf "%s" "$entry" | cut -d'|' -f"$field_num"
}

is_font_installed() {
  local id="$1"
  local dir="${FONT_BASE_DIR}/${id}"
  if [[ -d "$dir" ]] && [[ -n "$(find "$dir" -maxdepth 2 \( -iname '*.ttf' -o -iname '*.otf' \) -print -quit 2>/dev/null)" ]]; then
    return 0
  fi
  return 1
}

find_index_by_id() {
  local target="$1"
  local i
  for (( i = 0; i < ${#FONT_CATALOG[@]}; i++ )); do
    if [[ "$(get_field "${FONT_CATALOG[$i]}" 1)" == "$target" ]]; then
      printf "%d" "$i"
      return 0
    fi
  done
  return 1
}

# Resolve latest GitHub release asset download URL, falling back to pinned URL
resolve_download_url() {
  local repo="$1"
  local asset_regex="$2"
  local fallback_url="$3"

  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local curl_args=(-fsSL --connect-timeout 8 --max-time 15 -H "Accept: application/vnd.github+json" -H "User-Agent: open-fonts-installer/${VERSION}")

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  local response=""
  if response=$(curl "${curl_args[@]}" "$api_url" 2>/dev/null); then
    local matched_url=""
    matched_url=$(printf "%s\n" "$response" \
      | grep -Eo '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]+"' \
      | sed -E 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"([^"]+)"/\1/' \
      | grep -E "$asset_regex" \
      | head -n 1 || true)

    if [[ -n "$matched_url" ]]; then
      printf "%s" "$matched_url"
      return 0
    fi
  fi

  # Fallback to verified release URL if API rate-limited or offline
  printf "%s" "$fallback_url"
}

install_font() {
  local idx="$1"
  local entry="${FONT_CATALOG[$idx]}"
  local id name repo asset_regex fallback_url
  id=$(get_field "$entry" 1)
  name=$(get_field "$entry" 2)
  repo=$(get_field "$entry" 4)
  asset_regex=$(get_field "$entry" 5)
  fallback_url=$(get_field "$entry" 6)

  local target_dir="${FONT_BASE_DIR}/${id}"
  info "Installing ${BOLD}${name}${RESET} (${DIM}${repo}${RESET})..."

  local url
  url=$(resolve_download_url "$repo" "$asset_regex" "$fallback_url")

  if (( DRY_RUN == 1 )); then
    printf "  %s[dry-run]%s Would download: %s\n" "${CYAN}" "${RESET}" "$url"
    printf "  %s[dry-run]%s Would install to: %s\n" "${CYAN}" "${RESET}" "$target_dir"
    return 0
  fi

  if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/open-fonts.XXXXXX")
  fi

  local work_dir="${TMP_DIR}/${id}"
  local zip_file="${work_dir}/font.zip"
  local extract_dir="${work_dir}/extracted"
  mkdir -p "$extract_dir"

  printf "  %sDownloading%s %s\n" "${DIM}" "${RESET}" "$(basename "$url")"
  if ! curl -fL --progress-bar --connect-timeout 15 --max-time 300 -o "$zip_file" "$url"; then
    error "Failed to download ${name} from ${url}"
    return 1
  fi

  printf "  %sExtracting font files...%s\n" "${DIM}" "${RESET}"
  if ! unzip -qo "$zip_file" -d "$extract_dir"; then
    error "Failed to extract archive for ${name}"
    return 1
  fi

  # Collect .ttf and .otf files, skipping __MACOSX metadata and webfont directories
  local font_files=()
  while IFS= read -r -d '' f; do
    font_files+=("$f")
  done < <(find "$extract_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
    ! -path '*/__MACOSX/*' \
    ! -path '*/.*' \
    ! -iname '._*' \
    ! -path '*/webfonts/*' \
    ! -path '*/web/*' \
    ! -path '*/WOFF*' \
    -print0)

  if (( ${#font_files[@]} == 0 )); then
    error "No .ttf or .otf files found in archive for ${name}"
    return 1
  fi

  # Prefer static fonts over variable fonts if both exist in the same archive,
  # to avoid duplicate family conflicts on macOS/Linux.
  local static_files=()
  for f in "${font_files[@]}"; do
    local lower_f
    lower_f=$(printf "%s" "$f" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower_f" != *"/variable/"* && "$lower_f" != *"variable"* ]]; then
      static_files+=("$f")
    fi
  done

  if (( ${#static_files[@]} > 0 )); then
    font_files=("${static_files[@]}")
  fi

  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  local count=0
  for f in "${font_files[@]}"; do
    cp -f "$f" "$target_dir/"
    count=$((count + 1))
  done

  success "Installed ${BOLD}${name}${RESET} (${count} font files -> ${DIM}${target_dir}${RESET})"
}

uninstall_font() {
  local id="$1"
  local target_dir="${FONT_BASE_DIR}/${id}"
  if [[ -d "$target_dir" ]]; then
    if (( DRY_RUN == 1 )); then
      printf "  %s[dry-run]%s Would remove: %s\n" "${CYAN}" "${RESET}" "$target_dir"
    else
      rm -rf "$target_dir"
      success "Uninstalled ${BOLD}${id}${RESET} (${DIM}${target_dir}${RESET})"
    fi
  else
    warn "${id} is not installed in ${FONT_BASE_DIR}"
  fi
}

refresh_font_cache() {
  if (( DRY_RUN == 1 )); then
    return 0
  fi
  if [[ "$OS_TYPE" == "linux" ]] && command -v fc-cache >/dev/null 2>&1; then
    info "Refreshing Linux font cache (fc-cache)..."
    fc-cache -f "${FONT_BASE_DIR}" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1 || true
    success "Font cache updated"
  elif [[ "$OS_TYPE" == "macos" ]]; then
    success "macOS automatically detects fonts in ~/Library/Fonts (restart open apps if needed)"
  elif [[ "$OS_TYPE" == "windows" ]]; then
    warn "On Windows, you may need to right-click the fonts in ${FONT_BASE_DIR} and select 'Install', or reopen your apps."
  fi
}

# --- Display & Listing --------------------------------------------------------
print_usage() {
  cat <<EOF
${BOLD}Open Fonts Installer v${VERSION}${RESET}
Download and install famous open-source fonts (Persian/Arabic, Coding, UI).

${BOLD}USAGE:${RESET}
  $(basename "$0") [OPTIONS] [FONT_IDS...]

${BOLD}OPTIONS:${RESET}
  -l, --list                  List all available fonts and their IDs
  -a, --all                   Install all fonts in the catalog
  -c, --category <CAT>        Install a category: persian, code, ui
  -f, --fonts <ID1,ID2,...>   Install specific fonts (comma-separated)
  -u, --uninstall <ID1,...>   Uninstall specific fonts (comma-separated)
  -d, --dir <PATH>            Custom font installation directory
      --dry-run               Preview actions without downloading or installing
  -h, --help                  Show this help message

${BOLD}EXAMPLES:${RESET}
  $(basename "$0")                                   # Interactive selector
  $(basename "$0") vazirmatn dastkhat jetbrains-mono # Install specific fonts
  $(basename "$0") --category persian                # Install all Persian fonts
  $(basename "$0") --all --dry-run                   # Preview installing all fonts
  $(basename "$0") --uninstall vazirmatn,inter       # Remove installed fonts

${BOLD}INSTALL DIRECTORY:${RESET}
  Detected: ${FONT_BASE_DIR}
EOF
}

list_fonts() {
  printf "\n%sAvailable Open-Source Fonts%s (%s)\n\n" "${BOLD}" "${RESET}" "${FONT_BASE_DIR}"
  local categories=("persian" "code" "ui")
  local cat_titles=("Persian / Arabic (RTL)" "Coding / Monospace" "UI / Sans-Serif")
  local c i

  for (( c = 0; c < ${#categories[@]}; c++ )); do
    printf "%s%s%s\n" "${CYAN}${BOLD}" "${cat_titles[$c]}" "${RESET}"
    for (( i = 0; i < ${#FONT_CATALOG[@]}; i++ )); do
      local entry="${FONT_CATALOG[$i]}"
      local id name cat desc status_badge=""
      id=$(get_field "$entry" 1)
      name=$(get_field "$entry" 2)
      cat=$(get_field "$entry" 3)
      desc=$(get_field "$entry" 7)

      if [[ "$cat" == "${categories[$c]}" ]]; then
        if is_font_installed "$id"; then
          status_badge=" ${GREEN}[installed]${RESET}"
        fi
        printf "  %2d. %-24s %s%-18s%s %s%s\n" \
          "$((i + 1))" "$name" "${DIM}" "($id)" "${RESET}" "$desc" "$status_badge"
      fi
    done
    printf "\n"
  done
}

# --- Interactive Multi-Select Menu --------------------------------------------
interactive_menu() {
  local count=${#FONT_CATALOG[@]}
  local selected=()
  local i
  for (( i = 0; i < count; i++ )); do
    selected[$i]=0
  done

  local msg=""
  local tty_in="/dev/stdin"
  if [[ ! -t 0 && -t 1 && -r /dev/tty ]]; then
    tty_in="/dev/tty"
  fi

  while true; do
    if [[ -t 1 ]]; then
      printf "\033[H\033[2J"
    fi

    printf "%s╔══════════════════════════════════════════════════════════════════════╗%s\n" "${BLUE}${BOLD}" "${RESET}"
    printf "%s║                   Open-Source Fonts Installer v%s                 ║%s\n" "${BLUE}${BOLD}" "${VERSION}" "${RESET}"
    printf "%s╚══════════════════════════════════════════════════════════════════════╝%s\n" "${BLUE}${BOLD}" "${RESET}"
    printf "%sInstall directory:%s %s\n\n" "${DIM}" "${RESET}" "${FONT_BASE_DIR}"

    local categories=("persian" "code" "ui")
    local cat_titles=("Persian / Arabic (RTL)" "Coding / Monospace" "UI / Sans-Serif")
    local c

    for (( c = 0; c < ${#categories[@]}; c++ )); do
      printf "%s%s%s\n" "${CYAN}${BOLD}" "${cat_titles[$c]}" "${RESET}"
      for (( i = 0; i < count; i++ )); do
        local entry="${FONT_CATALOG[$i]}"
        local id name cat desc
        id=$(get_field "$entry" 1)
        name=$(get_field "$entry" 2)
        cat=$(get_field "$entry" 3)
        desc=$(get_field "$entry" 7)

        if [[ "$cat" != "${categories[$c]}" ]]; then
          continue
        fi

        local box="${DIM}[ ]${RESET}"
        local name_fmt="$name"
        if (( selected[$i] == 1 )); then
          box="${GREEN}${BOLD}[x]${RESET}"
          name_fmt="${GREEN}${BOLD}${name}${RESET}"
        fi

        local installed_tag=""
        if is_font_installed "$id"; then
          installed_tag=" ${YELLOW}(installed)${RESET}"
        fi

        printf "  %s %2d) %-24s %s%s%s%s\n" \
          "$box" "$((i + 1))" "$name_fmt" "${DIM}" "$desc" "${RESET}" "$installed_tag"
      done
      printf "\n"
    done

    local sel_count=0
    for (( i = 0; i < count; i++ )); do
      (( sel_count += selected[$i] ))
    done

    printf "%sCommands:%s\n" "${BOLD}" "${RESET}"
    printf "  %s1 2 8%s or %s1-3,8%s  Toggle fonts    %sa%s All    %sp%s Persian    %sc%s Code    %su%s UI    %sn%s Clear\n" \
      "${CYAN}" "${RESET}" "${CYAN}" "${RESET}" "${CYAN}" "${RESET}" "${CYAN}" "${RESET}" "${CYAN}" "${RESET}" "${CYAN}" "${RESET}" "${CYAN}" "${RESET}"
    printf "  %si%s / %sEnter%s       Install (%s%d selected%s)    %sq%s Quit\n\n" \
      "${GREEN}${BOLD}" "${RESET}" "${GREEN}${BOLD}" "${RESET}" "${BOLD}" "$sel_count" "${RESET}" "${RED}" "${RESET}"

    if [[ -n "$msg" ]]; then
      printf "%s\n\n" "$msg"
      msg=""
    fi

    printf "%sSelect > %s" "${BOLD}" "${RESET}"
    local input=""
    if ! IFS= read -r input < "$tty_in"; then
      echo ""
      exit 0
    fi

    # Trim whitespace
    input=$(printf "%s" "$input" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')

    if [[ -z "$input" || "$input" == "i" || "$input" == "install" ]]; then
      if (( sel_count == 0 )); then
        msg="${YELLOW}No fonts selected yet. Enter numbers (e.g. 1 2 8) or 'a' for all.${RESET}"
        continue
      fi
      SELECTED_INDICES=()
      for (( i = 0; i < count; i++ )); do
        if (( selected[$i] == 1 )); then
          SELECTED_INDICES+=("$i")
        fi
      done
      return 0
    fi

    case "$input" in
      q|Q|quit|exit)
        printf "Cancelled.\n"
        exit 0
        ;;
      a|A|all)
        for (( i = 0; i < count; i++ )); do selected[$i]=1; done
        msg="${GREEN}Selected all ${count} fonts.${RESET}"
        ;;
      n|N|none|clear)
        for (( i = 0; i < count; i++ )); do selected[$i]=0; done
        msg="${DIM}Cleared selection.${RESET}"
        ;;
      p|P|persian)
        for (( i = 0; i < count; i++ )); do
          [[ "$(get_field "${FONT_CATALOG[$i]}" 3)" == "persian" ]] && selected[$i]=1
        done
        msg="${GREEN}Selected all Persian / Arabic fonts.${RESET}"
        ;;
      c|C|code)
        for (( i = 0; i < count; i++ )); do
          [[ "$(get_field "${FONT_CATALOG[$i]}" 3)" == "code" ]] && selected[$i]=1
        done
        msg="${GREEN}Selected all Coding / Monospace fonts.${RESET}"
        ;;
      u|U|ui)
        for (( i = 0; i < count; i++ )); do
          [[ "$(get_field "${FONT_CATALOG[$i]}" 3)" == "ui" ]] && selected[$i]=1
        done
        msg="${GREEN}Selected all UI / Sans-Serif fonts.${RESET}"
        ;;
      *)
        # Parse comma/space separated numbers and ranges (e.g. "1 2 8", "1-4,10")
        local tokens
        tokens=$(printf "%s" "$input" | tr ',' ' ')
        local bad_tokens=()
        for tok in $tokens; do
          if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            if (( start >= 1 && end <= count && start <= end )); then
              local n
              for (( n = start; n <= end; n++ )); do
                local idx=$((n - 1))
                selected[$idx]=$(( 1 - selected[$idx] ))
              done
            else
              bad_tokens+=("$tok")
            fi
          elif [[ "$tok" =~ ^[0-9]+$ ]]; then
            if (( tok >= 1 && tok <= count )); then
              local idx=$((tok - 1))
              selected[$idx]=$(( 1 - selected[$idx] ))
            else
              bad_tokens+=("$tok")
            fi
          else
            # Also allow toggling by font ID
            local found_idx=""
            if found_idx=$(find_index_by_id "$tok"); then
              selected[$found_idx]=$(( 1 - selected[$found_idx] ))
            else
              bad_tokens+=("$tok")
            fi
          fi
        done

        if (( ${#bad_tokens[@]} > 0 )); then
          msg="${RED}Unknown input: ${bad_tokens[*]}${RESET}"
        fi
        ;;
    esac
  done
}

# --- Main ---------------------------------------------------------------------
main() {
  check_dependencies

  local mode="interactive"
  local requested_ids=()
  local uninstall_ids=()
  local requested_category=""

  while (( $# > 0 )); do
    case "$1" in
      -h|--help)
        detect_os
        print_usage
        exit 0
        ;;
      -l|--list)
        mode="list"
        shift
        ;;
      -a|--all)
        mode="all"
        shift
        ;;
      -c|--category)
        if (( $# < 2 )); then
          error "--category requires an argument (persian, code, ui)"
          exit 1
        fi
        mode="category"
        requested_category="$2"
        shift 2
        ;;
      -f|--fonts)
        if (( $# < 2 )); then
          error "--fonts requires a comma-separated list of font IDs"
          exit 1
        fi
        mode="specific"
        IFS=',' read -r -a parts <<< "$2"
        requested_ids+=("${parts[@]}")
        shift 2
        ;;
      -u|--uninstall)
        if (( $# < 2 )); then
          error "--uninstall requires a comma-separated list of font IDs"
          exit 1
        fi
        mode="uninstall"
        IFS=',' read -r -a parts <<< "$2"
        uninstall_ids+=("${parts[@]}")
        shift 2
        ;;
      -d|--dir)
        if (( $# < 2 )); then
          error "--dir requires a directory path"
          exit 1
        fi
        CUSTOM_DIR="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -*)
        error "Unknown option: $1 (use --help for usage)"
        exit 1
        ;;
      *)
        mode="specific"
        requested_ids+=("$1")
        shift
        ;;
    esac
  done

  detect_os

  case "$mode" in
    list)
      list_fonts
      exit 0
      ;;
    uninstall)
      info "Uninstalling fonts from ${FONT_BASE_DIR}..."
      for id in "${uninstall_ids[@]}"; do
        uninstall_font "$id"
      done
      refresh_font_cache
      exit 0
      ;;
    all)
      local i
      for (( i = 0; i < ${#FONT_CATALOG[@]}; i++ )); do
        SELECTED_INDICES+=("$i")
      done
      ;;
    category)
      local i
      for (( i = 0; i < ${#FONT_CATALOG[@]}; i++ )); do
        if [[ "$(get_field "${FONT_CATALOG[$i]}" 3)" == "$requested_category" ]]; then
          SELECTED_INDICES+=("$i")
        fi
      done
      if (( ${#SELECTED_INDICES[@]} == 0 )); then
        error "Unknown category '${requested_category}'. Valid categories: persian, code, ui"
        exit 1
      fi
      ;;
    specific)
      for id in "${requested_ids[@]}"; do
        local idx=""
        if idx=$(find_index_by_id "$id"); then
          SELECTED_INDICES+=("$idx")
        else
          error "Unknown font ID: '${id}'. Run with --list to see available IDs."
          exit 1
        fi
      done
      ;;
    interactive)
      interactive_menu
      ;;
  esac

  printf "\n"
  info "Installing ${#SELECTED_INDICES[@]} font(s) to ${BOLD}${FONT_BASE_DIR}${RESET}..."
  printf "\n"

  local ok_count=0
  local fail_count=0

  for idx in "${SELECTED_INDICES[@]}"; do
    if install_font "$idx"; then
      ok_count=$((ok_count + 1))
    else
      fail_count=$((fail_count + 1))
    fi
    printf "\n"
  done

  if (( ok_count > 0 )); then
    refresh_font_cache
  fi

  printf "\n%sDone!%s %s%d succeeded%s" "${BOLD}" "${RESET}" "${GREEN}" "$ok_count" "${RESET}"
  if (( fail_count > 0 )); then
    printf ", %s%d failed%s" "${RED}" "$fail_count" "${RESET}"
  fi
  printf ".\n"

  (( fail_count == 0 ))
}

main "$@"
