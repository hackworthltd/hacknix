final: prev:
let

  # https://github.com/NixOS/nixpkgs/pull/138186
  # https://github.com/nix-community/nix-direnv/issues/113
  nixUnstable = prev.nixUnstable.override {
    patches = [ ../patches/nix/unset-is-macho.patch ];
  };

in
{
  inherit nixUnstable;
}
