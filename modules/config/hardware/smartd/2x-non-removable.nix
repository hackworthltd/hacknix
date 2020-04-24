{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.hacknix.hardware.smartd-2x-non-removable;
  enabled = cfg.enable;
  commonConfig = import ./common.nix { inherit config lib pkgs; };

in {
  options.hacknix.hardware.smartd-2x-non-removable = {
    enable = mkEnableOption ''
      <literal>smartd</literal> for 2 non-removable drives.

      <literal>smartd</literal> will be configured as follows:

      <variablelist>

       <varlistentry>
         <listitem>
           <para>
             Monitor two drives named <literal>/dev/sda</literal> and
             <literal>/dev/sdb</literal>.
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
             If a drive is missing or disappears, it is assumed to
             have failed.
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
            "-a -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/02|L/../../1/02)";
        }
        {
          device = "/dev/sdb";
          options =
            "-a -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/03|L/../../2/03)";
        }
      ];
    };
  } // commonConfig);
}
