{ system ? builtins.currentSystem
, crossSystem ? null
, config ? {
    allowBroken = true;
    allowUnfree = true;
  }
, sourcesOverride ? { }
, localLib ? (
    import nix/default.nix {
      inherit system crossSystem config sourcesOverride;
    }
  )
, pkgs ? localLib.pkgs
}:
{
  inherit (pkgs) aws-sso-credential-process;
  inherit (pkgs) aws-export-credentials;

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

  inherit (pkgs) cachix;
  inherit (pkgs) chamber;
  inherit (pkgs) delete-tweets;
  inherit (pkgs) ffmpeg-full;
  inherit (pkgs) fsatrace;
  inherit (pkgs) gawk_4_2_1;
  inherit (pkgs) gitignoreSource gitignoreFilter;
  inherit (pkgs) hostapd;
  inherit (pkgs) hydra-unstable;
  inherit (pkgs) libprelude;
  inherit (pkgs) linux_ath10k linuxPackages_ath10k;
  inherit (pkgs) linux_ath10k_ct linuxPackages_ath10k_ct;
  inherit (pkgs) lorri;
  inherit (pkgs) macnix-rebuild;
  inherit (pkgs) mkCacert;
  inherit (pkgs) neovim;
  inherit (pkgs) nixops;
  inherit (pkgs) nmrpflash;
  inherit (pkgs) radare2;
  inherit (pkgs) traefik-forward-auth;
  inherit (pkgs) trimpcap;
  inherit (pkgs) tsoff;
  inherit (pkgs) wpa_supplicant;
  inherit (pkgs) yubikey-manager;

  inherit (pkgs) hashedCertDir;

  inherit (pkgs) haskellPackages;

  inherit (pkgs) darwin;

  # Various buildEnv's that we use, usually only on macOS (though many
  # of them should work on any pltform).
  inherit (pkgs) anki-env;
  inherit (pkgs) mactools-env;
  inherit (pkgs) maths-env;
  inherit (pkgs) minikube-env;
  inherit (pkgs) nixtools-env;
  inherit (pkgs) opsec-env;
  inherit (pkgs) shell-env;

  inherit (pkgs) hacknix-source;

  inherit (pkgs) lib;

  inherit (pkgs) macos-remote-builder macos-build-host;

  inherit (pkgs) nixops-network-deployments;

  overlays.all = localLib.overlays;
}
