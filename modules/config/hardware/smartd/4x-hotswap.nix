{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.smartd-4x-hotswap;
  enabled = cfg.enable;
  commonConfig = import ./common.nix { inherit config lib pkgs; };

in {
  options.hacknix.hardware.smartd-4x-hotswap = {
    enable = mkEnableOption ''
      <literal>smartd</literal> for a system with 4 hot-swap
      bays, e.g., for a typical Supermicro 1U rackmount server.

      <literal>smartd</literal> will be configured as follows:

      <variablelist>

       <varlistentry>
         <listitem>
           <para>
             Monitor up to 4 drives named <literal>/dev/sd[a-d]</literal>.
           </para>
         </listitem>
       </varlistentry>

       <varlistentry>
         <listitem>
           <para>
             Send problem notifications via email to
             <literal>root</literal>. If you want to send the notices
             to a different email address, use
             <literal>mkForce</literal> to override the
             <option>services.smartd.notifications.mail.recipient</option>
             option.
           </para>
         </listitem>
       </varlistentry>

       <varlistentry>
         <listitem>
           <para>
             Mark all drives as removable.
           </para>
         </listitem>
       </varlistentry>

       <varlistentry>
         <listitem>
           <para>
             Disable drive auto-detection.
           </para>
         </listitem>
       </varlistentry>

       <varlistentry>
         <listitem>
           <para>
             Set up a non-overlapping self-test schedule for each drive.
           </para>
         </listitem>
       </varlistentry>

       <varlistentry>
         <listitem>
           <para>
             Prevent the non-removable drives from spinning up in
             sleep/standby mode, unless 7 days have passed without a
             daily check.
           </para>
         </listitem>
       </varlistentry>

      <variablelist>
    '';
  };

  config = mkIf enabled ({
    services.smartd = {
      autodetect = false;
      devices = [
        {
          device = "/dev/sda";
          options =
            "-a -d removable -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/02|L/../../1/02)";
        }
        {
          device = "/dev/sdb";
          options =
            "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/03|L/../../2/03)";
        }
        {
          device = "/dev/sdc";
          options =
            "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|4|5|6|7)/04|L/../../3/04)";
        }
        {
          device = "/dev/sdd";
          options =
            "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|5|6|7)/05|L/../../4/05)";
        }
      ];
    };
  } // commonConfig);
}
