self: super:
let
  inherit (super) callPackage;

  # Upstream doesn't support macOS, probably due to
  # https://github.com/radareorg/radare2/issues/15197
  radare2 = super.radare2.overrideAttrs (
    drv: {
      python3 = super.python3;
      useX11 = false;
      pythonBindings = true;
      luaBindings = true;

      # XXX dhess - this is a bit of a hack.
      HOST_CC = if super.stdenv.cc.isClang then "clang" else "gcc";

      meta = drv.meta // { platforms = super.lib.platforms.unix; };
    }
  );

  # Upstream prevents fsatrace from building on macOS. It should work,
  # more or less, as long as you're using it with binaries built from
  # Nixpkgs and not pulling in Apple frameworks.
  fsatrace = super.fsatrace.overrideAttrs (drv: { meta = drv.meta // { platforms = super.lib.platforms.unix; }; });

  # Enable TLS v1.2 in wpa_supplicant.
  wpa_supplicant = super.wpa_supplicant.overrideAttrs (
    drv: {
      extraConfig = drv.extraConfig + ''
        CONFIG_TLSV12=y
      '';
    }
  );
  hostapd = super.hostapd.overrideAttrs (
    drv: {
      extraConfig = drv.extraConfig + ''
        CONFIG_DRIVER_NL80211_QCA=y
        CONFIG_SAE=y
        CONFIG_SUITEB192=y
        CONFIG_IEEE80211AX=y
        CONFIG_DEBUG_LINUX_TRACING=y
        CONFIG_FST=y
        CONFIG_FST_TEST=y
        CONFIG_MBO=y
        CONFIG_TAXONOMY=y
        CONFIG_FILS=y
        CONFIG_FILS_SK_PFS=y
        CONFIG_WPA_CLI_EDIT=y
        CONFIG_OWE=y
        CONFIG_AIRTIME_POLICY=y
        CONFIG_NO_TKIP=y
      '';
    }
  );

  hydra-unstable = (import super.lib.hacknix.sources.hydra).defaultPackage.x86_64-linux;

  niv = (import super.lib.hacknix.sources.niv { pkgs = super; }).niv;

  # Use the pinned spago2nix and make it buildable on multiple targets.
  spago2nix = (import super.lib.hacknix.sources.spago2nix { pkgs = super; }).overrideAttrs (
    drv: {
      meta = (drv.meta or { }) // { platforms = super.lib.platforms.all; };
    }
  );

  emacsGcc = super.emacsGcc.overrideAttrs (drv: {
    # Courtesy:
    # https://github.com/twlz0ne/nix-gccemacs-darwin/blob/aaacc6dd84dc3e585b4ad653dd3bbbe2cc7e070c/emacs.nix#L52
    postInstall = drv.postInstall or "" + super.lib.optionalString super.stdenv.isDarwin ''
      ln -snf $out/lib/emacs/28.0.50/native-lisp $out/native-lisp
      ln -snf $out/lib/emacs/28.0.50/native-lisp $out/Applications/Emacs.app/Contents/native-lisp
      cat <<EOF> $out/bin/run-emacs.sh
      #!/usr/bin/env bash
      set -e
      exec $out/bin/emacs-28.0.50 "\$@"
      EOF
      chmod a+x $out/bin/run-emacs.sh
      ln -snf ./run-emacs.sh $out/bin/emacs
    '';
  });

  # The patch previously needed for macOS is now applied upstream.
  ykPython3 = super.python3.override {
    packageOverrides = self: super: {
      pyscard = super.pyscard.overrideAttrs (oldAttrs: rec {
        patches = [ ];
      });
    };
  };

  yubikey-manager = callPackage (super.path + "/pkgs/tools/misc/yubikey-manager") {
    inherit (super) fetchurl lib yubikey-personalization libu2f-host libusb1;
    python3Packages = ykPython3.pkgs;
  };

  # Upstream keeps breaking this and it's usually not up-to-date, either.
  awscli2 = callPackage ../pkgs/awscli2 { };

  # Use fdk_aac in ffmpeg-full.
  #
  # Don't override super; it disables a bunch of things on macOS.
  ffmpeg-full =
    callPackage (super.path + "/pkgs/development/libraries/ffmpeg-full") {
      nonfreeLicensing = true;
      fdkaacExtlib = true;
      fdk_aac = super.fdk_aac;
      libvmaf = super.libvmaf;
      nvenc = false;
      inherit (super.darwin.apple_sdk.frameworks)
        Cocoa CoreServices CoreAudio AVFoundation MediaToolbox
        VideoDecodeAcceleration
        ;

      frei0r = if super.stdenv.isDarwin then null else super.frei0r;

      # Disable for now, samba isn't building on macOS.
      samba = false;
    };

in
{
  inherit awscli2;
  inherit emacsGcc;
  inherit ffmpeg-full;
  inherit fsatrace;
  inherit hostapd;
  inherit hydra-unstable;
  inherit niv;
  inherit radare2;
  inherit spago2nix;
  inherit wpa_supplicant;
  inherit yubikey-manager;
}
