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

    # Enable the sandbox, but in order to work around issues with
    # packages requiring too many paths, we add `/nix/store` by
    # default. This is less than optimal, but much safer than
    # disabling the sandbox entirely, and probably safer than
    # disabling the sandbox on a per-package, as-needed basis, as
    # well.
    #
    # Ref:
    # https://github.com/NixOS/nix/issues/4119#issuecomment-2561973914
    nix.settings.sandbox = true;
    nix.settings.extra-sandbox-paths = [ "/nix/store" ];

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
