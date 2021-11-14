{
  description = "Hackworth Ltd's nixpkgs overlays and NixOS modules.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nix-darwin.url = github:hackworthltd/nix-darwin/fixes-v12;
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    arion-flake.url = github:hercules-ci/arion;
    arion-flake.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = github:numtide/flake-utils;

    flake-compat.url = github:edolstra/flake-compat;
    flake-compat.flake = false;

    badhosts.url = github:StevenBlack/hosts;
    badhosts.flake = false;

    emacs-overlay.url = github:nix-community/emacs-overlay;

    gitignore-nix.url = github:hercules-ci/gitignore.nix;
    gitignore-nix.flake = false;

    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , arion-flake
    , flake-utils
    , nixpkgs
    , nix-darwin
    , emacs-overlay
    , sops-nix
    , ...
    }@inputs:
    let
      bootstrap = (import ./nix/overlays/000-bootstrap.nix) { } nixpkgs;

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSupportedSystems = flake-utils.lib.eachSystem supportedSystems;

      testSystems = [ "x86_64-linux" ];
      forAllTestSystems = flake-utils.lib.eachSystem testSystems;

      linuxSystems = [ "x86_64-linux" ];
      forAllLinuxSystems = flake-utils.lib.eachSystem linuxSystems;

      macSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      forAllMacSystems = flake-utils.lib.eachSystem macSystems;

      pkgsFor = system: import nixpkgs
        {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
          overlays = [ self.overlay ];
        };

      lib = (pkgsFor "x86_64-linux").lib;

    in
    {
      inherit lib;

      overlay =
        let
          overlaysFromDir = bootstrap.lib.overlays.combineFromDir ./nix/overlays;
        in
        bootstrap.lib.overlays.combine [
          (final: prev: {
            lib = (prev.lib or { }) // {

              flakes = (prev.lib.flakes or { }) // {
                # For some reason, the nixpkgs flake doesn't roll its local
                # lib.nixosSystem into nixpkgs.lib. We expose it here.
                inherit (nixpkgs.lib) nixosSystem;

                # Ditto for nix-darwin's lib.darwinSystem function.
                inherit (nix-darwin.lib) darwinSystem;
              };

              hacknix = (prev.lib.hacknix or { }) // {
                # Hack to fix some issues with aarch64-darwin packages.
                pkgs_x86 = prev.lib.optionalAttrs (final.stdenv.hostPlatform.system == "aarch64-darwin") (pkgsFor "x86_64-darwin");
                flake = (prev.lib.hacknix.flake or { }) // {
                  inherit inputs;
                  inherit (self) darwinModule;
                  inherit (self) nixosModule;
                };

                arion.mkMeta = { modules, ... }: arion-flake.lib.eval {
                  inherit modules;
                  pkgs = final;
                };

                arion.buildImage = { name, meta, ... }:
                  let
                    descriptor = builtins.elemAt meta.config.docker-compose.raw.x-arion.images 0;
                    inherit (descriptor) imageName imageExe imageTag;
                  in
                  final.runCommand "${baseNameOf name}.tar.gz"
                    {
                      passthru = { inherit imageTag; };
                      nativeBuildInputs = [ final.pigz ];
                    } "${imageExe} | pigz -nT > $out";
              };
            };
          })
          arion-flake.overlay
          emacs-overlay.overlay
          sops-nix.overlay
          overlaysFromDir
        ];

      # Ideally, this would be refactored into multiple stand-alone
      # modules, but many of these modules are interdependent at the
      # moment, so we simply export them as a single module, for now.
      nixosModule = {
        imports = [
          ./nix/modules/config/providers/ec2/default.nix
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

          ./nix/modules/services/cloudflared
          ./nix/modules/services/hydra-manual-setup
          ./nix/modules/services/netsniff-ng
          ./nix/modules/services/tarsnapper
          ./nix/modules/services/tftpd-hpa
          ./nix/modules/services/vault/agent

          ./nix/common/config/services/vault/agent/auth/approle
          ./nix/common/config/services/vault/agent/template
          ./nix/common/config/services/vault/agent/template/aws-credentials
        ];
        nixpkgs.overlays = [ self.overlay ];
      };

      nixosConfigurations =
        let
          extraModules = [{
            boot.isContainer = true;
          }];
          mkSystem = self.lib.hacknix.nixosSystem' extraModules;
        in
        self.lib.flakes.nixosConfigurations.importFromDirectory
          mkSystem
          ./examples/nixos
          {
            inherit (self) lib;
          };

      darwinModule = {
        imports = [
          ./nix/darwinModules/config/defaults/default.nix
          ./nix/darwinModules/config/defaults/nix.nix
          ./nix/darwinModules/config/remote-builds/build-host
          ./nix/darwinModules/config/remote-builds/remote-build-host

          ./nix/darwinModules/config/services/vault-agent

          ./nix/common/config/services/vault/agent/auth/approle
          ./nix/common/config/services/vault/agent/template
          ./nix/common/config/services/vault/agent/template/aws-credentials
        ];
        nixpkgs.overlays = [ self.overlay ];
      };

      darwinConfigurations =
        self.lib.flakes.darwinConfigurations.importFromDirectory
          self.lib.hacknix.darwinSystem
          ./examples/nix-darwin
          {
            inherit (self) lib;
          };
    }

    // forAllSupportedSystems (system:
    let
      pkgs = pkgsFor system;
    in
    {
      packages = self.lib.flakes.filterPackagesByPlatform system
        {
          inherit (pkgs) aws-sam-cli;

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

          inherit (pkgs) colima;
          inherit (pkgs) cortextools;
          inherit (pkgs) emacsMacport;
          inherit (pkgs) emacsPgtkGcc;
          inherit (pkgs) ffmpeg-full;
          inherit (pkgs) fsatrace;
          inherit (pkgs) glances;
          inherit (pkgs) hostapd;
          inherit (pkgs) lean;
          inherit (pkgs) nix-index;
          inherit (pkgs) nmrpflash;
          inherit (pkgs) tarsnap;
          inherit (pkgs) trimpcap;
          inherit (pkgs) tsoff;
          inherit (pkgs) wpa_supplicant;

          inherit (pkgs) ffdhe2048Pem ffdhe3072Pem ffdhe4096Pem;

          inherit (pkgs) vault-plugin-secrets-github;
          inherit (pkgs) vault-plugins register-vault-plugins;

          inherit (pkgs) terraform-provider-postgresql terraform-provider-cloudflare terraform-provider-gandi terraform-provider-github terraform-provider-keycloak;

          # From sops-nix.
          inherit (pkgs) sops-init-gpg-key sops-import-keys-hook ssh-to-pgp;

          # These aren't actually derivations, and therefore, we
          # can't export them from packages. They are in the overlay, however.
          # inherit (pkgs) gitignoreSource gitignoreFilter;
          # inherit (pkgs) lib;
        }

      // (self.lib.optionalAttrs (system == "x86_64-linux") (
        let
          arion-example = {
            services.webserver = { pkgs, ... }: {
              image.nixBuild = true;
              nixos.useSystemd = true;
              nixos.configuration.imports = [
                self.nixosModule
              ];
              nixos.configuration.boot.tmpOnTmpfs = true;
              nixos.configuration.services.nginx.enable = true;
              nixos.configuration.services.nginx.virtualHosts.localhost.root = "${pkgs.nix.doc}/share/doc/nix/manual";

              service.useHostStore = false;
              service.ports = [
                "8000:80" # host:container
              ];
            };
          };
          arion-example-meta = pkgs.lib.hacknix.arion.mkMeta {
            modules = [ arion-example ];
          };
          arion-example-image = pkgs.lib.hacknix.arion.buildImage {
            name = "arion-example";
            meta = arion-example-meta;
          };
        in
        {
          # Only available for Linux, but not detected properly by `filterPackagesByPlatform`.
          inherit (pkgs) sops-install-secrets;

          # Linux kernels.
          inherit (pkgs) linux_ath10k;
          inherit (pkgs) linux_ath10k_ct;

          # Arion Docker image examples.
          inherit arion-example-image;

          # These aren't actually derivations, and therefore, we
          # can't export them from packages. They are in the overlay, however.
          # inherit (pkgs) linuxPackages_ath10k;
          # inherit (pkgs) linuxPackages_ath10k_ct;
        }
      ));
    })

    // {
      hydraJobs =
        {
          inherit (self) packages;
        }

        // forAllLinuxSystems (system: {
          nixosConfigurations =
            self.lib.flakes.nixosConfigurations.build
              self.nixosConfigurations;

          amazonImages =
            let
              extraModules = [
                {
                  ec2.hvm = true;
                  amazonImage.format = "qcow2";
                  amazonImage.sizeMB = 4096;
                }
              ];
              mkSystem = self.lib.hacknix.amazonImage extraModules;
              configs =
                self.lib.flakes.nixosConfigurations.importFromDirectory
                  mkSystem
                  ./examples/nixos
                  {
                    inherit (self) lib;
                  };
            in
            self.lib.flakes.nixosConfigurations.buildAmazonImages configs;

          isoImages =
            let
              extraModules = [
                ({ config, ... }:
                  {
                    isoImage.isoBaseName = self.lib.mkForce "${config.networking.hostName}_hacknix-example-iso";
                    networking.wireless.enable = self.lib.mkForce false;
                  })
              ];
              mkSystem = self.lib.hacknix.isoImage extraModules;
              configs =
                self.lib.flakes.nixosConfigurations.importFromDirectory
                  mkSystem
                  ./examples/nixos
                  {
                    inherit (self) lib;
                  };
            in
            self.lib.flakes.nixosConfigurations.buildISOImages configs;
        })

        // forAllMacSystems (system: {
          darwinConfigurations = self.lib.flakes.darwinConfigurations.build self.darwinConfigurations;
        })

        // forAllTestSystems (system: {
          tests =
            let
              pkgs = pkgsFor system;
            in
            (self.lib.testing.nixos.importFromDirectory ./tests/fixtures
              {
                inherit system pkgs;
                extraConfigurations = [ self.nixosModule ];
              }
              { })
            // (with import (nixpkgs + "/pkgs/top-level/release-lib.nix")
              {
                supportedSystems = [ system ];
                scrubJobs = true;
                nixpkgsArgs = {
                  config = {
                    allowUnfree = false;
                    allowBroken = true;
                    inHydra = true;
                  };
                  overlays = [
                    self.overlay
                    (import ./lib-tests)
                  ];
                };
              };
            mapTestOn {
              dlnAttrSets = all;
              dlnIPAddr = all;
              dlnMisc = all;
              dlnFfdhe = all;
              dlnTypes = all;
            });
        });

      ciJobs = self.lib.flakes.recurseIntoHydraJobs self.hydraJobs;
    };
}
