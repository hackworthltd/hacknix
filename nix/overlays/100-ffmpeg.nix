final: prev:
let
  # We tune ffmpeg-full for our own purposes.
  ffmpeg-full =
    prev.callPackage (prev.path + "/pkgs/development/libraries/ffmpeg-full") {
      # Broken on macOS.
      libmodplug = null;

      nonfreeLicensing = true;
      fdkaacExtlib = true;
      fdk_aac = prev.fdk_aac;
      libvmaf = prev.libvmaf;
      nvenc = false;
      x265 = prev.x265;
      xavs = prev.xavs;
      inherit (prev.darwin.apple_sdk.frameworks)
        Cocoa CoreServices CoreAudio AVFoundation MediaToolbox
        VideoDecodeAcceleration
        ;

      frei0r = if prev.stdenv.isDarwin then null else prev.frei0r;

      # Broken on macOS.
      samba = false;

      # Broken.
      rav1e = null;
      vid-stab = null;
    };

in
{
  inherit ffmpeg-full;
}
