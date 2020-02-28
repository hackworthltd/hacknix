{ config, pkgs, lib, ... }:

let

  siteDefault = ''
    server default {

      listen {
        type = auth
        ipaddr = *
        port = 0
        limit {
              max_connections = 16
              lifetime = 0
              idle_timeout = 30
        }
      }

      listen {
        ipaddr = *
        port = 0
        type = acct
        limit {
        }
      }

      listen {
        type = auth
        ipv6addr = ::
        port = 0
        limit {
              max_connections = 16
              lifetime = 0
              idle_timeout = 30
        }
      }

      listen {
        ipv6addr = ::
        port = 0
        type = acct
        limit {
        }
      }

      authorize {
        preprocess

        rewrite_calling_station_id
        authorized_macs

        if (!ok) {
          reject
        }

        # If not 802.1x, accept, otherwise, check EAP.
        # XXX dhess - change me! Should not accept just MACs.

        if (!EAP-Message) {
          update control {
            Auth-Type := Accept
          }
        }
        else {
          eap {
            ok = return
            updated = return
          }
        }
      }

      authenticate {
        eap
      }

      preacct {
        preprocess
        acct_unique
        suffix
        files
      }

      accounting {
        detail
        unix
        radutmp
        sradutmp
        exec
        attr_filter.accounting_response
      }

      session {
        radutmp
      }

      post-auth {
        update {
          &reply: += &session-state:
        }
        exec
        remove_reply_message_if_eap
        Post-Auth-Type REJECT {
          attr_filter.access_reject
          eap
          remove_reply_message_if_eap
        }

        Post-Auth-Type Challenge {
        }
      }

      pre-proxy {
      }

      post-proxy {
        eap
      }
    }
  '';
in
  pkgs.writeText "default" siteDefault
