final: prev:
let

  badhosts = prev.callPackage ../pkgs/badhosts {
    src = prev.lib.hacknix.flake.inputs.badhosts;
  };

in
{
  inherit (badhosts) badhosts-unified;
  inherit (badhosts)
    badhosts-fakenews badhosts-gambling badhosts-nsfw badhosts-social
    ;
  inherit (badhosts)
    badhosts-fakenews-gambling badhosts-fakenews-nsfw badhosts-fakenews-social
    ;
  inherit (badhosts) badhosts-gambling-nsfw badhosts-gambling-social;
  inherit (badhosts) badhosts-nsfw-social;
  inherit (badhosts)
    badhosts-fakenews-gambling-nsfw badhosts-fakenews-gambling-social
    ;
  inherit (badhosts) badhosts-fakenews-nsfw-social;
  inherit (badhosts) badhosts-gambling-nsfw-social;
  inherit (badhosts) badhosts-fakenews-gambling-nsfw-social;
  inherit (badhosts) badhosts-all;
}
