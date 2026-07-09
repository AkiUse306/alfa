#!/usr/bin/env bash
set -euo pipefail

REPO="AkiUse306/alfa"
API="https://api.github.com/repos/${REPO}/releases/latest"

echo "====================================="
echo "🚀 Alfa Installer"
echo "====================================="
echo

OS="$(uname -s)"

case "$OS" in
  Darwin)
    ASSET_PATTERN="(macos|darwin).*(pkg|dmg|tar.gz|zip)"
    ;;
  Linux)
    ASSET_PATTERN="(linux|ubuntu|debian).*(deb|tar.gz|zip|bin)"
    ;;
  *)
    echo "❌ Unsupported operating system: $OS"
    exit 1
    ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "📡 Checking latest release..."

# Fetch release JSON (quietly)
RELEASE_JSON="$TMPDIR/release.json"
if ! curl -fsSL "$API" -o "$RELEASE_JSON"; then
  echo "❌ Failed to fetch release info from GitHub."
  exit 1
fi

# Find an asset matching the pattern (prefer browser_download_url)
ASSET_URL=$(grep -oE '"browser_download_url":[[:space:]]*"[^"]+"' "$RELEASE_JSON" \
  | sed -E 's/.*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/' \
  | grep -Ei "$ASSET_PATTERN" \
  | head -n1 || true)

if [ -z "$ASSET_URL" ]; then
  echo "❌ Could not find installer asset for your platform in the latest release."
  exit 1
fi

FILE="$TMPDIR/$(basename "$ASSET_URL")"

echo "📦 Downloading $(basename "$ASSET_URL")..."
echo "Downloading from:"
echo "$ASSET_URL"

curl -fL --retry 3 --retry-delay 2 -o "$FILE" "$ASSET_URL"

echo
echo "Downloaded file:"
ls -lh "$FILE"

echo
echo "File type:"
file "$FILE"

echo
echo "Size:"
stat -f%z "$FILE"

echo

# Helper: install .dmg on macOS
install_dmg() {
  local dmg="$1"
  echo "📥 Mounting DMG..."
  MOUNT_POINT=$(hdiutil attach "$dmg" -nobrowse -quiet | awk -F'\t' '/\/Volumes\//{print $3; exit}')
  if [ -z "$MOUNT_POINT" ]; then
    echo "❌ Failed to mount DMG."
    return 1
  fi

  # Install .pkg if present, otherwise copy .app to /Applications
  if ls "$MOUNT_POINT"/*.pkg >/dev/null 2>&1; then
    echo "📦 Installing PKG from DMG..."
    sudo installer -pkg "$MOUNT_POINT"/*.pkg -target /
  elif ls "$MOUNT_POINT"/*.app >/dev/null 2>&1; then
    echo "📁 Copying app to /Applications..."
    sudo cp -R "$MOUNT_POINT"/*.app /Applications/
  else
    echo "⚠️ No .pkg or .app found inside DMG. Please inspect: $MOUNT_POINT"
    hdiutil detach "$MOUNT_POINT" -quiet || true
    return 1
  fi

  hdiutil detach "$MOUNT_POINT" -quiet || true
  return 0
}

# Install based on file extension
case "$FILE" in
  *.dmg)
    if [[ "$OS" != "Darwin" ]]; then
      echo "❌ DMG installer is macOS-only."
      exit 1
    fi
    install_dmg "$FILE"
    ;;
  *.pkg)
    echo "📥 Installing package..."
    if [[ "$OS" == "Darwin" ]]; then
      sudo installer -pkg "$FILE" -target /
    else
      # treat as generic package; try dpkg
      sudo dpkg -i "$FILE" || sudo apt-get install -f -y
    fi
    ;;
  *.deb)
    if [[ "$OS" != "Linux" ]]; then
      echo "❌ DEB installer is Linux-only."
      exit 1
    fi
    echo "📥 Installing DEB..."
    sudo dpkg -i "$FILE" || sudo apt-get install -f -y
    ;;
  *.tar.gz|*.tgz)
    echo "📦 Extracting tarball..."
    tar -xzf "$FILE" -C "$TMPDIR"
    # Try to find an executable named alfa
    BIN_PATH=$(find "$TMPDIR" -type f -name "alfa" -perm -u=x | head -n1 || true)
    if [ -n "$BIN_PATH" ]; then
      echo "📁 Installing binary to /usr/local/bin..."
      sudo install -m 0755 "$BIN_PATH" /usr/local/bin/alfa
    else
      echo "⚠️ No executable named 'alfa' found in the tarball. Inspect $TMPDIR"
      exit 1
    fi
    ;;
  *.zip)
    echo "📦 Extracting zip..."
    if ! command -v unzip >/dev/null 2>&1; then
      echo "❌ unzip is required to extract this archive."
      exit 1
    fi
    unzip -q "$FILE" -d "$TMPDIR"
    BIN_PATH=$(find "$TMPDIR" -type f -name "alfa" -perm -u=x | head -n1 || true)
    if [ -n "$BIN_PATH" ]; then
      echo "📁 Installing binary to /usr/local/bin..."
      sudo install -m 0755 "$BIN_PATH" /usr/local/bin/alfa
    else
      echo "⚠️ No executable named 'alfa' found in the zip. Inspect $TMPDIR"
      exit 1
    fi
    ;;
  *.bin|*.run)
    echo "🔧 Making installer executable and running..."
    chmod +x "$FILE"
    sudo "$FILE"
    ;;
  *)
    # If it's a single-file executable, install it
    if file "$FILE" | grep -qi "executable"; then
      echo "📁 Installing executable to /usr/local/bin/alfa..."
      sudo install -m 0755 "$FILE" /usr/local/bin/alfa
    else
      echo "❌ Unknown asset type: $FILE"
      exit 1
    fi
    ;;
esac

echo
echo "✅ Alfa installed successfully!"
echo
echo "Run:"
echo "  alfa"
