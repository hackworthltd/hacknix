{ lib
, runCommand
, openssl
, perl
}:

let

  # Derived from symlinkJoin in trivial-builders.nix.
  hashedCertDir =
    args_@{ name
         , certFiles
         , preferLocalBuild ? true
         , allowSubstitutes ? false
         , postBuild ? ""
         , ...
         }:
    let
      args = removeAttrs args_ [ "name" "postBuild" ]
        // { inherit preferLocalBuild allowSubstitutes; }; # pass the defaults
    in runCommand name args
      ''
        mkdir -p $out
        for i in $certFiles; do
          ln -s $i $out
        done
        PATH=$PATH:${openssl}/bin ${perl}/bin/perl -- ${openssl}/bin/c_rehash $out
        ${postBuild}
      '';

in  
hashedCertDir
