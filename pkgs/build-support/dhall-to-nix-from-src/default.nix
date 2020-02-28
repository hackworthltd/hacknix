{ stdenv
, dhall-nix
}:

let

  dhallToNixFromSrc = src: dhallFile:
    let
      drv = stdenv.mkDerivation {
        name = "dhall-to-nix-from-src";
        inherit src;

        buildCommand = ''
          dhall-to-nix <<< $src/${dhallFile} > $out
        '';

        buildInputs = [ dhall-nix ];
      };

    in
      import "${drv}";
in
  dhallToNixFromSrc
