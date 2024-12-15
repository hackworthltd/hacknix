final: prev:
let
  talosctl = final.callPackage ../pkgs/talosctl { };
in
{
  inherit talosctl;
}
