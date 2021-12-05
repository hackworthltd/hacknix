final: prev:
let
  # Currently broken upstream on macOS.
  qemu = final.callPackage ../pkgs/qemu {
    inherit (final.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor;
    inherit (final.darwin.stubs) rez setfile;
    inherit (final.darwin) sigtool;
    python = final.python3;
  };

in
{
  inherit qemu;
}


