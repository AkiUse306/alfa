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

echo "Release package created: alfa-release.tar.gz"
