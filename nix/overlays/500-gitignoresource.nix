final: prev:
let
  gitignoreSrc =
    (import final.lib.hacknix.flake.inputs.gitignore-nix)
      {
        inherit (final) lib;
      };
in
{
  inherit (gitignoreSrc) gitignoreSource gitignoreFilter;
}
