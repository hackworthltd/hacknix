final: prev:
let
  gawk_4_2_1 = final.callPackage ../pkgs/gawk/4.2.1.nix { };
  libprelude =
    final.callPackage ../pkgs/libprelude { gawk = gawk_4_2_1; };

in
{
  inherit libprelude;
}
