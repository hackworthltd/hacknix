# When we override a NixOS module, we want to detect upstream changes,
# in case the changes obviate our reason(s) for overriding the module
# in the first place. This module allows us to specify the hash of the
# specific version of the upstream module upon which our override is
# based.
#
# This code is adapted from:
#
# https://github.com/nixcloud/nixcloud-webservices/blob/f13a7b471db986e8ffb21d6a566ef28f5d35935c/modules/core/hashed-modules.nix
#
# Thank you to the Nixcloud team for publishing it!
#
# The license for the original code reads as follows:
#
# Copyright (c) 2017 Joachim Schiele, Paul Seitz and the Nixcloud contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

{ config, lib, modulesPath, ... }:

let
  inherit (lib) types mkOption;
  cfg = config.hacknix.assertions;

  mkAssertion = path: expectedHash:
    let
      contents = builtins.readFile "${toString modulesPath}/${toString path}";
      hash = builtins.hashString "sha256" contents;
    in {
      assertion = hash == expectedHash;
      message = "Hash mismatch for `${path}': "
        + "Expected `${expectedHash}' but got `${hash}'.";
    };

  hashType = lib.mkOptionType {
    name = "sha256";
    description = "base-16 SHA-256 hash";
    check = val:
      lib.isString val && builtins.match "[a-fA-F0-9]{64}" val != null;
    merge = lib.mergeOneOption;
  };

in {
  options.hacknix.assertions.moduleHashes = mkOption {
    type = types.attrsOf hashType;
    default = { };
    example."services/mail/opendkim.nix" =
      "a937be8731e6e1a7b7872a2dc72274b4a31364f249bfcf8ef7bcc98753c9a018";
    description = ''
      An attribute set consisting of module paths relative to the NixOS module
      directory as attribute names and their corresponding SHA-256 hashes as
      attribute values.
    '';
  };

  config.assertions = lib.mapAttrsToList mkAssertion cfg.moduleHashes;
}
