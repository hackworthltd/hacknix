final: prev:
let
  # Bump for CVE-2021-3156 fix until nixpkgs-unstable merges it.
  sudo = prev.sudo.overrideAttrs (drv: rec {
    pname = drv.pname;
    version = "1.9.5p2";
    src = final.fetchurl {
      url = "https://www.sudo.ws/dist/${pname}-${version}.tar.gz";
      sha256 = "0y093z4f3822rc88g9asdch12nljdamp817vjxk04mca7ks2x7jk";
    };


  });
in
{
  inherit sudo;
}
