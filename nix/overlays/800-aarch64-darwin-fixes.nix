final: prev:
let
  # Note: creating a function for this if-then-else pattern causes
  # infinite recursion, so we have to write it by hand each time.

  emacsMacport = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.emacsMacport else prev.emacsMacport;
  ffmpeg-full = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.ffmpeg-full else prev.ffmpeg-full;
  glances = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.glances else prev.glances;
  lean = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.lean else prev.lean;
  nix-index = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.nix-index else prev.nix-index;
  tarsnap = if final.stdenv.hostPlatform.system == "aarch64-darwin" then final.lib.hacknix.pkgs_x86.tarsnap else prev.tarsnap;
in
{
  inherit emacsMacport;
  inherit ffmpeg-full;
  inherit glances;
  inherit lean;
  inherit nix-index;
  inherit tarsnap;
}
