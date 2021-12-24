let
  ciJobs = (import ./flake-compat.nix).defaultNix.ciJobs;
in
{
  inherit (ciJobs.packages.x86_64-linux) tarsnap;
}
