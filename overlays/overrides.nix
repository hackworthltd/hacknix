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

  # We need YubiKey OpenPGP KDF functionality, which hasn't been
  # released yet.
  yubikey-manager = super.yubikey-manager.overrideAttrs (
    drv: {
      version = "3.1.1";
      name = "yubikey-manager-3.1.1";
      srcs = super.fetchFromGitHub {
        owner = "Yubico";
        repo = "yubikey-manager";
        rev = "12efa59f94e18bfd86b8d662a2bd70a5d2dc4fe0";
        sha256 = "1anj1gav3mc2hzzbm80vfnb2k4s0jvlbf0kvisbj8fi4pqs18db3";
      };
    }
  );

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
in
{
  # Use fdk_aac in ffmpeg-full.
  #
  # Don't override super; it disables a bunch of things on macOS.
  xoffmpeg-full =
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

  inherit fsatrace;
  inherit hostapd;
  inherit hydra-unstable;
  inherit radare2;
  inherit wpa_supplicant;
  inherit yubikey-manager;
}
