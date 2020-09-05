{ system ? "x86_64-linux", pkgs, makeTestPython, ... }:
let
  # NOTE: these are dummy keys and certs, and they are obviously
  # insecure. Do not use them for any purpose!
  exampleCA1Pem = ''
    -----BEGIN CERTIFICATE-----
    MIIHezCCBWOgAwIBAgIJAMtk9IHs+5Q3MA0GCSqGSIb3DQEBCwUAMIGWMQswCQYD
    VQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTEWMBQGA1UEBwwNU2FuIEZyYW5j
    aXNjbzEUMBIGA1UECgwLRXhhbXBsZSBPcmcxLjAsBgNVBAsMJVRoZSBFeGFtcGxl
    IE9yZyBjZXJ0aWZpY2F0ZSBhdXRob3JpdHkxFDASBgNVBAMMC0V4YW1wbGUgT3Jn
    MCAXDTE5MDIyMjEyMDUyMVoYDzIxMTkwMjIzMTIwNTIxWjCBljELMAkGA1UEBhMC
    VVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcMDVNhbiBGcmFuY2lzY28x
    FDASBgNVBAoMC0V4YW1wbGUgT3JnMS4wLAYDVQQLDCVUaGUgRXhhbXBsZSBPcmcg
    Y2VydGlmaWNhdGUgYXV0aG9yaXR5MRQwEgYDVQQDDAtFeGFtcGxlIE9yZzCCAiIw
    DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK8sLklS5YKQRuhTEelDXY0hMRiT
    yfv4PlxaMOdjnyI64cV8Sn2V55eRbOWB7ght0xL+9Fm+u0vawocCEx5MzIKwLwbs
    eBAHurCPdmDaDPM3EPNs7MxO8zcEnjVxranJLnPnITFuK0bHc5B7xe5anipBNRs5
    hEhL7Y0B1tpfg7SETKO4Hm+OnfTraW4+6F1JFN7MMG+lZYuNkvKwUHIGvzz2TPcs
    OeFcPl01/Ncz5J2bfu4FLhbF0KtSHH/7KenVJ74VNOlhOQbE8IXvdt+69cw+zGPf
    7LUD6zol/Lu6X7jrIv1bySSSAOaFKZud2xy72Oi42QZMPLHGALvl2DdiJPZTJRb8
    UHkAZsUr2VNbtFEdfBL7+/cNjJLbNAFKHhAnnmDGj8Fu62X3x0gJjFQ+ZtfxlqQw
    Yhm9dTFh2dFzkXe+WD74YJm/tqq1n3iRIUDhPw4LtjmHqfpvQZ98EcXV5TZyvi43
    jUhK02E+4BPOyPTM2NezD1XmCcBMjp/FZimZh1cThRn0KCK8dD/5KatHIGuwGUIv
    7Jnq0ycziBwlkfg7c3t71ieMU9tkkJDRYNgWRwvvw0sugiP2uvl7WtgYct9B9ifx
    kZV0nEd+EMA+SAIWT4EBozYFHHnq3zJwRyHNJ38aiobK3mS6SSdAQkTkR3pPyiKZ
    xqXVKl6U/Jc6jkd3AgMBAAGjggHGMIIBwjAdBgNVHQ4EFgQURkESB9MGcm/Tvn4a
    Mw1uQgpQWr4wgcsGA1UdIwSBwzCBwIAURkESB9MGcm/Tvn4aMw1uQgpQWr6hgZyk
    gZkwgZYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQH
    DA1TYW4gRnJhbmNpc2NvMRQwEgYDVQQKDAtFeGFtcGxlIE9yZzEuMCwGA1UECwwl
    VGhlIEV4YW1wbGUgT3JnIGNlcnRpZmljYXRlIGF1dGhvcml0eTEUMBIGA1UEAwwL
    RXhhbXBsZSBPcmeCCQDLZPSB7PuUNzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1Ud
    DwEB/wQEAwIBBjApBgNVHREEIjAggRFjZXJ0c0BleGFtcGxlLm9yZ4ILZXhhbXBs
    ZS5vcmcwKQYDVR0SBCIwIIERY2VydHNAZXhhbXBsZS5vcmeCC2V4YW1wbGUub3Jn
    MFkGA1UdHwRSMFAwJKAioCCGHmh0dHA6Ly9leGFtcGxlLm9yZy9yZXZva2VkLmNy
    bDAooCagJIYiaHR0cDovL2NlcnRzLmV4YW1wbGUub3JnL2NlcnRzLmNybDANBgkq
    hkiG9w0BAQsFAAOCAgEApQSTPZF9QGXOeABWmQnEzGoy3+u8/xQ9t+uZiFAcmnMz
    tVCughKdNCN191pg9Ug4YY30490Ih19pAm/rzB7FFJWUM3qHn7cxU3X6+1Sb2fDo
    QwinvEWukYI5koxOG/BO4gnYif+ev5ESVvNTJf1EHsvgxt5RovAWf6bffaK0up4o
    K9xwMg4Ybj/QBT4OSqLq7jwt6wtBc7KJ8bwGswq9oPY+m0BYsoX5wxiRZG5sZ0Pz
    9ySrIAlOAA45dUy+Z2LgrcTTdwrXlTnNx8PJ0ogGAoMsAHSc4Ri1Zd0a++iik1cd
    7t0YXFs8rCGxXffBWP9rWPG4T+joeixXfnGgoECldjRE0W4UYBgrFnIDTDlmnBmE
    whmC86evv3cJ3AVNJobquklpWUS6Xg0Inx7gNrsHUf59amHWC1WmAc7dgGj0WoII
    Q0XU3lnMQvU+Zlje2k1QjLZX5i4OWmzMFhVriRMxrD2EHtzk2zmZdFHaGaUtPQOK
    ZzHu0bwyEzOXeCexmcnLW/xF1wimhgjL6KeROgLbJaXsGVS3DaGxSwh3l9gYwSKF
    AXxLNWJRf3VCmvvdHxRBSBovfBHW6U1sV01RHZWDg1CIprns0vqAiqH+C1EVkjNN
    0oWimIVIbbSTozs3ZfAMOxcsJlbtIU3Rl7JBlUjmLWDDjxmQhfTtm1yoSSGQQ+w=
    -----END CERTIFICATE-----
  '';
  extraCerts = { "Example Org CA" = exampleCA1Pem; };
  server1Pem = pkgs.writeText "server1.pem" ''
    -----BEGIN CERTIFICATE-----
    MIIF5TCCA82gAwIBAgIBATANBgkqhkiG9w0BAQsFADCBljELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNVBAcMDVNhbiBGcmFuY2lzY28xFDAS
    BgNVBAoMC0V4YW1wbGUgT3JnMS4wLAYDVQQLDCVUaGUgRXhhbXBsZSBPcmcgY2Vy
    dGlmaWNhdGUgYXV0aG9yaXR5MRQwEgYDVQQDDAtFeGFtcGxlIE9yZzAeFw0xOTAy
    MjIxMjA2NTRaFw00NjA3MTAxMjA2NTRaMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
    DApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMRQwEgYDVQQKDAtF
    eGFtcGxlIE9yZzEaMBgGA1UECwwRU2VydmVyIChJbnRlcm5hbCkxEDAOBgNVBAMM
    B3NlcnZlcjEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCrvO9BCNxb
    pg+Q1WY2MCBz2jhssUHMn/Ts1NwJz0896GqX/xwnYxsU7CXYoaALqmq3N/eCo25B
    /fx9uoBfbECZhsStPtb/fTPW0TbBJIzaL76wqxo0SHASrnzp2+ArS1EnMCMjYnwH
    mZriR/tNH3jBSYoRxWTpGaoafP0LIMTe2Xt9CsLCSfwvZC+Uj8k/eyObcfuRxlyC
    iZ1Na2zp7F4QAeSn+h42NzELvSHe3zzaCgSCmeQgL5u/OHU1bPw4DmgLo3NFmHyx
    dHyYV5uvD4lfYVbe/1tiaVIMzq66wIF4zfauUc/GS4fv3am9ceD43lYsXT61fLqZ
    kkpgIGWyKEmlAgMBAAGjggFTMIIBTzAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQE
    AwIFoDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDATAdBgNVHQ4EFgQU5dGaIGo4K3SW
    XXSv3aGFNGQ6dNAwgcsGA1UdIwSBwzCBwIAURkESB9MGcm/Tvn4aMw1uQgpQWr6h
    gZykgZkwgZYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYD
    VQQHDA1TYW4gRnJhbmNpc2NvMRQwEgYDVQQKDAtFeGFtcGxlIE9yZzEuMCwGA1UE
    CwwlVGhlIEV4YW1wbGUgT3JnIGNlcnRpZmljYXRlIGF1dGhvcml0eTEUMBIGA1UE
    AwwLRXhhbXBsZSBPcmeCCQDLZPSB7PuUNzAqBgNVHREEIzAhgRZob3N0bWFzdGVy
    QGV4YW1wbGUub3JnggdzZXJ2ZXIxMA0GCSqGSIb3DQEBCwUAA4ICAQAZdEGPv2X9
    w+GrJuSYyWoP3pR0GJJQ7Bt6p+gHQFhrInPZ3z0ldDddH04h4SvdB0I2OvgfQzdx
    BnrSs5WfSvArngrRDLK2aNW4yIY+Lrd40buUcNIMJ/XCHpU6uQV3cbJvmcqDBpo7
    0iy9kWtfSkofayQ8BPWgfCd/8ZSnhclCVX/qvlA6VwQpcWo2kSP7YJ5Kwj/novNa
    ysJ3SWpTRn+1TY/0k6iIVliW3v+3EtpDiAiUBa94S5rn6qxkkb1WeKxkdo6xTvay
    eLcDFFoRr2J735IW1/fafcoNt2P6x1i1aRXVCGwAEwFOPZSK9VGA82SAKfQSovkR
    2RvznKLN/cb3H/Cbi4NbGzqTPu/eRoJJKR3TffZDNIKZQCHRuUSJSuZtvyQ6aTtY
    h+zDVCav4tpuU7SGq098MH73jvg90tT/J/dc+sQ8dGEOdiIlbMADaglBo7NQ4sMK
    8Be9FWP/xhukI39Ce4XJMv7CemhzPmxF5YajYedumX6dPql4tG5F79/d1JZXoP/j
    xZqoiONWnD2p95Iq0kG8sUXPzvxOqL2TjNjZoygBJyZMABuxeBrdoJtXnFvL3umd
    IoUsDhVtoWCo8JBBXWO8Qhr3lPu99aobat/BxitLdVtJI00IBPVg0H2PzpczEq+g
    QETbqJ/y5PkjiHZhX9gAg3QWyANtgu6swg==
    -----END CERTIFICATE-----
  '';
  server1Key = pkgs.writeText "server1.key" ''
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpQIBAAKCAQEAq7zvQQjcW6YPkNVmNjAgc9o4bLFBzJ/07NTcCc9PPehql/8c
    J2MbFOwl2KGgC6pqtzf3gqNuQf38fbqAX2xAmYbErT7W/30z1tE2wSSM2i++sKsa
    NEhwEq586dvgK0tRJzAjI2J8B5ma4kf7TR94wUmKEcVk6RmqGnz9CyDE3tl7fQrC
    wkn8L2QvlI/JP3sjm3H7kcZcgomdTWts6exeEAHkp/oeNjcxC70h3t882goEgpnk
    IC+bvzh1NWz8OA5oC6NzRZh8sXR8mFebrw+JX2FW3v9bYmlSDM6uusCBeM32rlHP
    xkuH792pvXHg+N5WLF0+tXy6mZJKYCBlsihJpQIDAQABAoIBAD4WPvTnDCtB/Myi
    qaIbghAAK3f4GU6t4XEhfy84uHAsLyUmQHpo1OiaexA3VlIBWTVF0YB0Ly9CcF7P
    5wsYar5WP5JWbonNLMmTt1TaLuXObwUVxpJyQbovRM+TAxcD0qH1QC7Rsv9YY+s8
    lLiMES7ntDe6gkHXWmzbFOxJ+4KIy3Lv935ynCoymMCtUKnw3HyAbZ/GYD1F6sSR
    nE7F0uit5mMvWef2mn25wcEF3JZklE2mucLh6KnLMP8m8JtZg7Bw7+QitCRD+8+L
    vd6M1jyXMg0FpeAQp6VYvMA+gkMGOL9bB4eS9fwCjMbOUzmEn6r2y0eZ20IIu6Ww
    4x7ZLmECgYEA5LPYR4VX9eRvknrejgPQ0laDzDypEpwdeSGQsx/3XeddBfRj1C4c
    r/Ey0wtSnqXxd2ESxIQQyUWOZ0aFpCqVrq1hGEAJVcs/DX7e0qVezEGKJHqFzoms
    uirbxyK+1EagTWCCh+RP6LGRJ+gkOtvjAHQB3B52a+M4rOtvnWw3+z0CgYEAwDyA
    m1h/KX9Ge5dqymqjpW9y0wCp2WSGRF1WLwHDR65/NtYDpPZNaXhH3RBtmfRVonJO
    Bqplr3tBENB9F2SiGzp9ADd7a1OuskHEnsmhpYkjompE/E1Tj+td1ulHLco4Kojs
    88VjTLSH52UuE6IWtl/OVelbOXtdx0Qgrf+jjokCgYEAh2G61uOlZSbbsR9Q3Up+
    8/RIwr7p6t1FSS5IZPC4UvshguPfsHu3eaNTTcD3IHjlDqEFJhVzhmHJYXNKqxqW
    TrfNsTg/Dm1pHskKiDFig5EMgHmS+edfuzihryjvQ+OnAwbtXhoV/44VekUeJUWD
    BAKoEzBpM4ZnR117TfoAzZUCgYEAhH6u3WMncgCJIdIBBrZtSC8CYzAH4RAKAsCa
    EBgU8ijxAWiMZnxkapc+YL1b7UqcYzSJVsrG/yXieKZaMW9o03+CfE3BQP4SYEY4
    MIEkaqWU6/J2zba2K3G74c4zAvpnr9lkB7g6crnTGceA9IM5SEXMPyZxe7LttdPc
    +lBB+JECgYEAlstV5XT3auCak6Y5C511OR3jBGelYpa15dQhp97Gs4Rcd77wJvgO
    0XydnrwwpI+5CORRcAiBTlpjjc/PGmSIeN6K848Qvfk9gBccda4ZxE4bocPJ3OSD
    5qSgSFtQGfvUH6bYfEiJIMGyhBU029MgGoVJ4ILe0z1nWsR2gEwX/w4=
    -----END RSA PRIVATE KEY-----
  '';
  imports = pkgs.lib.hacknix.modules;
  makeMkCacertTest = name: clientAttrs:
    makeTestPython {
      name = "mkCacert-${name}";
      meta = with pkgs.lib; { maintainers = [ maintainers.dhess ]; };

      nodes = {

        client = { config, pkgs, ... }:
          {
            nixpkgs.localSystem.system = system;
            inherit imports;
          } // clientAttrs;

        server1 = { config, ... }: {
          nixpkgs.localSystem.system = system;
          networking.firewall.allowedTCPPorts = [ 443 ];
          services.nginx = {
            enable = true;
            virtualHosts."server1" = {
              forceSSL = true;
              sslCertificate = server1Pem;
              sslCertificateKey = server1Key;
              locations."/".root = pkgs.runCommand "docroot" { } ''
                mkdir -p "$out"
                echo "<!DOCTYPE html><title>server1</title>" > "$out/index.html"
              '';
            };
          };
        };
      };

      testScript = { nodes, ... }:
        let
          custom-cacert = pkgs.mkCacert { inherit extraCerts; };
        in
        ''
          start_all()
          server1.wait_for_unit("nginx.service")
          client.wait_for_unit("multi-user.target")

          with subtest("Default CA cert fails"):
              client.fail(
                  "${nodes.client.pkgs.wget}/bin/wget -O server1.html https://server1"
              )

          with subtest("Custom CA cert succeeds"):
              client.succeed(
                  "${nodes.client.pkgs.wget}/bin/wget -O server1.html --ca-certificate=${custom-cacert}/etc/ssl/certs/ca-bundle.crt https://server1"
              )
        '';
    };
in
makeMkCacertTest "default" { }
