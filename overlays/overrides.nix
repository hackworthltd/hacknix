self: super:

let

  inherit (super) callPackage;

  # Upstream cfssl is out of date.
  cfssl = callPackage ../pkgs/cfssl {
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  # More recent version than upstream.
  minikube = callPackage ../pkgs/minikube {
    source = super.lib.hacknix.sources.minikube;
    inherit (super.darwin) libobjc;
    inherit (super.darwin.apple_sdk.frameworks) Foundation Security vmnet xpc;
    inherit (super) hyperkit;
  };

  # Upstream disables macOS.
  libvmaf = callPackage ../pkgs/libvmaf {};

  # Upstream is out of date.
  aws-okta = callPackage ../pkgs/aws-okta {
    source = super.lib.hacknix.sources.aws-okta;
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  # Upstream is broken on macOS.
  aws-vault = callPackage ../pkgs/aws-vault {
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  # Upstream is out of date.
  oauth2_proxy = callPackage ../pkgs/oauth2_proxy {
    inherit (super.darwin.apple_sdk.frameworks) Security;
  };

  # Upstream doesn't support macOS, probably due to
  # https://github.com/radareorg/radare2/issues/15197
  radare2 = super.radare2.overrideAttrs (drv: {
    python3 = super.python3;
    useX11 = false;
    pythonBindings = true;
    luaBindings = true;

    # XXX dhess - this is a bit of a hack.
    HOST_CC = if super.stdenv.cc.isClang then "clang" else "gcc";

    meta = drv.meta // {
      platforms = super.lib.platforms.unix;
    };
  });

  # Upstream prevents fsatrace from building on macOS. It should work,
  # more or less, as long as you're using it with binaries built from
  # Nixpkgs and not pulling in Apple frameworks.
  fsatrace = super.fsatrace.overrideAttrs (drv: {
    meta = drv.meta // {
      platforms = super.lib.platforms.unix;
    };
  });

  # Upstream is out of date.
  saml2aws = callPackage ../pkgs/saml2aws {
    source = super.lib.hacknix.sources.saml2aws;
    inherit (super.darwin) libobjc;
    inherit (super.darwin.apple_sdk.frameworks) Foundation IOKit;
  };

  # We need YubiKey OpenPGP KDF functionality, which hasn't been
  # released yet.
  yubikey-manager = super.yubikey-manager.overrideAttrs (drv: {
    version = "3.1.1";
    name = "yubikey-manager-3.1.1";
    srcs = super.fetchFromGitHub {
      owner = "Yubico";
      repo = "yubikey-manager";
      rev = "2bbab3072ea0ec7cdcbaba398ce8dc0105aa27c2";
      sha256 = "1i4qfmmwiw3pfbhzyivw6qp3zc17qv38sgxvza1lb2hl577za9y1";
    };
  });

in
{
  # Enable TLS v1.2 in wpa_supplicant.
  wpa_supplicant = super.wpa_supplicant.overrideAttrs (drv: {
    extraConfig = drv.extraConfig + ''
     CONFIG_TLSV12=y
    '';
  });

  # Use fdk_aac in ffmpeg-full.
  #
  # Don't override super; it disables a bunch of things on macOS.
  ffmpeg-full = callPackage (super.path + "/pkgs/development/libraries/ffmpeg-full") {
    nonfreeLicensing = true;
    fdkaacExtlib = true;
    fdk_aac = super.fdk_aac;
    inherit libvmaf;
    nvenc = false;
    inherit (super.darwin.apple_sdk.frameworks)
      Cocoa CoreServices CoreAudio AVFoundation MediaToolbox
      VideoDecodeAcceleration;

    frei0r = if super.stdenv.isDarwin then null else super.frei0r;
  };

  inherit aws-okta;
  inherit aws-vault;
  inherit cfssl;
  inherit fsatrace;
  inherit libvmaf;
  inherit minikube;
  inherit oauth2_proxy;
  inherit radare2;
  inherit saml2aws;
  inherit yubikey-manager;
}
