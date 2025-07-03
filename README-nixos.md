# caelestia-shell for NixOS

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>

A NixOS-compatible version of caelestia-shell that can be run directly with quickshell or packaged with Nix.

## Components

-   Widgets: [`Quickshell`](https://quickshell.outfoxxed.me)
-   Window manager: [`Hyprland`](https://hyprland.org)
-   Original dots: [`caelestia`](https://github.com/caelestia-dots)

## Installation on NixOS

### Method 1: Direct quickshell execution

1. Install quickshell in your NixOS configuration:
```nix
# configuration.nix
environment.systemPackages = with pkgs; [
  quickshell
  # Required dependencies
  ddcutil
  brightnessctl
  cava
  networkmanager
  lm_sensors
  fish
  aubio
  pipewire
  grim
  swappy
  libqalculate
  material-symbols
  (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
];
```

2. Clone this repository to your quickshell config directory:
```bash
mkdir -p ~/.config/quickshell
cd ~/.config/quickshell
git clone https://github.com/your-repo/caelestia-shell-nixos.git caelestia
```

3. Build the beat detector:
```bash
cd ~/.config/quickshell/caelestia
nix-shell -p gcc pipewire.dev aubio --run \
  "g++ -std=c++17 -Wall -Wextra -I\$NIX_CFLAGS_COMPILE -o beat_detector assets/beat_detector.cpp -lpipewire-0.3 -laubio"
mkdir -p ~/.local/lib/caelestia
mv beat_detector ~/.local/lib/caelestia/
```

4. Run the shell:
```bash
quickshell -c caelestia
```

### Method 2: Nix package (recommended)

Add the following to your NixOS configuration:

```nix
# flake.nix or configuration.nix
{
  inputs.caelestia-shell = {
    url = "github:your-repo/caelestia-shell-nixos";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, caelestia-shell, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      modules = [
        caelestia-shell.nixosModules.default
        {
          services.caelestia-shell.enable = true;
          # Optional: customize configuration
          services.caelestia-shell.config = {
            bar.workspaces.shown = 7;
            dashboard.weatherLocation = "40.7128,-74.0060"; # NYC coordinates
          };
        }
      ];
    };
  };
}
```

## Usage

### Starting the shell

- **Direct command**: `quickshell -c caelestia`
- **With systemd** (if using Nix package): The shell will start automatically with your session
- **Manual systemd**: `systemctl --user start caelestia-shell`

### IPC Commands

All IPC commands are available through quickshell's built-in IPC system:

```bash
# Media controls
quickshell --ipc mpris playPause
quickshell --ipc mpris next
quickshell --ipc mpris previous
quickshell --ipc mpris "getActive" "trackTitle"

# Notifications
quickshell --ipc notifs clear

# Lock screen
quickshell --ipc lock lock
quickshell --ipc lock unlock
quickshell --ipc lock isLocked

# Drawers/panels
quickshell --ipc drawers "toggle" "launcher"
quickshell --ipc drawers list

# Screenshot tool
quickshell --ipc picker open
quickshell --ipc picker openFreeze

# Wallpaper
quickshell --ipc wallpaper "set" "/path/to/wallpaper.jpg"
quickshell --ipc wallpaper get
quickshell --ipc wallpaper list
```

### Hyprland Integration

Add these keybinds to your Hyprland configuration:

```bash
# ~/.config/hypr/hyprland.conf

# Media controls
bind = , XF86AudioPlay, exec, quickshell --ipc mpris playPause
bind = , XF86AudioNext, exec, quickshell --ipc mpris next
bind = , XF86AudioPrev, exec, quickshell --ipc mpris previous

# Shell controls
bind = SUPER, Space, exec, quickshell --ipc drawers "toggle" "launcher"
bind = SUPER, L, exec, quickshell --ipc lock lock
bind = SUPER SHIFT, S, exec, quickshell --ipc picker open
bind = SUPER CTRL SHIFT, S, exec, quickshell --ipc picker openFreeze

# Dashboard and session
bind = SUPER, D, exec, quickshell --ipc drawers "toggle" "dashboard"
bind = SUPER, Escape, exec, quickshell --ipc drawers "toggle" "session"
```

## Configuration

Configuration is stored in `~/.config/caelestia/shell.json`. The file will be created with default values on first run.

### Profile Picture and Wallpapers

- **Profile picture**: Copy your image to `~/.face`
- **Wallpapers**: Place wallpapers in `~/Pictures/Wallpapers` (configurable in shell.json)

## Differences from Original

- **No caelestia-cli dependency**: Uses quickshell's native IPC system
- **No system installation**: Runs from user config directory
- **Nix-friendly**: Beat detector builds with Nix toolchain
- **Simplified paths**: Uses XDG standard directories
- **NixOS integration**: Optional systemd service and module

## Troubleshooting

### Beat detector not working
```bash
# Check if beat detector exists and is executable
ls -la ~/.local/lib/caelestia/beat_detector

# Test manually
~/.local/lib/caelestia/beat_detector --no-log --no-stats --no-visual
```

### IPC commands not working
```bash
# Check if quickshell is running
pgrep quickshell

# Check available IPC targets
quickshell --ipc-list
```

### Missing dependencies
Ensure all required packages are installed in your NixOS configuration.

## Development

To modify the shell:

1. Edit QML files in `~/.config/quickshell/caelestia/`
2. Quickshell will automatically reload on file changes
3. For beat detector changes, rebuild with the nix-shell command above

## License

Same as original caelestia-shell project.