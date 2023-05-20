final: prev:
let
  ci-scripts = final.callPackage ../pkgs/ci-scripts { };
in
{
  inherit (ci-scripts) cachix-archive-flake-inputs;
  inherit (ci-scripts) cachix-push-attr;
  inherit (ci-scripts) cachix-push-flake-dev-shell;
}
