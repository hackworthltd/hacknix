# Lifted from nixpkgs's NixOS module of the same name, but works fine
# on macOS.
#
# License follows:
#
# Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors
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

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.git;
in

{
  options = {
    programs.git = {
      enable = mkEnableOption (lib.mdDoc "git");

      package = mkOption {
        type = types.package;
        default = pkgs.git;
        defaultText = literalExpression "pkgs.git";
        example = literalExpression "pkgs.gitFull";
        description = lib.mdDoc "The git package to use";
      };

      config = mkOption {
        type =
          with types;
          let
            gitini = attrsOf (attrsOf anything);
          in
          either gitini (listOf gitini)
          // {
            merge =
              loc: defs:
              let
                config =
                  foldl'
                    (
                      acc:
                      { value, ... }@x:
                      acc
                      // (
                        if isList value then
                          {
                            ordered = acc.ordered ++ value;
                          }
                        else
                          {
                            unordered = acc.unordered ++ [ x ];
                          }
                      )
                    )
                    {
                      ordered = [ ];
                      unordered = [ ];
                    }
                    defs;
              in
              [ (gitini.merge loc config.unordered) ] ++ config.ordered;
          };
        default = [ ];
        example = {
          init.defaultBranch = "main";
          url."https://github.com/".insteadOf = [
            "gh:"
            "github:"
          ];
        };
        description = lib.mdDoc ''
          Configuration to write to /etc/gitconfig. A list can also be
          specified to keep the configuration in order. For example, setting
          `config` to `[ { foo.x = 42; } { bar.y = 42; }]` will put the `foo`
          section before the `bar` section unlike the default alphabetical
          order, which can be helpful for sections such as `include` and
          `includeIf`. See the CONFIGURATION FILE section of git-config(1) for
          more information.
        '';
      };

      lfs = {
        enable = mkEnableOption (lib.mdDoc "git-lfs");

        package = mkOption {
          type = types.package;
          default = pkgs.git-lfs;
          defaultText = literalExpression "pkgs.git-lfs";
          description = lib.mdDoc "The git-lfs package to use";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];
      environment.etc.gitconfig = mkIf (cfg.config != [ ]) {
        text = concatMapStringsSep "\n" generators.toGitINI cfg.config;
      };
    })
    (mkIf (cfg.enable && cfg.lfs.enable) {
      environment.systemPackages = [ cfg.lfs.package ];
      programs.git.config = {
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
    })
  ];

  meta.maintainers = with maintainers; [ dhess ];
}
