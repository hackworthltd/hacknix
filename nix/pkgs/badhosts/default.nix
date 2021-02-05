{ stdenv
, lib
, src
}:
let
  version = src.shortRev;
  generic = { subname, hostsFile, ... }:
    stdenv.mkDerivation {
      name = "badhosts-${subname}-${version}";
      inherit version;
      inherit src;

      # Note that when we generate the Unbound zones file, we skip
      # everything in the source hosts file up to the "# Start
      # StevenBlack" line. This ensures that we won't accidentally
      # create "nxdomain" zones for any addresses that the source hosts
      # file defines (e.g., 0.0.0.0).
      installPhase = ''
        mkdir -p $out
        cp ${hostsFile} $out/hosts
        awk '/^# Start StevenBlack/,0' ${hostsFile} | awk '$1 == "0.0.0.0" {print "local-zone: \""$2"\" always_nxdomain"}' > $out/unbound.conf
      '';

      meta = with lib; {
        description = "Steven Black's bad hosts (${subname})";
        maintainers = maintainers.dhess;
        license = licenses.mit;
        platforms = lib.platforms.all;
      };
    };
  alternate = subname:
    generic {
      inherit subname;
      hostsFile = "alternates/${subname}/hosts";
    };
  badhosts-unified = generic {
    subname = "unified";
    hostsFile = "hosts";
  };
  badhosts-fakenews = alternate "fakenews";
  badhosts-gambling = alternate "gambling";
  badhosts-nsfw = alternate "porn";
  badhosts-social = alternate "social";
  badhosts-fakenews-gambling = alternate "fakenews-gambling";
  badhosts-fakenews-nsfw = alternate "fakenews-porn";
  badhosts-fakenews-social = alternate "fakenews-social";
  badhosts-gambling-nsfw = alternate "gambling-porn";
  badhosts-gambling-social = alternate "gambling-social";
  badhosts-nsfw-social = alternate "porn-social";
  badhosts-fakenews-gambling-nsfw = alternate "fakenews-gambling-porn";
  badhosts-fakenews-gambling-social = alternate "fakenews-gambling-social";
  badhosts-fakenews-nsfw-social = alternate "fakenews-porn-social";
  badhosts-gambling-nsfw-social = alternate "gambling-porn-social";
  badhosts-fakenews-gambling-nsfw-social =
    alternate "fakenews-gambling-porn-social";
  badhosts-all = badhosts-fakenews-gambling-nsfw-social;
in
{
  inherit badhosts-unified;
  inherit badhosts-fakenews badhosts-gambling badhosts-nsfw badhosts-social;
  inherit badhosts-fakenews-gambling badhosts-fakenews-nsfw
    badhosts-fakenews-social
    ;
  inherit badhosts-gambling-nsfw badhosts-gambling-social;
  inherit badhosts-nsfw-social;
  inherit badhosts-fakenews-gambling-nsfw badhosts-fakenews-gambling-social;
  inherit badhosts-fakenews-nsfw-social;
  inherit badhosts-gambling-nsfw-social;
  inherit badhosts-fakenews-gambling-nsfw-social;
  inherit badhosts-all;
}
