#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "=== Alfa publish package ==="

./build.sh

rm -rf dist
mkdir -p dist/core dist/server dist/web dist/cli

cp core/build/alfa-core dist/core/

dotnet publish server -c Release -o dist/server

dotnet publish web -c Release -o dist/web

dotnet publish cli -c Release -o dist/cli

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    dotnet publish app/desktop -c Release -o dist/desktop
    ;;
  *)
    echo "Skipping desktop packaging on non-Windows host."
    ;;
 esac

tar -czf alfa-release.tar.gz -C dist .

mkdir -p dist/installers

echo "Creating package-style release artifacts..."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
export PACKAGE_TMPDIR="$tmpdir"

tar -czf "$tmpdir/alfa-1.0-linux.pkg" -C dist .

tar -czf "$tmpdir/alfa-1.0-macos.pkg" -C dist .

python3 - <<'PY'
import os
import zipfile
root = 'dist'
out_path = os.path.join(os.environ['PACKAGE_TMPDIR'], 'alfa-1.0-windows.msi')
with zipfile.ZipFile(out_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for base, _, files in os.walk(root):
        if base.startswith(os.path.join(root, 'installers')):
            continue
        for fname in files:
            path = os.path.join(base, fname)
            rel = os.path.relpath(path, root)
            zipf.write(path, rel)
PY

mv "$tmpdir"/* dist/installers/

echo "Installer artifacts created: dist/installers/alfa-1.0-linux.pkg, dist/installers/alfa-1.0-macos.pkg, dist/installers/alfa-1.0-windows.msi"
echo "Release package created: alfa-release.tar.gz"
