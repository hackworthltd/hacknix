# A service for running a high-performance instance(s) of netsniff-ng.
#
# This service assumes you've set up some kind of SPAN port(s) on your
# switch, or added a TAP device(s), to mirror/capture packets and have
# them sent to the interface(s) on which netsniff-ng listens.
#
# Currently this service only supports packet capture to disk, but it
# could fairly easily be extended to support other forms of output,
# e.g., packet redirection via a different interface.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.netsniff-ng;

  defaultUser = "netsniff-ng";
  defaultGroup = "netsniff-ng";


  outputDir = conf: "${toString conf.outputBaseDirectory}/${conf.name}";
  outputDirPerms = "u+rwx,g+rx,o-rwx";

  instancesList = mapAttrsToList (_: config: config) cfg.instances;

  perInstanceAssertions = c: [
    {
      assertion = c.inputInterface != "";
      message = "services.netsniff-ng.instances.${c.name}.inputInterface cannot be the empty string.";
    }
    {
      assertion = c.outputBaseDirectory != "";
      message = "services.netsniff-ng.instances.${c.name}.outputBaseDirectory cannot be the empty string.";
    }
  ];

  preCmd = conf:
  let
    dir = outputDir conf;
  in ''
    if [[ ! -d "${dir}" ]]; then
      mkdir -p "${dir}"
    fi
    chown ${cfg.user}:${cfg.group} "${dir}"
    chmod ${outputDirPerms} "${dir}"
  '';

  netsniffNgCmd = conf:
  let
    dir = outputDir conf;
  in ''
    USERID=`id -u ${cfg.user}`
    GROUPID=`id -g ${cfg.group}`
    ${pkgs.netsniff-ng}/bin/netsniff-ng --in ${conf.inputInterface} --out "${dir}"       \
      ${optionalString (conf.bindToCPU != null) "--bind-cpu ${toString conf.bindToCPU}"} \
      ${optionalString (conf.interval != "") "--interval ${conf.interval}"}              \
      ${optionalString (conf.packetType != null) "--type ${conf.packetType}"}            \
      ${optionalString (conf.pcapMagic != "") "--magic ${conf.pcapMagic}"}               \
      ${optionalString (conf.pcapPrefix != "") "--prefix ${conf.pcapPrefix}"}            \
      ${optionalString (conf.ringSize != "") "--ring-size ${conf.ringSize}"}             \
      --user $USERID --group $GROUPID                                                    \
      --silent --verbose ${conf.extraOptions}
  '';

  # Note: delete expired files first, and then trim from highest
  # 'afterDays' to lowest to guarantee we only process each file at
  # most once. Note that we use trimpcap's '--extension' option to
  # move pcap files out of the way while we're trimming -- again, so
  # that files are only trimmed once.

  trimScript = conf:
  let
    dir = outputDir conf;

    deleteCmd = ''
      echo "Deleting files older than ${toString conf.trim.deleteAfterDays} days"
      find "${dir}" -type f -name "${conf.pcapPrefix}*.pcap" -mtime +${toString conf.trim.deleteAfterDays} -exec rm {} \;
    '';

    trimExtension = params: ".${toString params.afterDays}days";

    trimCmd = params: ''
      echo "Trimming files older than ${toString params.afterDays} days"
      find "${dir}" -type f -name "${conf.pcapPrefix}*.pcap" -mtime +${toString params.afterDays} -execdir ${pkgs.trimpcap}/bin/trimpcap --flowsize ${toString params.size} --delete --extension "${trimExtension params}" --preserve-file-times {} +
    '';

    postTrimCmd = params: ''
      echo "Replacing trimmed files older than ${toString params.afterDays} days"
      find "${dir}" -type f -name "${conf.pcapPrefix}*.pcap${trimExtension params}" -execdir /bin/sh -c 'mv {} $(${pkgs.coreutils}/bin/basename {} ${trimExtension params})' \;
    '';

    trimSchedule =
      concatStrings (map (s: trimCmd s)
                         (sort (a: b: a.afterDays > b.afterDays) conf.trim.schedule));

    postTrimSchedule =
      concatStrings (map (s: postTrimCmd s) 
                         (sort (a: b: a.afterDays > b.afterDays) conf.trim.schedule));

  in ''
    ${optionalString (conf.trim.deleteAfterDays != null) deleteCmd}
    ${trimSchedule}
    ${postTrimSchedule}
  '';

in
{
  options = {
    services.netsniff-ng = {

      user = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = defaultUser;
        description = ''
          All <literal>netsniff-ng</literal> services will run as this
          user after the initial setup.

          If you do not override the default value, an unprivileged
          user will be created for this purpose.
        '';
      };

      group = mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = defaultGroup;
        description = ''
          All <literal>netsniff-ng</literal> services will run as this
          group after the initial setup.

          If you do not override the default value, an unprivileged
          group will be created for this purpose.
        '';
      };

      instances = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: (import ./netsniff-ng-options.nix {
          inherit name config lib pkgs outputDirPerms;
        })));
        default = {};
        example = literalExample ''
          full-cap = {
            inputInterface = "eno1";
            interval = "1MiB";
            bindToCPU = 0;
            serviceRequires = [ "pcap-prep-eno1.service" ];
          };
        '';
        description = ''
          Zero or more <literal>netsniff-ng</literal> instances for
          packet capture.

          Note that there are many fiddly <command>netsniff-ng</command>
          options, many of which have profound performance implications.
          Only some of the <command>netsniff-ng</command> options have
          corresponding configuration options, and those that do only
          provide a brief explanation of their significance. See
          <citerefentry><refentrytitle>netsniff-ng</refentrytitle><manvolnum>8</manvolnum></citerefentry>
          for the full documentation of these options and their
          performance implications. To get high performance with
          relative few dropped packets, you will likely need to do quite
          a bit of hardware-specific performance tuning.

          <command>netsniff-ng</command> options that do not have a
          corresponding configuration option can be passed as a raw
          string to the <literal>netsniff-ng</literal> service instance
          via the <option>extraOptions</option> option.

          Note that <literal>netsniff-ng</literal> instances will not
          configure the network interface on which they capture
          packets. You will probably also want to configure a
          <option>services.pcap-prep</option> service for each network
          interface on which a <literal>netsniff-ng</literal> instance
          runs, and add the name of that service to the corresponding
          <literal>netsniff-ng</literal>'s
          <option>serviceRequires</option> list. Without this
          additional service, it is likely that you will lose packets,
          because network interfaces are typically not set up for
          high-speed packet catpure by default.
          (<literal>netsniff-ng</literal> instances cannot do this
          themselves because there may be multiple packet capture
          services running on the same interface, and each service's
          needs must be considered when configuring the interface.)
        '';
      };
    };

  };

  config = mkIf (cfg.instances != {}) {

    assertions =
      (flatten (map perInstanceAssertions instancesList)) ++
      [
        { assertion = cfg.group != "";
          message = "services.netsniff-ng.group cannot be the empty string."; }
        { assertion = cfg.user != "";
          message = "serivces.netsniff-ng.user cannot be the empty string."; }
      ];

    users.users = optionalAttrs (cfg.user == defaultUser) {
      "${cfg.user}" = {
        name = defaultUser;
        description = "Packet capture user";
        group = cfg.group;
      };
    };

    users.groups = optionalAttrs (cfg.group == defaultGroup) {
      "${cfg.group}" = {
        name = defaultGroup;
      };
    };

    systemd.services = listToAttrs (filter (x: x.value != null) (
      (mapAttrsToList
        (_: conf: nameValuePair "netsniff-ng@${conf.name}" ({

          description = "Packet capture (${conf.name})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" "local-fs.target" ] ++ conf.serviceRequires;
          requires = conf.serviceRequires;
          preStart = preCmd conf;
          script = netsniffNgCmd conf;

        })) cfg.instances) ++
      (mapAttrsToList
        (_: conf: nameValuePair "netsniff-ng@${conf.name}-trim" ({

          description = "Trim netsniff-ng@${conf.name} pcap files";
          after = [ "multi-user.target" "netsniff-ng@${conf.name}.service" ];
          requires = [ "netsniff-ng@${conf.name}.service" ];
          script = trimScript conf;
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            Type = "oneshot";
          };

        })) cfg.instances)
    ));

    systemd.timers = listToAttrs (filter (x: x.value != null)
      (mapAttrsToList
        (_: conf: nameValuePair "netsniff-ng@${conf.name}-trim" ({

          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = conf.trim.period;
            Persistent = "yes";
          };

        })) cfg.instances));

    environment.systemPackages = [ pkgs.netsniff-ng ];

  };
}
