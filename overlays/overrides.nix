self: super:
let
  inherit (super) callPackage;

  # Upstream is out of date.
  aws-sam-cli = callPackage ../pkgs/aws-sam-cli { };

  # Upstream cfssl is out of date.
  cfssl = callPackage ../pkgs/cfssl {
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  # Upstream disables macOS.
  libvmaf = callPackage ../pkgs/libvmaf { };

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

  # We need YubiKey OpenPGP KDF functionality, which hasn't been
  # released yet.
  yubikey-manager = super.yubikey-manager.overrideAttrs (
    drv: {
      version = "3.1.1";
      name = "yubikey-manager-3.1.1";
      srcs = super.fetchFromGitHub {
        owner = "Yubico";
        repo = "yubikey-manager";
        rev = "2bbab3072ea0ec7cdcbaba398ce8dc0105aa27c2";
        sha256 = "1i4qfmmwiw3pfbhzyivw6qp3zc17qv38sgxvza1lb2hl577za9y1";
      };
    }
  );

  # Upstream is out of date.
  unison-ucm = super.callPackage ../pkgs/unison { };

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

  # Hydra is broken upstream because nixpkgs hasn't kept Hydra's
  # required version of nix in sync. This one does.
  hydraNix = (callPackage ../pkgs/nix {
    boehmgc = super.boehmgc.override { enableLargeConfig = true; };
  }
  );

  hydra-unstable = callPackage (super.path + "/pkgs/development/tools/misc/hydra/common.nix") {
    version = "2020-06-23";
    src = super.fetchFromGitHub {
      owner = "NixOS";
      repo = "hydra";
      rev = "bb32aafa4a9b027c799e29b1bcf68727e3fc5f5b";
      sha256 = "0kl9h70akwxpik3xf4dbbh7cyqn06023kshfvi14mygdlb84djgx";
    };
    nix = hydraNix.nixFlakes;

    tests = {
      db-migration = super.nixosTests.hydra-db-migration.mig;
      basic = super.nixosTests.hydra.hydra-unstable;
    };
  };

in
{
  # Use fdk_aac in ffmpeg-full.
  #
  # Don't override super; it disables a bunch of things on macOS.
  ffmpeg-full =
    callPackage (super.path + "/pkgs/development/libraries/ffmpeg-full") {
      nonfreeLicensing = true;
      fdkaacExtlib = true;
      fdk_aac = super.fdk_aac;
      inherit libvmaf;
      nvenc = false;
      inherit (super.darwin.apple_sdk.frameworks)
        Cocoa CoreServices CoreAudio AVFoundation MediaToolbox
        VideoDecodeAcceleration
        ;

      frei0r = if super.stdenv.isDarwin then null else super.frei0r;
    };

  inherit aws-sam-cli;
  inherit cfssl;
  inherit fsatrace;
  inherit hostapd;
  inherit hydra-unstable;
  inherit libvmaf;
  inherit radare2;
  inherit unison-ucm;
  inherit wpa_supplicant;
  inherit yubikey-manager;
}
