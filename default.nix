let

  lib = import ./lib;
  defaultPkgs = lib.nixpkgs { config = { allowBroken = true; allowUnfree = true; }; };

in

{ pkgs ? defaultPkgs }:

let

  overlays = self: super:
    lib.customisation.composeOverlays lib.overlays super;
  self = lib.customisation.composeOverlays (lib.singleton overlays) pkgs;

in
{
  inherit (self) aws-okta;
  inherit (self) aws-vault;

  inherit (self) badhosts-unified;
  inherit (self) badhosts-fakenews badhosts-gambling badhosts-nsfw badhosts-social;
  inherit (self) badhosts-fakenews-gambling badhosts-fakenews-nsfw badhosts-fakenews-social;
  inherit (self) badhosts-gambling-nsfw badhosts-gambling-social;
  inherit (self) badhosts-nsfw-social;
  inherit (self) badhosts-fakenews-gambling-nsfw badhosts-fakenews-gambling-social;
  inherit (self) badhosts-fakenews-nsfw-social;
  inherit (self) badhosts-gambling-nsfw-social;
  inherit (self) badhosts-fakenews-gambling-nsfw-social;
  inherit (self) badhosts-all;

  inherit (self) cabal-fmt;
  inherit (self) cachix;
  inherit (self) ccextractor;
  inherit (self) cfssl;
  inherit (self) chamber;
  inherit (self) darcs;
  inherit (self) delete-tweets;
  inherit (self) ffmpeg-full;
  inherit (self) fsatrace;
  inherit (self) gawk_4_2_1;
  inherit (self) gitignoreSource gitignoreFilter;
  inherit (self) hydra-unstable;
  inherit (self) libprelude;
  inherit (self) libvmaf;
  inherit (self) lorri;
  inherit (self) macnix-rebuild;
  inherit (self) mkCacert;
  inherit (self) neovim;
  inherit (self) nixops;
  inherit (self) nmrpflash;
  inherit (self) ntp;
  inherit (self) oauth2_proxy;
  inherit (self) radare2;
  inherit (self) saml2aws;
  inherit (self) terraform-provider-okta;
  inherit (self) trimpcap;
  inherit (self) tsoff;
  inherit (self) wpa_supplicant;
  inherit (self) yubikey-manager;

  inherit (self) hashedCertDir;

  inherit (self) emacsMelpaPackagesNg;
  inherit (self) emacs-nox emacsNoXMelpaPackagesNg;
  inherit (self) emacsMacportMelpaPackagesNg;
  inherit (self) emacs-env emacs-nox-env emacs-macport-env;

  inherit (self) haskellPackages;

  inherit (self) hyperkit;
  inherit (self) minikube;

  inherit (self) python-env;

  inherit (self) darwin;

  # Various buildEnv's that we use, usually only on macOS (though many
  # of them should work on any pltform).
  inherit (self) anki-env;
  inherit (self) mactools-env;
  inherit (self) maths-env;
  inherit (self) minikube-env;
  inherit (self) nixops-env;
  inherit (self) nixtools-env;
  inherit (self) opsec-env;
  inherit (self) shell-env;

  inherit (self) hacknix-source;

  inherit (self) lib;

  inherit (self) examples;

  overlays.all = overlays;
}
