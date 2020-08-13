{ localLib ? import nix/default.nix { }
}:

localLib.pkgs.mkShell {
  buildInputs = with localLib.pkgs; [
    niv
  ];
}
