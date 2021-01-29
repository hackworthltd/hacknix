final: prev:
let
  structuredExtraConfig = with final.stdenv.lib.kernel; {
    EXPERT = yes;
    EVENT_TRACING = yes;
    DEBUG_FS = yes;

    MAC80211_DEBUGFS = yes;
    MAC80211_LEDS = yes;
    MAC80211_RC_MINSTREL = yes;
    MAC80211_RC_DEFAULT_MINSTREL = yes;

    NL80211_TESTMODE = yes;

    CFG80211_DEBUGFS = yes;
    CFG80211_WEXT = yes;
    CFG80211_CERTIFICATION_ONUS = yes;
    CFG80211_REG_RELAX_NO_IR = yes;
    CFG80211_DEFAULT_PS = no;
    CFG80211_REQUIRE_SIGNED_REGDB = no;

    # ath-specific.
    ATH_DEBUG = yes;
    ATH_REG_DYNAMIC_USER_REG_HINTS = yes;
    ATH_REG_DYNAMIC_USER_CERT_TESTING = yes;
    ATH_TRACEPOINTS = yes;

    # ath10k-specific.
    ATH10K_DEBUG = yes;
    ATH10K_DFS_CERTIFIED = yes;
    ATH10K_SPECTRAL = yes;
    ATH10K_DEBUGFS = yes;
    ATH10K_TRACING = yes;
  };

  ath10kPackagesFor = kernel: final.linuxPackagesFor (
    kernel.override {
      inherit structuredExtraConfig;
    }
  );

  # iwlwifi is broken on this kernel.
  ath10kPackagesFor_ct = kernel: final.linuxPackagesFor (
    kernel.override {
      structuredExtraConfig = structuredExtraConfig // (with final.stdenv.lib.kernel; {
        IWLWIFI = no;
      });
    }
  );

  # Don't recurseIntoAttrs here, as we don't want to build all these
  # out-of-tree modules for ath10k kernels.
  linuxPackages_ath10k = ath10kPackagesFor final.linux;
  linux_ath10k = linuxPackages_ath10k.kernel;


  linux_5_4_ct = final.callPackage ../pkgs/linux-5.4-ct {
    kernelPatches = [
      final.kernelPatches.bridge_stp_helper
      final.kernelPatches.request_key_helper
      final.kernelPatches.rtl8761b_support
    ];
  };

  # Don't recurseIntoAttrs here, as we don't want to build all these
  # out-of-tree modules for ath10k kernels.
  linuxPackages_ath10k_ct = ath10kPackagesFor_ct linux_5_4_ct;
  linux_ath10k_ct = linuxPackages_ath10k_ct.kernel;
in
{
  inherit linux_ath10k linuxPackages_ath10k;
  inherit linux_ath10k_ct linuxPackages_ath10k_ct;
}
