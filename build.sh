#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "=== Alfa build script ==="

echo "Building core engine..."
mkdir -p core/build
cmake -S core -B core/build
cmake --build core/build --config Release

echo "Building shared models..."
dotnet restore shared

echo "Building server..."
dotnet build server -c Release

echo "Building web dashboard..."
dotnet build web -c Release

echo "Building CLI..."
dotnet build cli -c Release

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    echo "Building desktop app..."
    dotnet build app/desktop -c Release
    ;;
  *)
    echo "Skipping desktop WPF build on non-Windows host."
    ;;
esac

echo "=== Build complete ==="
