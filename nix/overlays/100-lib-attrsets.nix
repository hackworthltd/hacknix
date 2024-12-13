## Things that I do all the time with attrsets, but aren't included in
## Nix or nixpkgs, for whatever reason.

final: prev:
let
  ## Tests on attrsets.

  /*
    Given an attrset, return true if `pred` is true for each value in
    the set, else false. Here `pred` is a predicate function of one
    argument (the value of each attribute in the set).

    Example:
      s1 = { a = { valid = true; }; b = { valid = true; }; }
      allAttrs (v: v.valid) s1
      => true
      s2 = { a = { valid = true; }; b = { valid = false; }; }
      allAttrs (v: v.valid) s2
      => false
      z = {};
      allAttrs (v: v.valid) z
      => true
  */

  allAttrs = pred: attrs: final.lib.all pred (final.lib.mapAttrsToList (_: value: value) attrs);

  /*
    Given an attrset, return true if `pred` is true for any value in
    the set, else false. Here `pred` is a predicate function of one
    argument (the value of each attribute in the set).

    Example:
      s1 = { a = { valid = true; }; b = { valid = false; }; }
      anyAttrs (v: v.valid) s1
      => true
      s2 = { a = { valid = false; }; b = { valid = false; }; }
      anyAttrs (v: v.valid) s2
      => false
      z = {};
      anyAttrs (v: v.valid) z
      => false
  */

  anyAttrs = pred: attrs: final.lib.any pred (final.lib.mapAttrsToList (_: value: value) attrs);

  /*
    Given an attrset, return true if `pred` is true for no value in
    the set, else false. Here `pred` is a predicate function of one
    argument (the value of each attribute in the set).

    Note: this is the same as !anyAttrs.

    Example:
      s1 = { a = { valid = true; }; b = { valid = false; }; }
      noAttrs (v: v.valid) s1
      => false
      s2 = { a = { valid = false; }; b = { valid = false; }; }
      noAttrs (v: v.valid) s2
      => true
      z = {};
      noAttrs (v: v.valid) z
      => true
  */

  noAttrs = pred: attrs: !(anyAttrs pred attrs);

  ## Mapping over attrsets.

  /*
    Apply a function to the value of each key/value pair in an
    attribute set (discarding the key), returning a list of the
    transformed values.

    Note that `mapValuesToList f s` is equivalent to
    `mapAttrsToList (_: v: f v) s`.
  */

  mapValuesToList = f: attrs: final.lib.mapAttrsToList (_: v: f v) attrs;
in
{
  lib = (prev.lib or { }) // {
    attrsets = (prev.lib.attrsets or { }) // {
      inherit
        allAttrs
        anyAttrs
        noAttrs
        mapValuesToList
        ;
    };
  };
}
