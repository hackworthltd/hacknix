{ config, lib, pkgs, ... }:

let

  cfg           = config.hacknix.freeradius;

  prefix        = "${pkgs.freeradius}";
  exec_prefix   = prefix;
  sysconfdir    = "/etc";
  localstatedir = "/var";
  sbindir       = "${prefix}/sbin";
  logdir        = cfg.logDir;
  raddbdir      = cfg.configDir;
  radacctdir    = "${logdir}/radacct";

  name          = "radiusd";

  confdir    = "${raddbdir}";
  modconfdir = "${confdir}/mods-config";
  certdir    = "${confdir}/certs";
  cadir      = cfg.tls.caPath;
  run_dir    = "${localstatedir}/run/${name}";

  db_dir  = cfg.dataDir;

  libdir  = "${prefix}/lib";

  pidfile = "${run_dir}/${name}.pid";

  checkrad = "${sbindir}/checkrad";

  radiusdConf = pkgs.writeText "radiusd.conf" ''
    #
    # Based on:
    #
    # radiusd.conf	-- FreeRADIUS server configuration file - 3.0.17
    #	$Id: 59e59f3ac443e75663333a5b7732664b67c5567d $

    prefix = ${prefix}
    exec_prefix = ${exec_prefix}
    sysconfdir = ${sysconfdir}
    localstatedir = ${localstatedir}
    sbindir = ${sbindir}
    logdir = ${logdir}
    raddbdir = ${raddbdir}
    radacctdir = ${radacctdir}

    name = ${name}

    confdir = ${confdir}
    modconfdir = ${modconfdir}
    certdir = ${certdir}
    cadir   = ${cadir}
    run_dir = ${run_dir}

    db_dir = ${db_dir}

    libdir = ${libdir}

    pidfile = ${pidfile}

    correct_escapes = true

    max_request_time = 30

    cleanup_delay = 5

    max_requests = 16384

    hostname_lookups = no

    log {
      destination = syslog
      colourise = yes
      file = ${logdir}/radius.log
      syslog_facility = daemon
      stripped_names = no
      auth = yes
      auth_badpass = no
      auth_goodpass = no
      msg_denied = "You are already logged in - access denied"
    }

    checkrad = ${checkrad}

    security {
      allow_core_dumps = no
      max_attributes = 200
      reject_delay = 1
      status_server = yes
      allow_vulnerable_openssl = no
    }

    proxy_requests  = no


    # clients.conf
    $INCLUDE ${confdir}/clients.conf

    thread pool {
      start_servers = 5
      max_servers = 32
      min_spare_servers = 3
      max_spare_servers = 10
      max_requests_per_server = 0
      auto_limit_acct = no
    }

    modules {
      $INCLUDE ${confdir}/mods-enabled/
    }

    instantiate {
    }

    policy {
      $INCLUDE ${confdir}/policy.d/
    }

    $INCLUDE ${confdir}/sites-enabled/
  '';

in
radiusdConf
