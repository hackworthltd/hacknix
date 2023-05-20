{ stdenv
, lib
, writeShellApplication
, nixStable
, jq
, cachix
, gnugrep
}:

let
  # Archive Nix flake inputs to Cachix.
  cachix-archive-flake-inputs = writeShellApplication {
    name = "cachix-archive-flake-inputs";
    runtimeInputs = [
      cachix
      jq
      nixStable
    ];
    # Use `builtins.readFile` here so that we get a shellcheck.
    text = builtins.readFile ./cachix-archive-flake-inputs.sh;
  };

  # Push a Nix attribute's build and runtime dependencies to Cachix.
  #
  # Note: uses traditional `nix-build` rather than a flake due to
  # https://github.com/NixOS/nix/issues/7165
  cachix-push-attr = writeShellApplication {
    name = "cachix-push-attr";
    runtimeInputs = [
      cachix
      gnugrep
      nixStable
    ];
    # Use `builtins.readFile` here so that we get a shellcheck.
    text = builtins.readFile ./cachix-push-attr.sh;
  };

  # Push a Nix flake's dev shell to Cachix.
  cachix-push-flake-dev-shell = writeShellApplication {
    name = "cachix-push-flake-dev-shell";
    runtimeInputs = [
      cachix
      nixStable
    ];
    # Use `builtins.readFile` here so that we get a shellcheck.
    text = builtins.readFile ./cachix-push-flake-dev-shell.sh;
  };
in
{
  inherit cachix-archive-flake-inputs;
  inherit cachix-push-attr;
  inherit cachix-push-flake-dev-shell;
}

