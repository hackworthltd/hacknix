{ config, pkgs, lib, ... }:
let
  localLib = import ../../../nix { };
  cfg = config.hacknix-nix-darwin.defaults;
in
{
  options.hacknix-nix-darwin.defaults = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        the hacknix default system configuration for macOS.

        Note that the default configuration is enabled by default. By
        importing these modules, you're enabling these defaults unless
        you explicitly set this option to <literal>false</literal>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowBroken = true;

    nix.trustedUsers = [ "@admin" ];

    # See https://gist.github.com/LnL7/1cfca66d17eba1f9936175926bf39de8.
    #
    # XXX dhess - disabled, see:
    # https://github.com/NixOS/nix/issues/2311
    # nix.useSandbox = true;
    # nix.sandboxPaths = [
    #   "/System/Library/Frameworks"
    #   "/System/Library/PrivateFrameworks"
    #   "/usr/lib"
    #   "/private/tmp"
    #   "/private/var/tmp"
    #   "/usr/bin/env"
    # ];

    nix.extraOptions = ''
      pre-build-hook =
    '';

    # We always run nix-daemon (multi-user mode).
    services.nix-daemon.enable = true;
    services.activate-system.enable = true;
    users.nix.configureBuildUsers = true;
    users.nix.nrBuildUsers = 32;

    # Configure bash to work with Nix. bash isn't really supported by
    # Apple anymore, so we don't go out of our way here to do anything
    # fancy like we do for zsh.
    programs.bash.enable = true;
    programs.bash.enableCompletion = false;

    # Configure zsh to work with Nix. Note that the Apple-supplied
    # versions (which we rename *.apple, see below) often contain
    # important settings, so we hook them from the versions that
    # nix-darwin creates. This means that some of the things that
    # nix-darwin sets up may be overridden by the Apple version of the
    # configuration script (e.g., the zsh history settings).
    # Generally, though, this should be safe, as it's unlikely that
    # Apple would interfere with any Nix-specific settings.
    programs.zsh = {
      enable = true;
      enableCompletion = true;

      shellInit = ''
        # Hook the Apple version of this config file.
        if test -h /etc/zshenv.apple; then
          source /etc/zshenv.apple
        fi
      '';

      loginShellInit = ''
        # Hook the Apple version of this config file.
        if test -h /etc/zprofile.apple; then
          source /etc/zprofile.apple
        fi
      '';

      interactiveShellInit = ''
        # Hook the Apple version of this config file.
        if test -h /etc/zshrc.apple; then
          source /etc/zshrc.apple
        fi
      '';
    };

    programs.nix-index.enable = true;

    # Move the Apple-supplied /etc/z* files out of the way. Note that
    # this often needs to be done after a macOS upgrade, so we
    # overwrite old versions, if they exist.
    system.activationScripts.preActivation.text = ''
      printf "Preserving Apple /etc zsh files that will be replaced... "
      for f in $(find /etc/static/z* -type l); do
        l=/etc/''${f#/etc/static/}
        [[ ! -L "$l" ]] && echo "moving $l to $l.apple" && mv $l $l.apple
      done
      echo "ok"

      printf "Preserving Apple /etc/bash* files that will be replaced... "
      for f in $(find /etc/static/bash* -type l); do
        l=/etc/''${f#/etc/static/}
        [[ ! -L "$l" ]] && echo "moving $l to $l.apple" && mv $l $l.apple
      done
      echo "ok"
    '';

    system.activationScripts.postActivation.text = ''
      printf "Disabling Spotlight on /nix... "
      mdutil -i off /nix &> /dev/null
      mdutil -d /nix &> /dev/null
      mdutil -E /nix &> /dev/null
      touch /nix/.metadata_never_index
      echo "ok"
    '';

    # Make sure our `darwin-rebuild` convenience wrapper is in the
    # system path.
    environment.systemPackages = [ pkgs.macnix-rebuild ];

    # Always use our fixed package sets and ignore channels. We want a
    # pure NIX_PATH by default.
    #
    # XXX dhess - this assumes `environment.darwinConfig` is set by
    # the top-level config. Fix this.
    nix.nixPath = [
      "darwin-config=${config.environment.darwinConfig}"
      "darwin=${localLib.fixedNixDarwin}"
      "nixpkgs=${localLib.fixedNixpkgs}"
    ];

    # Increase maxfiles and maxproc. (Note: I don't know of a way to
    # do this just per-user, so it must be done system-wide, it
    # seems.)
    launchd.daemons.limit-maxfiles = {
      command = "launchctl limit maxfiles 262144 262144";
      serviceConfig.Label = "limit.maxfiles";
      serviceConfig.RunAtLoad = true;
    };
    launchd.daemons.limit-maxproc = {
      command = "launchctl limit maxproc 2048 2048";
      serviceConfig.Label = "limit.maxproc";
      serviceConfig.RunAtLoad = true;
    };

    # Well-known remote hosts.
    programs.ssh.knownHosts = pkgs.lib.ssh.wellKnownHosts;
  };
}
