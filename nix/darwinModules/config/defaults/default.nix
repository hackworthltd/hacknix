{
  config,
  pkgs,
  lib,
  ...
}:
let
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
    hacknix-nix-darwin.defaults.nix.enable = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowBroken = true;

    nix.settings.trusted-users = [ "@admin" ];

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

    # We always run nix-daemon (multi-user mode).
    services.nix-daemon.enable = true;
    nix.configureBuildUsers = true;
    nix.nrBuildUsers = 32;

    # Configure bash to work with Nix. bash isn't really supported by
    # Apple anymore, so we don't go out of our way here to do anything
    # fancy like we do for zsh.
    programs.bash.enable = true;
    programs.bash.enableCompletion = false;

    # Configure zsh to work with Nix. Note that the Apple-supplied
    # versions often contain important settings, so we hook them from
    # the versions that nix-darwin creates. This means that some of
    # the things that nix-darwin sets up may be overridden by the
    # Apple version of the configuration script (e.g., the zsh history
    # settings). Generally, though, this should be safe, as it's
    # unlikely that Apple would interfere with any Nix-specific
    # settings.
    programs.zsh = {
      enable = true;
      enableCompletion = true;

      shellInit = ''
        if test -h /etc/zshenv.backup-before-nix; then
          source /etc/zshenv.backup-before-nix
        fi
      '';

      loginShellInit = ''
        if test -h /etc/zprofile.backup-before-nix; then
          source /etc/zprofile.backup-before-nix
        fi
      '';

      interactiveShellInit = ''
        if test -h /etc/zshrc.backup-before-nix; then
          source /etc/zshrc.backup-before-nix
        fi
      '';
    };

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
