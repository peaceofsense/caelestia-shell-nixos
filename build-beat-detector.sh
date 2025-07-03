#!/usr/bin/env bash

# Build script for caelestia beat detector on NixOS
# This script builds the beat detector using Nix toolchain

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/assets/beat_detector.cpp"
OUTPUT_DIR="$HOME/.local/lib/caelestia"
OUTPUT_FILE="$OUTPUT_DIR/beat_detector"

echo "Building caelestia beat detector..."
echo "Source: $SOURCE_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Check if source file exists
if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Error: Source file not found: $SOURCE_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if we're in a Nix environment
if [[ -n "${NIX_CFLAGS_COMPILE:-}" ]]; then
    echo "Building in Nix environment..."
    g++ -std=c++17 -Wall -Wextra \
        $NIX_CFLAGS_COMPILE \
        -o "$OUTPUT_FILE" \
        "$SOURCE_FILE" \
        -lpipewire-0.3 -laubio
else
    echo "Building with nix-shell..."
    
    # Check if nix-shell is available
    if ! command -v nix-shell &> /dev/null; then
        echo "Error: nix-shell not found. Please install Nix or use a different build method."
        exit 1
    fi
    
    # Use nix-shell to provide build environment
    nix-shell -p gcc pkg-config pipewire.dev aubio --run "
        echo 'Building beat detector with Nix dependencies...'
        g++ -std=c++17 -Wall -Wextra \
            \$(pkg-config --cflags libpipewire-0.3 aubio) \
            -o '$OUTPUT_FILE' \
            '$SOURCE_FILE' \
            \$(pkg-config --libs libpipewire-0.3 aubio)
    "
fi

# Check if build was successful
if [[ -x "$OUTPUT_FILE" ]]; then
    echo ""
    echo "✓ Beat detector built successfully!"
    echo "Location: $OUTPUT_FILE"
    echo ""
    echo "You can now run the shell with: ./run-nixos.sh"
    echo "Or test the beat detector with: $OUTPUT_FILE --help"
else
    echo ""
    echo "✗ Build failed!"
    echo "Please check the error messages above."
    exit 1
fi

# Make sure it's executable
chmod +x "$OUTPUT_FILE"

echo ""
echo "Build complete!"