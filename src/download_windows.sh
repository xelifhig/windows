#!/usr/bin/env bash
set -Eeuo pipefail

### Global Variables
: "${WIDTH:=""}"
: "${HEIGHT:=""}"
: "${VERIFY:=""}"
: "${REGION:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:=""}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"
MIRRORS=3
PLATFORM="x64"

### Helper Functions
info() { echo -e "[INFO] $1"; }
warn() { echo -e "[WARNING] $1"; }
error() { echo -e "[ERROR] $1" >&2; exit 1; }

### Functions from the "define.sh" script

parseVersion() {
  [ -z "$VERSION" ] && VERSION="win2025-eval"
  case "${VERSION,,}" in
    "2025" | "win2025" | "win2025-eval" | "windows2025") VERSION="win2025-eval" ;;
    *) error "Invalid VERSION specified: \"$VERSION\"";;
  esac
}

parseLanguage() {
  REGION="${REGION//_/-/}"
  KEYBOARD="${KEYBOARD//_/-/}"
  LANGUAGE="${LANGUAGE//_/-/}"

  [ -z "$LANGUAGE" ] && LANGUAGE="en"

  # Handle specific languages
  case "${LANGUAGE,,}" in
    "german" | "deutsch" | "de") LANGUAGE="de" ;;
    "english" | "en") LANGUAGE="en" ;;
    *) error "Invalid LANGUAGE specified: \"$LANGUAGE\"";;
  esac

  # Validate the language using getLanguage
  local culture
  culture=$(getLanguage "$LANGUAGE" "culture")
  if [ -z "$culture" ]; then
    error "Invalid LANGUAGE specified: \"$LANGUAGE\""
  fi
}

getLanguage() {
  local id="$1" ret="$2" lang="" culture=""
  case "${id,,}" in
    "de" | "de-"* ) lang="German"; culture="de-DE" ;;
    "en" | "en-"* ) lang="English"; culture="en-US" ;;
    *) error "Invalid LANGUAGE code: \"$id\"";;
  esac
  case "${ret,,}" in
    "desc" ) echo "$lang" ;;
    "culture" ) echo "$culture" ;;
    *) echo "$lang";;
  esac
}

getLink() {
  local id="$1" lang="$2" ret="$3"
  local host="https://dl.bobpony.com/windows"
  local url size sum
  case "${id,,}" in
    "win2025-eval")
      size=5307176960
      sum="2293897341febdcea599f5412300b470b5288c6fd2b89666a7b27d283e8d3cf3"
      url="$host/server/2025/en-us_windows_server_2025_preview_x64_dvd_ce9eb1a5.iso"
      ;;
    *) error "Unsupported version \"$id\"";;
  esac
  case "${ret,,}" in
    "url") echo "$url" ;;
    "size") echo "$size" ;;
    "sum") echo "$sum" ;;
    *) echo "$url";;
  esac
}

downloadFile() {
  local iso="$1" url="$2" sum="$3" size="$4"
  info "Downloading $iso from $url..."
  wget -O "$iso" "$url"
  if [ ! -f "$iso" ]; then error "Failed to download $iso"; fi
  local actual_size
  actual_size=$(stat -c%s "$iso")
  if [[ "$size" != "0" && "$actual_size" != "$size" ]]; then
    warn "Downloaded file size is $actual_size bytes, expected $size bytes"
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    local actual_sum
    actual_sum=$(sha256sum "$iso" | awk '{print $1}')
    if [ -n "$sum" ] && [ "$actual_sum" != "$sum" ]; then
      error "Checksum mismatch! Expected: $sum, Actual: $actual_sum"
    fi
  fi
  info "Download completed successfully."
}

### Main Function
downloadWindowsISO() {
  local version="$1" language="$2" keyboard="$3"
  parseVersion
  parseLanguage
  local url size sum iso
  url=$(getLink "$version" "$language" "url")
  size=$(getLink "$version" "$language" "size")
  sum=$(getLink "$version" "$language" "sum")
  iso="${version}_${language}.iso"
  downloadFile "$iso" "$url" "$sum" "$size"
  info "Your ISO has been downloaded: $iso"
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <VERSION> <LANGUAGE> <KEYBOARD>"
    echo "Example: $0 win2025-eval de de"
    exit 1
  fi
  downloadWindowsISO "$1" "$2" "$3"
fi
