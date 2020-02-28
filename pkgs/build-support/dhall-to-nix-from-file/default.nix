{ dhallToNix }:

let

  dhallToNixFromFile = fileName:
  let
    source = builtins.readFile fileName;
  in
    dhallToNix source;

in dhallToNixFromFile
