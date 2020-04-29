self: super:
let
  myPass = super.pass.withExtensions
    (ext: [ ext.pass-audit ext.pass-genphrase ext.pass-update ]);

  anki-env = super.buildEnv {
    name = "anki-env";
    paths = with super;
      [
        # Disabled for now, see:
        # https://github.com/NixOS/nixpkgs/issues/76715
        #anki
        (texlive.combine { inherit (texlive) scheme-medium; })
      ];
  };

  mactools-env = super.buildEnv {
    name = "mactools-env";
    paths = with super; [
      ccextractor
      delete-tweets
      ffmpeg-full
      mediainfo
      myPass
      pinentry_mac
      qrencode
      radare2
      # Disabled until fixed upstream.
      # wireguard-tools
      youtube-dl
      yubico-piv-tool
      yubikey-manager
      yubikey-personalization
    ];
    meta.platforms = super.lib.platforms.darwin;
  };

  maths-env = super.buildEnv {
    name = "maths-env";
    paths = with super; [ coq lean prooftree ];
    meta.platforms = super.lib.platforms.all;
  };

  minikube-env = super.buildEnv {
    name = "minikube-env";
    paths = with super; [ kubectl linuxkit minikube ];
    meta.platforms = super.lib.platforms.all;
  };

  nixtools-env = super.buildEnv {
    name = "nixtools-env";
    paths = with super; [
      cabal2nix
      cachix
      direnv
      hydra-cli
      lorri
      niv
      nixfmt
      nixpkgs-fmt
      nix-index
      nix-info
      nox
    ];
    meta.platforms = super.lib.platforms.all;
  };

  opsec-env = super.buildEnv {
    name = "opsec-env";
    paths = with super;
      [
        #nmap
      ];
    meta.platforms = super.lib.platforms.all;
  };

  shell-env = super.buildEnv {
    name = "shell-env";
    paths = with super; [
      coreutils
      gitAndTools.git-crypt
      gitAndTools.git-extras
      gitAndTools.git-secrets
      gnumake
      gnupg
      gnused
      htop
      keybase
      pwgen
      ripgrep
      speedtest-cli
      unrar
      wget
      xz
    ];
    meta.platforms = super.lib.platforms.all;
  };
in
{
  inherit anki-env;
  inherit mactools-env;
  inherit maths-env;
  inherit minikube-env;
  inherit nixtools-env;
  inherit opsec-env;
  inherit shell-env;
}
