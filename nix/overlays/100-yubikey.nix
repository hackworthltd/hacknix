final: prev:
let
  # We want OpenPGP KDF, and that breaks yubikey-manager 3.1.1, the
  # current release version. We override it with the latest GitHub
  # version.
  yubikey-manager = final.callPackage ../pkgs/yubikey-manager {
    inherit (final) fetchFromGitHub lib yubikey-personalization libu2f-host libusb1 python3Packages;
  };

in
{
  inherit yubikey-manager;
}
