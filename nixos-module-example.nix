# Example NixOS configuration for caelestia-shell
# Add this to your NixOS configuration to enable caelestia-shell

{ config, lib, pkgs, ... }:

{
  # Import the caelestia-shell flake (add this to your flake inputs)
  # inputs.caelestia-shell.url = "github:your-repo/caelestia-shell-nixos";
  
  # Enable caelestia-shell service
  services.caelestia-shell = {
    enable = true;
    
    # Optional: customize configuration
    config = {
      bar.workspaces = {
        shown = 7;  # Show 7 workspaces instead of default 5
        activeLabel = "● ";
        occupiedLabel = "○ ";
      };
      
      dashboard = {
        weatherLocation = "40.7128,-74.0060";  # NYC coordinates
        visualiserBars = 60;
      };
      
      launcher = {
        maxShown = 10;
        enableDangerousActions = false;  # Keep this false for safety
      };
      
      paths = {
        wallpaperDir = "~/Pictures/Wallpapers";
        # You can also use absolute paths:
        # wallpaperDir = "/home/username/Pictures/Wallpapers";
      };
    };
  };
  
  # Required system packages (automatically included when enabling the service)
  # But you might want to add them explicitly for other uses
  environment.systemPackages = with pkgs; [
    # Core requirements
    quickshell
    
    # System utilities
    ddcutil          # Display brightness control
    brightnessctl    # Backlight control
    networkmanager   # Network management
    lm_sensors       # Hardware sensors
    
    # Audio and media
    cava            # Audio visualizer
    pipewire        # Audio system
    
    # Screenshot and image tools
    grim            # Screenshot tool
    swappy          # Screenshot editor
    
    # Calculator
    libqalculate    # Calculator library
    
    # Fonts
    material-symbols
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    
    # Shell
    fish            # Fish shell (optional, but recommended)
  ];
  
  # Enable required services
  services = {
    # Audio system
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Display manager (choose one)
    # SDDM (recommended for Wayland)
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    
    # Or GDM
    # xserver.displayManager.gdm.enable = true;
  };
  
  # Enable Hyprland (required)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  # Optional: Enable fish shell globally
  programs.fish.enable = true;
  
  # Optional: Set fish as default shell for your user
  # users.users.your-username.shell = pkgs.fish;
  
  # Security settings for ddcutil (brightness control)
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  
  # Add your user to required groups
  users.users.your-username = {
    extraGroups = [
      "wheel"        # sudo access
      "networkmanager"  # network management
      "audio"        # audio devices
      "video"        # video devices
      "i2c"          # brightness control
    ];
  };
  
  # Optional: Hyprland configuration example
  # You can put this in ~/.config/hypr/hyprland.conf instead
  environment.etc."hypr/hyprland.conf.example".text = ''
    # Example Hyprland configuration for caelestia-shell
    
    # Start caelestia-shell on login
    exec-once = systemctl --user start caelestia-shell
    
    # Keybinds for caelestia-shell
    $mainMod = SUPER
    
    # Media controls
    bind = , XF86AudioPlay, exec, quickshell --ipc mpris playPause
    bind = , XF86AudioNext, exec, quickshell --ipc mpris next
    bind = , XF86AudioPrev, exec, quickshell --ipc mpris previous
    bind = , XF86AudioStop, exec, quickshell --ipc mpris stop
    
    # Shell controls
    bind = $mainMod, Space, exec, quickshell --ipc drawers "toggle" "launcher"
    bind = $mainMod, D, exec, quickshell --ipc drawers "toggle" "dashboard"
    bind = $mainMod, L, exec, quickshell --ipc lock lock
    bind = $mainMod, Escape, exec, quickshell --ipc drawers "toggle" "session"
    
    # Screenshot
    bind = $mainMod SHIFT, S, exec, quickshell --ipc picker open
    bind = $mainMod CTRL SHIFT, S, exec, quickshell --ipc picker openFreeze
    
    # Notifications
    bind = $mainMod, N, exec, quickshell --ipc notifs clear
    
    # Volume controls (if you want to use shell's OSD)
    bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    
    # Brightness controls
    bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
    
    # Window management (basic example)
    bind = $mainMod, Q, killactive
    bind = $mainMod, M, exit
    bind = $mainMod, V, togglefloating
    bind = $mainMod, P, pseudo
    bind = $mainMod, J, togglesplit
    
    # Move focus
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d
    
    # Switch workspaces
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10
    
    # Move active window to workspace
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10
  '';
  
  # Optional: Enable automatic login (useful for single-user systems)
  # services.displayManager.autoLogin = {
  #   enable = true;
  #   user = "your-username";
  # };
}