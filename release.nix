{ projectSrc ? {
    outPath = ./.;
    rev = "abcdef";
  }
, config ? {
    allowUnfree = true;
    allowBroken = true;
    inHydra = true;
  }
, supportedSystems ? [ "x86_64-darwin" "x86_64-linux" ]
, scrubJobs ? true
, sourcesOverride ? { }
}:
let
  localLib = import nix/default.nix { inherit sourcesOverride; };
in
with import (localLib.fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs;
  packageSet = import projectSrc;
  nixpkgsArgs = {
    inherit config;

    # Do not pass overlays here; if you do, release-lib.nix will try
    # to pass them to our project's default.nix, which doesn't take an
    # argument for that.
  };
};
let
  nixos-tests = (
    import ./release-nixos.nix {
      inherit scrubJobs;
      supportedSystems = [ "x86_64-linux" ];
    }
  );
  x86_64 = [ "x86_64-linux" "x86_64-darwin" ];
  x86_64_linux = [ "x86_64-linux" ];
  linux = [ "x86_64-linux" ];
  jobs = (
    mapTestOn (
      rec {
        awscli_2_0 = all;
        aws-sso-credential-process = all;
        aws-export-credentials = all;
        aws-vault = all;

        badhosts-unified = all;
        badhosts-fakenews = all;
        badhosts-gambling = all;
        badhosts-nsfw = all;
        badhosts-social = all;
        badhosts-fakenews-gambling = all;
        badhosts-fakenews-nsfw = all;
        badhosts-fakenews-social = all;
        badhosts-gambling-nsfw = all;
        badhosts-gambling-social = all;
        badhosts-nsfw-social = all;
        badhosts-fakenews-gambling-nsfw = all;
        badhosts-fakenews-gambling-social = all;
        badhosts-fakenews-nsfw-social = all;
        badhosts-gambling-nsfw-social = all;
        badhosts-fakenews-gambling-nsfw-social = all;
        badhosts-all = all;

        cachix = all;
        ccextractor = x86_64;
        cfssl = all;
        chamber = all;
        delete-tweets = all;
        ffmpeg-full = x86_64;
        fsatrace = all;
        gawk_4_2_1 = all;
        hostapd = linux;
        hydra-unstable = x86_64_linux;
        libprelude = x86_64_linux;
        libvmaf = x86_64;
        linux_ath10k = linux;
        linux_ath10k_ct = linux;
        lorri = all;
        macnix-rebuild = darwin;
        neovim = all;
        netsniff-ng = x86_64_linux;
        # NixOps doesn't evaluate on Hydra at the moment.
        #nixops = x86_64;
        nmrpflash = all;
        ntp = linux;
        radare2 = all;
        traefik-forward-auth = all;
        trimpcap = linux;
        tsoff = linux;
        unison-ucm = x86_64;
        wpa_supplicant = linux;
        yubikey-manager = all;

        emacs = darwin;
        emacs-env = darwin;
        emacs-nox = linux;
        emacs-nox-env = linux;
        emacs-macport-env = darwin;

        hyperkit = darwin;
        minikube = all;

        vscode = all;
        vscode-with-extensions = all;
        vscode-with-python = x86_64;

        anki-env = darwin;
        mactools-env = darwin;
        maths-env = x86_64;
        minikube-env = all;
        nixtools-env = all;
        opsec-env = all;
        shell-env = darwin;

        hacknix-source = all;

        examples.nix-darwin.build-host.system = darwin;
        examples.nix-darwin.remote-builder.system = darwin;
      }
    )
  ) // (
    rec {
      x86_64-linux = pkgs.releaseTools.aggregate {
        name = "hacknix-x86_64-linux";
        meta.description = "hacknix overlay packages (x86_64-linux)";
        meta.maintainer = lib.maintainers.dhess;
        constituents = with jobs; [
          awscli_2_0.x86_64-linux
          aws-sso-credential-process.x86_64-linux
          aws-export-credentials.x86_64-linux
          aws-vault.x86_64-linux

          badhosts-unified.x86_64-linux
          badhosts-fakenews.x86_64-linux
          badhosts-gambling.x86_64-linux
          badhosts-nsfw.x86_64-linux
          badhosts-social.x86_64-linux
          badhosts-fakenews-gambling.x86_64-linux
          badhosts-fakenews-nsfw.x86_64-linux
          badhosts-fakenews-social.x86_64-linux
          badhosts-gambling-nsfw.x86_64-linux
          badhosts-gambling-social.x86_64-linux
          badhosts-nsfw-social.x86_64-linux
          badhosts-fakenews-gambling-nsfw.x86_64-linux
          badhosts-fakenews-gambling-social.x86_64-linux
          badhosts-fakenews-nsfw-social.x86_64-linux
          badhosts-gambling-nsfw-social.x86_64-linux
          badhosts-fakenews-gambling-nsfw-social.x86_64-linux
          badhosts-all.x86_64-linux

          cachix.x86_64-linux
          ccextractor.x86_64-linux
          chamber.x86_64-linux
          cfssl.x86_64-linux
          hydra-unstable.x86_64-linux
          ffmpeg-full.x86_64-linux
          fsatrace.x86_64-linux
          gawk_4_2_1.x86_64-linux
          hostapd.x86_64-linux
          libprelude.x86_64-linux
          libvmaf.x86_64-linux
          linux_ath10k.x86_64-linux
          linux_ath10k_ct.x86_64-linux
          lorri.x86_64-linux
          neovim.x86_64-linux
          netsniff-ng.x86_64-linux
          #nixops.x86_64-linux
          ntp.x86_64-linux
          radare2.x86_64-linux
          traefik-forward-auth.x86_64-linux
          trimpcap.x86_64-linux
          tsoff.x86_64-linux
          unison-ucm.x86_64-linux
          wpa_supplicant.x86_64-linux
          yubikey-manager.x86_64-linux

          emacs-nox-env.x86_64-linux

          minikube.x86_64-linux

          maths-env.x86_64-linux
          minikube-env.x86_64-linux
          nixtools-env.x86_64-linux
          opsec-env.x86_64-linux

          hacknix-source.x86_64-linux
        ];
      };

      x86_64-darwin = pkgs.releaseTools.aggregate {
        name = "hacknix-x86_64-darwin";
        meta.description = "hacknix overlay packages (x86_64-darwin)";
        meta.maintainer = lib.maintainers.dhess;
        constituents = with jobs; [
          awscli_2_0.x86_64-darwin
          aws-sso-credential-process.x86_64-darwin
          aws-export-credentials.x86_64-darwin
          aws-vault.x86_64-darwin

          badhosts-unified.x86_64-darwin
          badhosts-fakenews.x86_64-darwin
          badhosts-gambling.x86_64-darwin
          badhosts-nsfw.x86_64-darwin
          badhosts-social.x86_64-darwin
          badhosts-fakenews-gambling.x86_64-darwin
          badhosts-fakenews-nsfw.x86_64-darwin
          badhosts-fakenews-social.x86_64-darwin
          badhosts-gambling-nsfw.x86_64-darwin
          badhosts-gambling-social.x86_64-darwin
          badhosts-nsfw-social.x86_64-darwin
          badhosts-fakenews-gambling-nsfw.x86_64-darwin
          badhosts-fakenews-gambling-social.x86_64-darwin
          badhosts-fakenews-nsfw-social.x86_64-darwin
          badhosts-gambling-nsfw-social.x86_64-darwin
          badhosts-fakenews-gambling-nsfw-social.x86_64-darwin
          badhosts-all.x86_64-darwin

          cachix.x86_64-darwin
          ccextractor.x86_64-darwin
          cfssl.x86_64-darwin
          chamber.x86_64-darwin
          ffmpeg-full.x86_64-darwin
          fsatrace.x86_64-darwin
          gawk_4_2_1.x86_64-darwin
          libvmaf.x86_64-darwin
          lorri.x86_64-darwin
          macnix-rebuild.x86_64-darwin
          neovim.x86_64-darwin
          #nixops.x86_64-darwin
          radare2.x86_64-darwin
          unison-ucm.x86_64-darwin
          yubikey-manager.x86_64-darwin

          emacs-env.x86_64-darwin
          emacs-macport-env.x86_64-darwin

          hyperkit.x86_64-darwin
          minikube.x86_64-darwin

          anki-env.x86_64-darwin
          mactools-env.x86_64-darwin
          maths-env.x86_64-darwin
          minikube-env.x86_64-darwin
          nixtools-env.x86_64-darwin
          opsec-env.x86_64-darwin
          shell-env.x86_64-darwin

          hacknix-source.x86_64-darwin
        ];
      };

      nix-darwin-configs = pkgs.releaseTools.aggregate {
        name = "nix-darwin-configs";
        meta.description = "Example nix-darwin configurations";
        meta.maintainer = lib.maintainers.dhess;
        constituents = with jobs; [
          examples.nix-darwin.build-host.system.x86_64-darwin
          examples.nix-darwin.remote-builder.system.x86_64-darwin
        ];
      };
    }
  );
in
jobs // nixos-tests
