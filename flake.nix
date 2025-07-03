{
  description = "caelestia-shell for NixOS - A beautiful desktop shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        beat-detector = pkgs.stdenv.mkDerivation {
          pname = "caelestia-beat-detector";
          version = "1.0.0";
          
          src = ./assets;
          
          nativeBuildInputs = with pkgs; [
            gcc
            pkg-config
          ];
          
          buildInputs = with pkgs; [
            pipewire.dev
            aubio
          ];
          
          buildPhase = ''
            g++ -std=c++17 -Wall -Wextra \
              $(pkg-config --cflags libpipewire-0.3 aubio) \
              -o beat_detector beat_detector.cpp \
              $(pkg-config --libs libpipewire-0.3 aubio)
          '';
          
          installPhase = ''
            mkdir -p $out/bin
            cp beat_detector $out/bin/caelestia-beat-detector
          '';
        };
        
        caelestia-shell = pkgs.stdenv.mkDerivation {
          pname = "caelestia-shell";
          version = "1.0.0-nixos";
          
          src = ./.;
          
          nativeBuildInputs = with pkgs; [
            makeWrapper
          ];
          
          buildInputs = with pkgs; [
            quickshell
            beat-detector
          ];
          
          installPhase = ''
            mkdir -p $out/share/caelestia-shell
            
            # Copy all QML files and assets
            cp -r modules $out/share/caelestia-shell/
            cp -r config $out/share/caelestia-shell/
            cp -r services $out/share/caelestia-shell/
            cp -r utils $out/share/caelestia-shell/
            cp -r widgets $out/share/caelestia-shell/
            cp -r assets $out/share/caelestia-shell/
            cp shell.qml $out/share/caelestia-shell/
            
            # Create wrapper script
            mkdir -p $out/bin
            makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/caelestia-shell \
              --add-flags "-p $out/share/caelestia-shell" \
              --set CAELESTIA_BD_PATH "${beat-detector}/bin/caelestia-beat-detector" \
              --prefix PATH : ${pkgs.lib.makeBinPath [
                pkgs.ddcutil
                pkgs.brightnessctl
                pkgs.cava
                pkgs.networkmanager
                pkgs.lm_sensors
                pkgs.fish
                pkgs.grim
                pkgs.swappy
                pkgs.libqalculate
              ]}
            
            # Create systemd user service
            mkdir -p $out/share/systemd/user
            cat > $out/share/systemd/user/caelestia-shell.service << EOF
[Unit]
Description=Caelestia Shell
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=simple
ExecStart=$out/bin/caelestia-shell
Restart=on-failure
RestartSec=1
TimeoutStopSec=10
KillMode=mixed
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=graphical-session.target
EOF
          '';
          
          meta = with pkgs.lib; {
            description = "A beautiful desktop shell for Hyprland (NixOS version)";
            homepage = "https://github.com/caelestia-dots/shell";
            license = licenses.mit;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };
        
      in {
        packages = {
          default = caelestia-shell;
          caelestia-shell = caelestia-shell;
          beat-detector = beat-detector;
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            quickshell
            gcc
            pkg-config
            pipewire.dev
            aubio
            ddcutil
            brightnessctl
            cava
            networkmanager
            lm_sensors
            fish
            grim
            swappy
            libqalculate
            material-symbols
            (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
          ];
          
          shellHook = ''
            echo "Caelestia Shell development environment"
            echo "Run 'quickshell -p .' to test the shell"
            echo "Run 'nix build' to build the package"
          '';
        };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.services.caelestia-shell;
          configFile = pkgs.writeText "shell.json" (builtins.toJSON cfg.config);
        in {
          options.services.caelestia-shell = {
            enable = mkEnableOption "Caelestia Shell";
            
            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The caelestia-shell package to use";
            };
            
            config = mkOption {
              type = types.attrs;
              default = {
                bar = {
                  workspaces = {
                    activeIndicator = true;
                    activeLabel = "󰮯 ";
                    activeTrail = false;
                    label = "  ";
                    occupiedBg = false;
                    occupiedLabel = "󰮯 ";
                    rounded = true;
                    showWindows = true;
                    shown = 5;
                  };
                };
                border = {
                  rounding = 25;
                  thickness = 10;
                };
                dashboard = {
                  mediaUpdateInterval = 500;
                  visualiserBars = 45;
                  weatherLocation = "0,0";
                };
                launcher = {
                  actionPrefix = ">";
                  enableDangerousActions = false;
                  maxShown = 8;
                  maxWallpapers = 9;
                };
                lock = {
                  maxNotifs = 5;
                };
                notifs = {
                  actionOnClick = false;
                  clearThreshold = 0.3;
                  defaultExpireTimeout = 5000;
                  expandThreshold = 20;
                  expire = false;
                };
                osd = {
                  hideDelay = 2000;
                };
                paths = {
                  mediaGif = "root:/assets/bongocat.gif";
                  sessionGif = "root:/assets/kurukuru.gif";
                  wallpaperDir = "~/Pictures/Wallpapers";
                };
                session = {
                  dragThreshold = 30;
                };
              };
              description = "Configuration for caelestia-shell";
            };
          };
          
          config = mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
            
            systemd.user.services.caelestia-shell = {
              description = "Caelestia Shell";
              partOf = [ "graphical-session.target" ];
              after = [ "graphical-session.target" ];
              
              serviceConfig = {
                Type = "simple";
                ExecStart = "${cfg.package}/bin/caelestia-shell";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
                KillMode = "mixed";
                Environment = [ "QT_QPA_PLATFORM=wayland" ];
              };
              
              wantedBy = [ "graphical-session.target" ];
            };
            
            # Ensure config directory exists and copy config
            system.userActivationScripts.caelestia-shell = ''
              mkdir -p $HOME/.config/caelestia
              if [ ! -f $HOME/.config/caelestia/shell.json ]; then
                cp ${configFile} $HOME/.config/caelestia/shell.json
              fi
            '';
            
            # Required system packages
            environment.systemPackages = with pkgs; [
              ddcutil
              brightnessctl
              cava
              networkmanager
              lm_sensors
              fish
              grim
              swappy
              libqalculate
              material-symbols
              (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
            ];
            
            # Enable required services
            services.pipewire.enable = mkDefault true;
            programs.hyprland.enable = mkDefault true;
          };
        };
    };
}