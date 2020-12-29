final: prev:
let
  anki-env = final.buildEnv {
    name = "anki-env";
    paths = with final;
      [
        # Disabled for now, see:
        # https://github.com/NixOS/nixpkgs/issues/76715
        #anki
        (texlive.combine { inherit (texlive) scheme-medium; })
      ];
  };

  myPass = final.pass.withExtensions (ext: [ ext.pass-genphrase ext.pass-update ]);
  mactools-env = final.buildEnv {
    name = "mactools-env";
    paths = with final; [
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
    meta.platforms = final.lib.platforms.darwin;
  };

  maths-env = final.buildEnv {
    name = "maths-env";
    paths = with final; [
      coq
      lean
      prooftree
    ];
    meta.platforms = final.lib.platforms.all;
  };

  nixtools-env = final.buildEnv {
    name = "nixtools-env";
    paths = with final; [
      cachix
      direnv
      niv
      nixpkgs-fmt
      nix-index
      nix-info
      nox
    ];
    meta.platforms = final.lib.platforms.all;
  };

  shell-env = final.buildEnv {
    name = "shell-env";
    paths = with final; [
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
    meta.platforms = final.lib.platforms.all;
  };

in
{
  inherit anki-env;
  inherit mactools-env;
  inherit maths-env;
  inherit nixtools-env;
  inherit shell-env;
}
