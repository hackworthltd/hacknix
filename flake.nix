{
  description = "Hackworth Ltd's nixpkgs overlays and NixOS modules.";

  inputs = {
    nixpkgs.url = github:hackworthltd/nixpkgs/big-sur-fixes-v2;

    nix-darwin.url = github:LnL7/nix-darwin;
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = github:numtide/flake-utils;

    flake-compat.url = github:edolstra/flake-compat;
    flake-compat.flake = false;

    hacknix-lib.url = github:hackworthltd/hacknix-lib;

    aws-export-credentials.url = github:benkehoe/aws-export-credentials;
    aws-export-credentials.flake = false;

    aws-sso-credential-process.url = github:benkehoe/aws-sso-credential-process;
    aws-sso-credential-process.flake = false;

    badhosts.url = github:StevenBlack/hosts;
    badhosts.flake = false;

    chamber.url = github:hackworthltd/chamber;
    chamber.flake = false;

    emacs-overlay.url = github:nix-community/emacs-overlay;

    gitignore-nix.url = github:hercules-ci/gitignore.nix;
    gitignore-nix.flake = false;

    hydra.url = github:NixOS/hydra;

    traefik-forward-auth.url = github:thomseddon/traefik-forward-auth;
    traefik-forward-auth.flake = false;

    spago2nix.url = github:justinwoo/spago2nix;
    spago2nix.flake = false;
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nix-darwin
    , hacknix-lib
    , emacs-overlay
    , ...
    }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      testSystems = [ "x86_64-linux" ];
      forAllTestSystems = f: nixpkgs.lib.genAttrs testSystems (system: f system);

      asList = attrs: map (name: attrs.${name}) (builtins.attrNames attrs);

      allOverlays = [
        emacs-overlay.overlay
      ]
      ++ asList hacknix-lib.overlays
      ++ asList self.overlays;

      config = {
        allowUnfree = true;
        allowBroken = true;
      };

      # Memoize nixpkgs for a given system;
      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system config;
          overlays = allOverlays;
        }
      );

    in
    {
      lib = pkgsFor.x86_64-linux.lib;

      # Nix's flake support expects this to be an attrset, even though
      # it's not useful as an attrset downstream (e.g.,
      # `nixpkgs.overlays` expects to be passed a list of overlays,
      # not an attrset.)
      overlays = (hacknix-lib.lib.sources.importDirectory ./nix/overlays) // {
        "000-flakes" = (final: prev: {
          lib = (prev.lib or { }) // {
            hacknix = (prev.lib.hacknix or { }) // {
              flake = (prev.lib.hacknix.flake or { }) // {
                inherit inputs;
                inherit (self) darwinModule;
                inherit (self) nixosModule;
              };
            };
          };
        });
      };

      packages = forAllSystems
        (system:
          let
            pkgs = pkgsFor.${system};
          in
          (hacknix-lib.lib.misc.filterPackagesByPlatform system
            {
              inherit (pkgs) awscli2;
              inherit (pkgs) aws-export-credentials;
              inherit (pkgs) aws-sso-credential-process;

              inherit (pkgs) badhosts-unified;
              inherit (pkgs)
                badhosts-fakenews badhosts-gambling badhosts-nsfw badhosts-social
                ;
              inherit (pkgs)
                badhosts-fakenews-gambling badhosts-fakenews-nsfw badhosts-fakenews-social
                ;
              inherit (pkgs) badhosts-gambling-nsfw badhosts-gambling-social;
              inherit (pkgs) badhosts-nsfw-social;
              inherit (pkgs)
                badhosts-fakenews-gambling-nsfw badhosts-fakenews-gambling-social
                ;
              inherit (pkgs) badhosts-fakenews-nsfw-social;
              inherit (pkgs) badhosts-gambling-nsfw-social;
              inherit (pkgs) badhosts-fakenews-gambling-nsfw-social;
              inherit (pkgs) badhosts-all;

              inherit (pkgs) chamber;
              inherit (pkgs) delete-tweets;
              inherit (pkgs) emacsGcc;
              inherit (pkgs) ffmpeg-full;
              inherit (pkgs) fsatrace;
              inherit (pkgs) hostapd;
              inherit (pkgs) hydra-unstable;
              inherit (pkgs) libprelude;
              inherit (pkgs) macnix-rebuild;
              inherit (pkgs) nmrpflash;
              inherit (pkgs) spago2nix;
              inherit (pkgs) traefik-forward-auth;
              inherit (pkgs) trimpcap;
              inherit (pkgs) tsoff;
              inherit (pkgs) wpa_supplicant;
              inherit (pkgs) yubikey-manager;

              # Various buildEnv's that we use, usually only on macOS (though many
              # of them should work on any pltform).
              inherit (pkgs) anki-env;
              inherit (pkgs) mactools-env;
              inherit (pkgs) maths-env;
              inherit (pkgs) nixtools-env;
              inherit (pkgs) shell-env;

              # These aren't actually derivations, and therefore, we
              # can't export them from packages. They are in the overlay, however.

              # We don't override these, but just want to make sure they build.
              inherit (pkgs) neovim;

              # These aren't actually derivations, and therefore, we
              # can't export them from packages. They are in the overlay, however.
              # inherit (pkgs) mkCacert;
              # inherit (pkgs) gitignoreSource gitignoreFilter;
              # inherit (pkgs) hashedCertDir;
              # inherit (pkgs) lib;

              # Build these overrides (for Big Sur support) until
              # they're upstreamed.
              inherit (pkgs) python38 python39;
            }) //
          # For some reason, the filterPackagesByPlatform doesn't
          # filter these Linux kernels from the macOS package set, so
          # we do these here separately.
          (if pkgs.stdenv.isLinux then
            {
              # Linux kernels.
              inherit (pkgs) linux_ath10k;
              inherit (pkgs) linux_ath10k_ct;

              # These aren't actually derivations, and therefore, we
              # can't export them from packages. They are in the overlay, however.
              # inherit (pkgs) linuxPackages_ath10k;
              # inherit (pkgs) linuxPackages_ath10k_ct;
            } else { })
        );

      # Ideally, this would be refactored into multiple stand-alone
      # modules, but many of these modules are interdependent at the
      # moment, so we simply export them as a single module, for now.
      nixosModule = {
        imports = [
          ./nix/modules/config/providers/linode/default.nix

          ./nix/modules/config/providers/vultr/cloud/default.nix

          ./nix/modules/config/defaults/default.nix
          ./nix/modules/config/defaults/acme.nix
          ./nix/modules/config/defaults/environment.nix
          ./nix/modules/config/defaults/networking.nix
          ./nix/modules/config/defaults/nginx.nix
          ./nix/modules/config/defaults/nix.nix
          ./nix/modules/config/defaults/security.nix
          ./nix/modules/config/defaults/ssh.nix
          ./nix/modules/config/defaults/sudo.nix
          ./nix/modules/config/defaults/system.nix
          ./nix/modules/config/defaults/tmux.nix
          ./nix/modules/config/defaults/users.nix

          ./nix/modules/config/services/fail2ban
          ./nix/modules/config/services/freeradius

          ./nix/modules/config/hardware/amd/common.nix
          ./nix/modules/config/hardware/amd/jaguar.nix
          ./nix/modules/config/hardware/apu2/apu3c4.nix
          ./nix/modules/config/hardware/intel/broadwell-de.nix
          ./nix/modules/config/hardware/intel/centerton.nix
          ./nix/modules/config/hardware/intel/coffee-lake.nix
          ./nix/modules/config/hardware/intel/common.nix
          ./nix/modules/config/hardware/intel/haswell.nix
          ./nix/modules/config/hardware/intel/kaby-lake.nix
          ./nix/modules/config/hardware/intel/sandy-bridge.nix
          ./nix/modules/config/hardware/smartd/1x-non-removable.nix
          ./nix/modules/config/hardware/smartd/2x-non-removable.nix
          ./nix/modules/config/hardware/smartd/36x-hotswap.nix
          ./nix/modules/config/hardware/smartd/4x-hotswap.nix
          ./nix/modules/config/hardware/supermicro/sys-5017a-ef.nix
          ./nix/modules/config/hardware/supermicro/sys-5018d-fn4t.nix
          ./nix/modules/config/hardware/supermicro/sys-5018d-mtln4f.nix
          ./nix/modules/config/hardware/supermicro/mb-x10.nix
          ./nix/modules/config/hardware/hwutils.nix
          ./nix/modules/config/hardware/jetson-tk1.nix
          ./nix/modules/config/hardware/jetson-tx1.nix
          ./nix/modules/config/hardware/mbr.nix
          ./nix/modules/config/hardware/uefi.nix
          ./nix/modules/config/networking/tcp-bbr
          ./nix/modules/config/nix/auto-gc
          ./nix/modules/config/remote-builds/remote-build-host
          ./nix/modules/config/remote-builds/build-host
          ./nix/modules/core/keychain
          ./nix/modules/core/module-hashes.nix
          ./nix/modules/dns/unbound-multi-instance
          ./nix/modules/email/dovecot
          ./nix/modules/email/null-client
          ./nix/modules/email/opendkim
          ./nix/modules/email/postfix-mta
          ./nix/modules/email/relay-host
          ./nix/modules/email/service-status-email
          ./nix/modules/networking/accept
          ./nix/modules/networking/pcap-prep
          ./nix/modules/networking/virtual-ips
          ./nix/modules/networking/wireguard-dhess

          ./nix/modules/services/apcupsd-net
          ./nix/modules/services/hydra-manual-setup
          ./nix/modules/services/netsniff-ng
          ./nix/modules/services/systemd-digitalocean
          ./nix/modules/services/tarsnapper
          ./nix/modules/services/traefik-forward-auth
          ./nix/modules/services/tftpd-hpa
          ./nix/modules/services/znc
        ];
        nixpkgs.overlays = allOverlays;
      };

      nixosConfigurations = self.lib.hacknix.importNixosConfigurations ./examples/nixos {
        inherit (self) lib;
      };

      darwinModule = {
        imports = [
          ./nix/darwinModules/config/defaults/default.nix
          ./nix/darwinModules/config/remote-builds/build-host
          ./nix/darwinModules/config/remote-builds/remote-build-host
        ];
        nixpkgs.overlays = allOverlays;
      };

      darwinConfigurations = self.lib.hacknix.importDarwinConfigurations ./examples/nix-darwin {
        inherit (self) lib;
      };

      hydraJobs = {
        build = self.packages;
        nixosConfigurations = hacknix-lib.lib.misc.buildNixosConfigurations self.nixosConfigurations;
        darwinConfigurations = hacknix-lib.lib.misc.buildNixosConfigurations self.darwinConfigurations;
        tests = forAllTestSystems
          (system:
            self.lib.hacknix.importNixosTests ./tests/fixtures
              {
                inherit system;
                pkgs = pkgsFor.${system};
                extraConfigurations = [ self.nixosModule ];
              }
              { });
      };
    };
}