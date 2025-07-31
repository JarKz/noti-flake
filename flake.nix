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

          noti-rs = pkgs.rustPlatform.buildRustPackage {
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
          packages.default = noti-rs;
        }
      )) packages;

      homeModules.default =
        { config, lib, pkgs, ... }:
        let
          noti-rs = self.packages."${pkgs.stdenv.system}".default;
        in
        {
          options.programs.noti-rs = {
            enable = lib.mkEnableOption "Noti Application";

            service = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable noti systemd service";
            };
          };


          config = lib.mkIf config.programs.noti-rs.enable {
            home.packages = [
              noti-rs
            ];

            systemd.user.services.noti = lib.mkIf config.programs.noti-rs.service {
              Unit = {
                Description = "Noti — Wayland notification daemon";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
              Service = {
                Type = "dbus";
                BusName = "org.freedesktop.Notifications";
                Environment = "NOTI_LOG=info";
                ExecCondition = "${pkgs.bash}/bin/sh -c '[ -n $WAYLAND_DISPLAY ]'";
                ExecStart = "${noti-rs}/bin/noti-rs run";
                Restart = "on-failure";
              };
            };
          };
        };
    };
}

