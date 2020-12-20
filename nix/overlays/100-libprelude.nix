final: prev:
let
  gawk_4_2_1 = prev.callPackage ../pkgs/gawk/4.2.1.nix { };
  libprelude =
    prev.callPackage ../pkgs/libprelude { gawk = gawk_4_2_1; };

in
{
  inherit libprelude;
}
