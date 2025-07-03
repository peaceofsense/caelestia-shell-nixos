#!/usr/bin/env bash

# NixOS-compatible run script for caelestia-shell
# This script can be used to run the shell directly without installation

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set environment variables for NixOS compatibility
export QT_QPA_PLATFORM=wayland

# Set beat detector path if not already set
if [[ -z "${CAELESTIA_BD_PATH:-}" ]]; then
    # Try different possible locations
    if [[ -x "$HOME/.local/lib/caelestia/beat_detector" ]]; then
        export CAELESTIA_BD_PATH="$HOME/.local/lib/caelestia/beat_detector"
    elif [[ -x "/usr/lib/caelestia/beat_detector" ]]; then
        export CAELESTIA_BD_PATH="/usr/lib/caelestia/beat_detector"
    elif [[ -x "$SCRIPT_DIR/beat_detector" ]]; then
        export CAELESTIA_BD_PATH="$SCRIPT_DIR/beat_detector"
    else
        echo "Warning: Beat detector not found. Audio visualization may not work."
        echo "Please build it with: nix-shell -p gcc pipewire.dev aubio --run 'g++ -std=c++17 -Wall -Wextra -I\$NIX_CFLAGS_COMPILE -o beat_detector assets/beat_detector.cpp -lpipewire-0.3 -laubio'"
    fi
fi

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config/caelestia"

# Create default config if it doesn't exist
if [[ ! -f "$HOME/.config/caelestia/shell.json" ]]; then
    cat > "$HOME/.config/caelestia/shell.json" << 'EOF'
{
    "bar": {
        "workspaces": {
            "activeIndicator": true,
            "activeLabel": "󰮯 ",
            "activeTrail": false,
            "label": "  ",
            "occupiedBg": false,
            "occupiedLabel": "󰮯 ",
            "rounded": true,
            "showWindows": true,
            "shown": 5
        }
    },
    "border": {
        "rounding": 25,
        "thickness": 10
    },
    "dashboard": {
        "mediaUpdateInterval": 500,
        "visualiserBars": 45,
        "weatherLocation": "0,0"
    },
    "launcher": {
        "actionPrefix": ">",
        "enableDangerousActions": false,
        "maxShown": 8,
        "maxWallpapers": 9
    },
    "lock": {
        "maxNotifs": 5
    },
    "notifs": {
        "actionOnClick": false,
        "clearThreshold": 0.3,
        "defaultExpireTimeout": 5000,
        "expandThreshold": 20,
        "expire": false
    },
    "osd": {
        "hideDelay": 2000
    },
    "paths": {
        "mediaGif": "root:/assets/bongocat.gif",
        "sessionGif": "root:/assets/kurukuru.gif",
        "wallpaperDir": "~/Pictures/Wallpapers"
    },
    "session": {
        "dragThreshold": 30
    }
}
EOF
fi

# Set up log filtering (similar to the original fish script)
DISABLE_WARNINGS=(
    "quickshell.dbus.properties.warning = false"
    "quickshell.dbus.dbusmenu.warning = false"
    "quickshell.service.notifications.warning = false"
    "quickshell.service.sni.host.warning = false"
)

FILTER_PATTERNS=(
    "QProcess: Destroyed while process"
    "Cannot open: file://$XDG_CACHE_HOME/caelestia/imagecache/"
)

# Build log rules
LOG_RULES=$(IFS=';'; echo "${DISABLE_WARNINGS[*]}")

# Build grep filter
GREP_ARGS=()
for pattern in "${FILTER_PATTERNS[@]}"; do
    GREP_ARGS+=(-e "$pattern")
done

echo "Starting caelestia-shell..."
echo "Config directory: $HOME/.config/caelestia"
echo "Beat detector: ${CAELESTIA_BD_PATH:-not found}"
echo "Shell directory: $SCRIPT_DIR"
echo ""

# Check if quickshell is available
if ! command -v quickshell &> /dev/null; then
    echo "Error: quickshell not found in PATH"
    echo "Please install quickshell or add it to your PATH"
    exit 1
fi

# Run quickshell with log filtering
if [[ ${#GREP_ARGS[@]} -gt 0 ]]; then
    quickshell -p "$SCRIPT_DIR" --log-rules "$LOG_RULES" | grep -vF "${GREP_ARGS[@]}"
else
    quickshell -p "$SCRIPT_DIR" --log-rules "$LOG_RULES"
fi