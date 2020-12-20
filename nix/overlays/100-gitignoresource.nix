final: prev:
let
  gitignoreSrc =
    (import prev.lib.hacknix.flake.inputs.gitignore-nix)
      {
        inherit (prev) lib;
      };
in
{
  inherit (gitignoreSrc) gitignoreSource gitignoreFilter;
}
