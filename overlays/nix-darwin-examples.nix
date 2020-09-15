self: super:
let
  macos-build-host =
    super.lib.hacknix.mkNixDarwinSystem ../examples/nix-darwin/build-host.nix;
  macos-remote-builder = super.lib.hacknix.mkNixDarwinSystem
    ../examples/nix-darwin/remote-builder.nix;
in
{
  inherit macos-build-host macos-remote-builder;
}
