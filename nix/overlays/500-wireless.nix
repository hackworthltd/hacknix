final: prev:
let
  # Enable TLS v1.2 in wpa_supplicant.
  wpa_supplicant = prev.wpa_supplicant.overrideAttrs (
    drv: {
      extraConfig = drv.extraConfig + ''
        CONFIG_TLSV12=y
      '';
    }
  );
  hostapd = prev.hostapd.overrideAttrs (
    drv: {
      extraConfig = drv.extraConfig + ''
        CONFIG_DRIVER_NL80211_QCA=y
        CONFIG_SAE=y
        CONFIG_SUITEB192=y
        CONFIG_IEEE80211AX=y
        CONFIG_DEBUG_LINUX_TRACING=y
        CONFIG_FST=y
        CONFIG_FST_TEST=y
        CONFIG_MBO=y
        CONFIG_TAXONOMY=y
        CONFIG_FILS=y
        CONFIG_FILS_SK_PFS=y
        CONFIG_WPA_CLI_EDIT=y
        CONFIG_OWE=y
        CONFIG_AIRTIME_POLICY=y
        CONFIG_NO_TKIP=y
      '';
    }
  );

in
{
  inherit hostapd;
  inherit wpa_supplicant;
}
