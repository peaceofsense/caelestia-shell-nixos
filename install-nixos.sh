#!/usr/bin/env bash

# Installation script for caelestia-shell on NixOS
# This script helps users set up caelestia-shell quickly

set -euo pipefail

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

print_header() {
    echo -e "${COLOR_BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Caelestia Shell for NixOS                ║"
    echo "║                     Installation Script                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${COLOR_NC}"
}

print_step() {
    echo -e "${COLOR_YELLOW}[STEP]${COLOR_NC} $1"
}

print_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"
}

print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

print_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"
}

check_requirements() {
    print_step "Checking requirements..."
    
    # Check if we're on NixOS
    if [[ ! -f /etc/NIXOS ]]; then
        print_error "This script is designed for NixOS. For other distributions, please use the original caelestia-shell."
        exit 1
    fi
    
    # Check if nix command is available
    if ! command -v nix &> /dev/null; then
        print_error "Nix command not found. Please ensure Nix is properly installed."
        exit 1
    fi
    
    # Check if flakes are enabled
    if ! nix flake --help &> /dev/null; then
        print_error "Nix flakes are not enabled. Please enable flakes in your NixOS configuration:"
        echo "  nix.settings.experimental-features = [ \"nix-command\" \"flakes\" ];"
        exit 1
    fi
    
    print_success "Requirements check passed"
}

setup_directories() {
    print_step "Setting up directories..."
    
    # Create quickshell config directory
    mkdir -p "$HOME/.config/quickshell"
    
    # Create caelestia config directory
    mkdir -p "$HOME/.config/caelestia"
    
    # Create wallpapers directory
    mkdir -p "$HOME/Pictures/Wallpapers"
    
    # Create local lib directory for beat detector
    mkdir -p "$HOME/.local/lib/caelestia"
    
    print_success "Directories created"
}

install_shell() {
    print_step "Installing caelestia-shell..."
    
    local install_dir="$HOME/.config/quickshell/caelestia"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if we're already in the right directory
    if [[ "$(basename "$script_dir")" == "caelestia" && -f "$script_dir/shell.qml" ]]; then
        print_info "Already in caelestia-shell directory, creating symlink..."
        if [[ -L "$install_dir" ]]; then
            rm "$install_dir"
        elif [[ -d "$install_dir" ]]; then
            print_error "Directory $install_dir already exists and is not a symlink."
            echo "Please remove it manually: rm -rf '$install_dir'"
            exit 1
        fi
        ln -s "$script_dir" "$install_dir"
    else
        # Copy files to quickshell config directory
        if [[ -d "$install_dir" ]]; then
            print_info "Existing installation found, backing up..."
            mv "$install_dir" "${install_dir}.backup.$(date +%s)"
        fi
        
        cp -r "$script_dir" "$install_dir"
    fi
    
    print_success "Shell files installed to $install_dir"
}

build_beat_detector() {
    print_step "Building beat detector..."
    
    local install_dir="$HOME/.config/quickshell/caelestia"
    
    if [[ -x "$install_dir/build-beat-detector.sh" ]]; then
        cd "$install_dir"
        bash build-beat-detector.sh
    else
        print_error "Build script not found. Trying manual build..."
        
        if [[ -f "$install_dir/assets/beat_detector.cpp" ]]; then
            nix-shell -p gcc pkg-config pipewire.dev aubio --run "
                cd '$install_dir'
                g++ -std=c++17 -Wall -Wextra \
                    \$(pkg-config --cflags libpipewire-0.3 aubio) \
                    -o '$HOME/.local/lib/caelestia/beat_detector' \
                    'assets/beat_detector.cpp' \
                    \$(pkg-config --libs libpipewire-0.3 aubio)
            "
            
            if [[ -x "$HOME/.local/lib/caelestia/beat_detector" ]]; then
                print_success "Beat detector built successfully"
            else
                print_error "Failed to build beat detector"
                exit 1
            fi
        else
            print_error "Beat detector source not found"
            exit 1
        fi
    fi
}

setup_config() {
    print_step "Setting up configuration..."
    
    local config_file="$HOME/.config/caelestia/shell.json"
    
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
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
        print_success "Default configuration created"
    else
        print_info "Configuration file already exists, skipping"
    fi
}

check_dependencies() {
    print_step "Checking dependencies..."
    
    local missing_deps=()
    local deps=("quickshell" "ddcutil" "brightnessctl" "cava" "grim" "swappy")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please add these packages to your NixOS configuration:"
        echo "environment.systemPackages = with pkgs; ["
        for dep in "${missing_deps[@]}"; do
            echo "  $dep"
        done
        echo "];"
        echo ""
        echo "Then rebuild your system: sudo nixos-rebuild switch"
        exit 1
    else
        print_success "All dependencies found"
    fi
}

print_completion() {
    echo ""
    echo -e "${COLOR_GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${COLOR_NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the shell: quickshell -c caelestia"
    echo "2. Or use the run script: ~/.config/quickshell/caelestia/run-nixos.sh"
    echo ""
    echo "For Hyprland integration, add this to your hyprland.conf:"
    echo "  exec-once = quickshell -c caelestia"
    echo ""
    echo "For system-wide installation with Nix flakes, see:"
    echo "  ~/.config/quickshell/caelestia/nixos-module-example.nix"
    echo ""
    echo "Configuration file: ~/.config/caelestia/shell.json"
    echo "Wallpapers directory: ~/Pictures/Wallpapers"
    echo ""
}

main() {
    print_header
    
    check_requirements
    setup_directories
    install_shell
    build_beat_detector
    setup_config
    check_dependencies
    
    print_completion
}

# Handle script interruption
trap 'echo -e "\n${COLOR_RED}Installation interrupted${COLOR_NC}"; exit 1' INT TERM

# Run main function
main "$@"