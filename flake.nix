{
  description = "Noti Application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    {
      inherit (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };

          rustToolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);

          noti = pkgs.rustPlatform.buildRustPackage {
            pname = "noti";
            version = "0.1.0";

            src = pkgs.fetchFromGitHub {
              owner = "noti-rs";
              repo = "noti";
              rev = "a3a3f2e6223ae40d560b5e0eebfc0955cd0af190";
              hash = "sha256-puVDJ5H0csxYlVWglyjdPctb83UJ4ik7mEl2R3ejKdQ=";
            };

            cargoHash = "sha256-LG2OCCMM9enn2+I1eNZFUK7ZKK8JvYXQ/r8NyiRx9L4=";

            nativeBuildInputs = [
              pkgs.pkg-config
            ];

            buildInputs = [
              pkgs.glib
              pkgs.cairo
              pkgs.pango
            ];

            meta = with pkgs.lib; {
              description = "A powerful Notification daemon for wayland";
              homepage = "https://github.com/noti-rs/noti";
              license = licenses.gpl3;
              maintainers = [ "noti-rs" ];
              platforms = platforms.linux;
            };

            cargo = rustToolchain;
            rustc = rustToolchain;
          };
        in
        {
          packages.default = noti;
        }
      )) packages;

      homeModules.default =
        { config, lib, pkgs, ... }: {
          options.programs.noti = {
            enable = lib.mkEnableOption "Noti Application";

            service = {
              enable = lib.mkEnableOption "Noti Service";
            };
          };


          config = lib.mkIf config.programs.noti.enable {
            home.packages = [
              pkgs.noti
            ];

            systemd.services.noti = lib.mkIf config.programs.noti.service.enable {
              description = "Noti — Wayland notification daemon";
              partOf = [ "graphical-session.target" ];
              after = [ "graphical-session.target" ];
              wantedBy = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "dbus";
                BusName = "org.freedesktop.Notifications";
                Environment = "NOTI_LOG=info";
                ExecCondition = "${pkgs.sh} -c '[ -n $WAYLAND_DISPLAY ]'";
                ExecStart = "${pkgs.noti}/bin/noti run";
                Restart = "on-failure";
              };
            };
          };
        };

    };
}

