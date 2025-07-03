#!/usr/bin/env bash

# Test script for caelestia-shell NixOS installation
# This script verifies that all components are properly installed and configured

set -euo pipefail

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

print_test() {
    echo -e "${COLOR_BLUE}[TEST]${COLOR_NC} $1"
}

print_pass() {
    echo -e "${COLOR_GREEN}[PASS]${COLOR_NC} $1"
}

print_fail() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_NC} $1"
}

print_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $1"
}

test_count=0
pass_count=0
fail_count=0
warn_count=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    local required="${3:-true}"
    
    print_test "$test_name"
    ((test_count++))
    
    if eval "$test_command" &>/dev/null; then
        print_pass "$test_name"
        ((pass_count++))
        return 0
    else
        if [[ "$required" == "true" ]]; then
            print_fail "$test_name"
            ((fail_count++))
        else
            print_warn "$test_name (optional)"
            ((warn_count++))
        fi
        return 1
    fi
}

echo "Caelestia Shell Installation Test"
echo "================================="
echo ""

# Test 1: Check if we're on NixOS
run_test "NixOS detection" "[[ -f /etc/NIXOS ]]"

# Test 2: Check quickshell availability
run_test "quickshell command" "command -v quickshell"

# Test 3: Check shell files
run_test "shell.qml exists" "[[ -f shell.qml ]]"
run_test "modules directory" "[[ -d modules ]]"
run_test "services directory" "[[ -d services ]]"
run_test "config directory" "[[ -d config ]]"
run_test "utils directory" "[[ -d utils ]]"
run_test "widgets directory" "[[ -d widgets ]]"
run_test "assets directory" "[[ -d assets ]]"

# Test 4: Check beat detector
if [[ -n "${CAELESTIA_BD_PATH:-}" ]]; then
    run_test "beat detector (env)" "[[ -x '$CAELESTIA_BD_PATH' ]]"
elif [[ -x "$HOME/.local/lib/caelestia/beat_detector" ]]; then
    run_test "beat detector (local)" "[[ -x '$HOME/.local/lib/caelestia/beat_detector' ]]"
else
    run_test "beat detector" "false" "false"
fi

# Test 5: Check configuration
run_test "config directory exists" "[[ -d '$HOME/.config/caelestia' ]]"
run_test "quickshell config dir" "[[ -d '$HOME/.config/quickshell' ]]"

# Test 6: Check dependencies
run_test "ddcutil" "command -v ddcutil" "false"
run_test "brightnessctl" "command -v brightnessctl" "false"
run_test "cava" "command -v cava" "false"
run_test "grim" "command -v grim" "false"
run_test "swappy" "command -v swappy" "false"
run_test "fish" "command -v fish" "false"
run_test "networkmanager" "command -v nmcli" "false"

# Test 7: Check Nix features
run_test "nix command" "command -v nix"
run_test "nix flakes" "nix flake --help" "false"

# Test 8: Check Wayland environment
run_test "Wayland display" "[[ -n '${WAYLAND_DISPLAY:-}' ]]" "false"
run_test "Hyprland" "command -v hyprctl" "false"

# Test 9: Check scripts
run_test "run-nixos.sh" "[[ -x run-nixos.sh ]]"
run_test "build-beat-detector.sh" "[[ -x build-beat-detector.sh ]]"
run_test "install-nixos.sh" "[[ -x install-nixos.sh ]]"
run_test "caelestia-shell launcher" "[[ -x caelestia-shell ]]"

# Test 10: Check flake.nix
run_test "flake.nix exists" "[[ -f flake.nix ]]"
if [[ -f flake.nix ]]; then
    run_test "flake.nix syntax" "nix flake check --no-build" "false"
fi

echo ""
echo "Test Results"
echo "============"
echo "Total tests: $test_count"
echo -e "${COLOR_GREEN}Passed: $pass_count${COLOR_NC}"
if [[ $fail_count -gt 0 ]]; then
    echo -e "${COLOR_RED}Failed: $fail_count${COLOR_NC}"
fi
if [[ $warn_count -gt 0 ]]; then
    echo -e "${COLOR_YELLOW}Warnings: $warn_count${COLOR_NC}"
fi

echo ""
if [[ $fail_count -eq 0 ]]; then
    echo -e "${COLOR_GREEN}✓ All critical tests passed!${COLOR_NC}"
    echo ""
    echo "You can now run caelestia-shell with:"
    echo "  ./caelestia-shell"
    echo "  or"
    echo "  quickshell -c caelestia  (if installed in ~/.config/quickshell/)"
    
    if [[ $warn_count -gt 0 ]]; then
        echo ""
        echo "Note: Some optional dependencies are missing."
        echo "For full functionality, install them in your NixOS configuration."
    fi
else
    echo -e "${COLOR_RED}✗ Some critical tests failed!${COLOR_NC}"
    echo ""
    echo "Please check the failed tests above and:"
    echo "1. Ensure you're running this on NixOS"
    echo "2. Install quickshell and dependencies"
    echo "3. Run the installation script: ./install-nixos.sh"
    echo "4. Build the beat detector: ./build-beat-detector.sh"
fi

echo ""

# Exit with appropriate code
if [[ $fail_count -eq 0 ]]; then
    exit 0
else
    exit 1
fi