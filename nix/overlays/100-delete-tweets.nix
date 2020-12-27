final: prev:
let
  delete-tweets = final.callPackage ../pkgs/delete-tweets { };
in
{
  inherit delete-tweets;
}
