# Common config for all smartd setups.
#
# Note that this configures smartd to send notification emails to
# root. This assumes you've set up some kind of mailer on the system.

{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    smartmontools
  ];

  services.smartd = {
    enable = true;
    notifications.mail.enable = true;
    notifications.mail.recipient = "root";
    notifications.wall.enable = false;
  };
}
