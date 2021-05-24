final: prev:
let
  # We tune ffmpeg-full for our own purposes.
  ffmpeg-full =
    final.callPackage (final.path + "/pkgs/development/libraries/ffmpeg-full") {
      # Broken on macOS.
      libmodplug = null;

      nonfreeLicensing = true;
      fdkaacExtlib = true;
      fdk_aac = final.fdk_aac;
      libvmaf = final.libvmaf;
      nvenc = false;
      x265 = final.x265;
      xavs = final.xavs;
      inherit (final.darwin.apple_sdk.frameworks)
        Cocoa CoreServices CoreAudio AVFoundation MediaToolbox
        VideoDecodeAcceleration
        ;

      frei0r = if final.stdenv.isDarwin then null else final.frei0r;

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
