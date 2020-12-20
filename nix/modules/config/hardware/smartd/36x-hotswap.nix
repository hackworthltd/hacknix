{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hacknix.hardware.smartd-36x-hotswap;
  enabled = cfg.enable;
  commonConfig = import ./common.nix { inherit config lib pkgs; };
in
{
  options.hacknix.hardware.smartd-36x-hotswap = {
    enable = mkEnableOption ''
      <literal>smartd</literal> for a system with up to 36
      hot-swap bays, e.g., for a Supermicro 847A-series 4U rackmount
      chassis.

      <literal>smartd</literal> will be configured as follows:

      <variablelist>

       <varlistentry>
         <listitem>
           <para>
             Monitor up to 36 removable drives (plus 2 internal
             drives) named <literal>/dev/sda</literal> through
             <literal>/dev/sda.
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

  config = mkIf enabled
    (
      {
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

            {
              device = "/dev/sde";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|6|7)/06|L/../../5/06)";
            }

            {
              device = "/dev/sdf";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|7)/07|L/../../6/07)";
            }

            {
              device = "/dev/sdg";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|6)/08|L/../../7/08)";
            }

            {
              device = "/dev/sdh";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/09|L/../../1/09)";
            }

            {
              device = "/dev/sdi";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/10|L/../../2/10)";
            }

            {
              device = "/dev/sdj";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|4|5|6|7)/11|L/../../3/11)";
            }

            {
              device = "/dev/sdk";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|5|6|7)/12|L/../../4/12)";
            }

            {
              device = "/dev/sdl";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|6|7)/13|L/../../5/13)";
            }

            {
              device = "/dev/sdm";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|7)/14|L/../../6/14)";
            }

            {
              device = "/dev/sdn";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|6)/15|L/../../7/15)";
            }

            {
              device = "/dev/sdo";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/16|L/../../1/16)";
            }

            {
              device = "/dev/sdp";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/17|L/../../2/17)";
            }

            {
              device = "/dev/sdq";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|4|5|6|7)/18|L/../../3/18)";
            }

            {
              device = "/dev/sdr";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|5|6|7)/19|L/../../4/19)";
            }

            {
              device = "/dev/sds";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|6|7)/20|L/../../5/20)";
            }

            {
              device = "/dev/sdt";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|7)/21|L/../../6/21)";
            }

            {
              device = "/dev/sdu";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|6)/22|L/../../7/22)";
            }

            {
              device = "/dev/sdv";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/23|L/../../1/23)";
            }

            {
              device = "/dev/sdw";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/00|L/../../2/00)";
            }

            {
              device = "/dev/sdx";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|4|5|6|7)/01|L/../../3/01)";
            }

            {
              device = "/dev/sdy";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|5|6|7)/02|L/../../4/02)";
            }

            {
              device = "/dev/sdz";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|6|7)/03|L/../../5/03)";
            }

            {
              device = "/dev/sdaa";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|7)/04|L/../../6/04)";
            }

            {
              device = "/dev/sdab";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|6)/05|L/../../7/05)";
            }

            {
              device = "/dev/sdac";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/06|L/../../1/06)";
            }

            {
              device = "/dev/sdad";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/07|L/../../2/07)";
            }

            {
              device = "/dev/sdae";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|4|5|6|7)/08|L/../../3/08)";
            }

            {
              device = "/dev/sdaf";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|5|6|7)/09|L/../../4/09)";
            }

            {
              device = "/dev/sdag";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|6|7)/10|L/../../5/10)";
            }

            {
              device = "/dev/sdah";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|7)/11|L/../../6/11)";
            }

            {
              device = "/dev/sdai";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|3|4|5|6)/12|L/../../7/12)";
            }

            {
              device = "/dev/sdaj";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(2|3|4|5|6|7)/13|L/../../1/13)";
            }

            {
              device = "/dev/sdak";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|3|4|5|6|7)/14|L/../../2/14)";
            }

            {
              device = "/dev/sdal";
              options =
                "-a -d removable -n standby,7 -o on -S on -s (S/../../(1|2|4|5|6|7)/15|L/../../3/15)";
            }

          ];
        };
      } // commonConfig
    );
}
