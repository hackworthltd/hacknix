final: prev:
let
  # Note: we use an older version than upstream because
  # python-watchdog is broken upstream. See
  # https://github.com/NixOS/nixpkgs/issues/113777
  aws-sam-cli = final.callPackage ../pkgs/aws-sam-cli { };

in
{
  inherit aws-sam-cli;
}
