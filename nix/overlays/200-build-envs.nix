final: prev:
let
  anki-env = prev.buildEnv {
    name = "anki-env";
    paths = with prev;
      [
        # Disabled for now, see:
        # https://github.com/NixOS/nixpkgs/issues/76715
        #anki
        (texlive.combine { inherit (texlive) scheme-medium; })
      ];
  };

  myPass = prev.pass.withExtensions (ext: [ ext.pass-genphrase ext.pass-update ]);
  mactools-env = prev.buildEnv {
    name = "mactools-env";
    paths = with prev; [
      ccextractor
      delete-tweets
      ffmpeg-full
      mediainfo
      myPass
      pinentry_mac
      qrencode
      youtube-dl
      yubico-piv-tool
      yubikey-manager
      yubikey-personalization
    ];
    meta.platforms = prev.lib.platforms.darwin;
  };

  maths-env = prev.buildEnv {
    name = "maths-env";
    paths = with prev; [
      coq
      lean
      prooftree
    ];
    meta.platforms = prev.lib.platforms.all;
  };

  nixtools-env = prev.buildEnv {
    name = "nixtools-env";
    paths = with prev; [
      cabal2nix
      cachix
      direnv
      hydra-cli
      lorri
      niv
      nixpkgs-fmt
      nix-index
      nix-info
      nox
    ];
    meta.platforms = prev.lib.platforms.all;
  };

  shell-env = prev.buildEnv {
    name = "shell-env";
    paths = with prev; [
      coreutils
      gitAndTools.git-crypt
      gitAndTools.git-extras
      gitAndTools.git-secrets
      git-lfs
      github-cli
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
    meta.platforms = prev.lib.platforms.all;
  };

in
{
  inherit anki-env;
  inherit mactools-env;
  inherit maths-env;
  inherit nixtools-env;
  inherit shell-env;
}
