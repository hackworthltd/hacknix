let
  ciJobs = (import ./flake-compat.nix).defaultNix.ciJobs;
in
{
  amazonImages = ciJobs.amazonImages.x86_64-linux;
  isoImages = ciJobs.isoImages.x86_64-linux;
  nixosConfigurations = ciJobs.nixosConfigurations.x86_64-linux;
  packages = ciJobs.packages.x86_64-linux;
  tests = ciJobs.tests.x86_64-linux;
}
