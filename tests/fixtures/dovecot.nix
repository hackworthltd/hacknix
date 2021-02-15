{ testingPython, ... }:
with testingPython;
let
  exampleCA1Pem = pkgs.writeText "exampleCA1.pem" ''
    -----BEGIN CERTIFICATE-----
    MIIDsDCCApigAwIBAgIUb+J+7668MGVbc3oqgGTOml/pJbQwDQYJKoZIhvcNAQEL
    BQAwcDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcT
    DVNhbiBGcmFuY2lzY28xFDASBgNVBAoTC0ZvbyBDb21wYW55MR4wHAYDVQQLExVD
    ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTcxMTI5MTAxNTAwWhcNMjIxMTI4MTAx
    NTAwWjBwMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UE
    BxMNU2FuIEZyYW5jaXNjbzEUMBIGA1UEChMLRm9vIENvbXBhbnkxHjAcBgNVBAsT
    FUNlcnRpZmljYXRlIEF1dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
    AQoCggEBAOEDx1cE06sVt7lCOojqmwQHMsSJT03W6/V8NrfDXyvyXUixIEAn+iPu
    MvbNr6JkuSLctRw4tsZCK/BgEepMUt01gixSK755mrOCNCb2ijBmK0tiYvp8jwno
    g7V4M3BcUozMD5Ez5mBpbo1OWnb6yvS64csCGGbfKH7hRU2CpvqZ9AD+GQ/suA4Q
    1RSC+JxXJfjw3aMr8goNOQAyPjrDZEIGZ0K20BhDZAb8v3yZ8ZaQbXq5xE9TaCDw
    ZJiQ5PjCQ4yNEWyc2iPFX091XinTN6dr0BD3+Cp7kVVZVCCBq/8gT5nbC5saUHJf
    FZu3bk0DLFrLxXKyesQ/20SWtGLGOJkCAwEAAaNCMEAwDgYDVR0PAQH/BAQDAgEG
    MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMnX3yF993aswclyaHwFsO8X0dQX
    MA0GCSqGSIb3DQEBCwUAA4IBAQCDBlRN0HJXOa7exyy6huNyN/lIUAvP4SDRBrHr
    cYfjMgqvPRzLSxiBFOcoG8BhExp68w1zSyyfuroqHDvh0FaUV7p1pqUVdw2fDiqW
    /238gtJP7MpUU4oXVEmvJhsGv3aboaiXYw3iCzJjXFXI5ypZybm3bdbxBWMcspw9
    A6ZbOTxtteDEojm0GEuxkkLGCMXjA3EVdjleByxAA6nFQGVZiFSShrPQoXlckuBx
    mnHp9wHIMLSp4KUtZ9IBmpyxLrSYwGJUzmydoVmc/MjDutEEC6Pt3SRZbRO/eWSP
    CIu9OpGQEqT2npTMX2echilaFjlKB3D3X91sgJ7Z0v2KrDz8
    -----END CERTIFICATE-----
  '';
  server1Pem = pkgs.writeText "server1.pem" ''
    -----BEGIN CERTIFICATE-----
    MIID8TCCAtmgAwIBAgIUdj0L3zecvezJnwb6BxuKdzhHgtwwDQYJKoZIhvcNAQEL
    BQAwcDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcT
    DVNhbiBGcmFuY2lzY28xFDASBgNVBAoTC0ZvbyBDb21wYW55MR4wHAYDVQQLExVD
    ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTcxMTI5MTAxNzAwWhcNMTgxMTI5MTAx
    NzAwWjBeMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UE
    BxMNU2FuIEZyYW5jaXNjbzEUMBIGA1UEChMLRm9vIENvbXBhbnkxDDAKBgNVBAsT
    A1dXVzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJKLTKU3EHm61LPN
    MLi+gD3ZwyEKTZ9BTyxmBXev5MN0ZkODBCGcas+3NdWn3N9VxqxfYPoT71nbr6ea
    SkNpujW0FVxkjkjiWYsgT0X6N5mgH5hY5mYG5olYDLMtZBSeN5tFWSylu8OTUf6f
    YOkOAloylf1g/Shwk/pAFccAm3+xSjl21S9/IFxNyz6aUrh6JocxG7r1F/VBDabz
    6262fITeEJejlDiwDfEnpC1qOj8/hi7OgLEjEQ9RFbgbIfGwCz2MYi8hVkJFDou4
    z7N6uBKBMTNCtU+/Ty5CPt9jeIo90Wa6ljAa5lRY4BR0JpapXYZYMTLbu6Y5QFFB
    ZM425ucCAwEAAaOBlDCBkTAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYB
    BQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFBZXN0ClUkL+
    tBcXwQvpepl4EjlLMB8GA1UdIwQYMBaAFMnX3yF993aswclyaHwFsO8X0dQXMBIG
    A1UdEQQLMAmCB3NlcnZlcjEwDQYJKoZIhvcNAQELBQADggEBAEMq6m5ppMi9WURm
    ZY4i8GNzFUF4hs7KAruOmuyDzEaBnJT5fYZq+lmMk6MS3FsKx6+QuT/0yufJzrqP
    q+vuTW11EUgiqgvWHcOgARHY0gcY9+Mv+hsB239RreCNVi7Y9Wmx3YDQNd5pzVFv
    O+1acKn7gDJOiuosvXWEdrY0XH9O3Mndbtw90nI0Gj1a3s74xhfp8DbNilwVetyc
    fo9sumZafCkthFbofag36cnznXuY/SJJMGUzE8RMU1ztMfoTjz8OwW00GPgHbaAy
    XYMRssS2T8Da8zHU6j8JKvvc16lA/LEqUZPQqtU6MhxKmuMYM4pLFqjv37BKNkhj
    dN6RX7s=
    -----END CERTIFICATE-----
  '';
  server1Key = pkgs.writeText "server1.key" ''
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAkotMpTcQebrUs80wuL6APdnDIQpNn0FPLGYFd6/kw3RmQ4ME
    IZxqz7c11afc31XGrF9g+hPvWduvp5pKQ2m6NbQVXGSOSOJZiyBPRfo3maAfmFjm
    ZgbmiVgMsy1kFJ43m0VZLKW7w5NR/p9g6Q4CWjKV/WD9KHCT+kAVxwCbf7FKOXbV
    L38gXE3LPppSuHomhzEbuvUX9UENpvPrbrZ8hN4Ql6OUOLAN8SekLWo6Pz+GLs6A
    sSMRD1EVuBsh8bALPYxiLyFWQkUOi7jPs3q4EoExM0K1T79PLkI+32N4ij3RZrqW
    MBrmVFjgFHQmlqldhlgxMtu7pjlAUUFkzjbm5wIDAQABAoIBACg/J7KsV9MG08n5
    zaq/bxsNhoC5gq39UtA/yLqhTTO88SUTg3vzqIYZrChcrNWNij3nCAxGk1LbefeO
    8VxoWiLLrZ4tY8Jyn+MM4Zi3arO/fU3rBIP62y/XRc2j5rue5Gi5eA9CCTpiaH+E
    qCn5lf3NrNHk5EJKAOoW1aRM72f3D6ZTIUcGbiTuHh7J0wQZ/MFseD+1iBSgJZmd
    fRz3P5X+WVu1cB1Hw61n8JiKbv0zEkM8J+TJ28Xo44k2zpytTnXmeDh5fRp7KW8Y
    BarpSUncIsMoOaHwv3YirI1B0Twhn8k2XpQAZRpdludx7ETYuPS6DEI+RJsbA28e
    dEifW2kCgYEAwNFIUAv384n2axMMBOjHbUXT9llhHw8DNgzaLWAyba+agcu5M+Pt
    l9ADM6DjD32Wfb/HfJDPDWBUbPcUPddA7K0yNH2D3uvqEcGn/xn1QDXnQZwmWBMy
    D1lKYN0PtJgjcIDs+sxb7A1eD1COFTF+EhOfCB2CGb3GBzVn3EwQUI0CgYEAwpBS
    e0QLxhkRkYLX4eNeVy6LKYDX4+Ai/GZ4QhjAU8TAfNxKA6wTj8kM6i1jzRMg+7bG
    zCGODO6KSR30iBZz6Rxg+bH9MWrceZe1sP9CXHdT0mLiUrWKoGhm7Mmr9I+KIUCD
    66i2uhBTOM5a5lwRBxJcwPeAtIjrZl1R4fSxmkMCgYAn2RiAsniDtDdg2YbaXOEa
    DBxKBR61NH0NZoqQZhkF4gykVl3oA2rOvQZsXQuP3/yB8GhhreuccBQCkO11+k5I
    m2KMxoPCRi8RjFwTtGGi64DnZkXmXdEyqtlcO1NLl0V7sqlHC4TTu898isFST/Al
    /DgZjT+d4kJSqw7T0ERu4QKBgQCZ+lHsj+upeUl4GU70zFZrNMCZtgglpcrKaeYe
    mSwMn5eeuVAyG8rXbku0QPvM3qipzPsDrkKXZWk3eGeAFBTjlbwBoKU6qNGXwULf
    swQ33ZAO3ocy4c22KSnbl7dosvikXESLCliiZC0YtecmjBJFwHh7luTa+8kgmBYn
    dtnftQKBgQCJ2Tvfr6Dz0MGhkw4UHd3yHNmIO4ltI8nhqQm5H39IGmdozBM74aro
    /Se10pE1Dky0/uo7gA9vcEufxXCjIb0q4QvBPQ+SBo1xL4QpWsiyB7jFGqr6/Tie
    gnK6FH1Gxkquo9AnV8KGXJQ9AOllUkgv+Zg2G1bIEcgqbGIfuOo79g==
    -----END RSA PRIVATE KEY-----
  '';

  imports = [ ../include/user-account.nix ];

in
makeTest {
  name = "dovecot";

  meta = with pkgs.lib.maintainers; { maintainers = [ dhess ]; };

  machine = { pkgs, config, ... }: {
    inherit imports;

    services.postfix.enable = true;
    services.dovecot2 = {
      enable = true;
      imap.enable = true;
      sslCACert = exampleCA1Pem;
      sslServerCert = server1Pem;
      sslServerKey = server1Key;
      dhParamsFile = pkgs.ffdhe3072Pem;
      lmtp = {
        postmasterAddress = "root@localhost";
        inet.enable = true;
      };
    };

    environment.systemPackages =
      let
        sendTestMail = pkgs.writeScriptBin "send-testmail" ''
          #!${pkgs.stdenv.shell}
          exec sendmail -vt <<MAIL
          From: root@localhost
          To: alice@localhost
          Subject: Very important!

          Hello world!
          MAIL
        '';
        sendTestMailViaDeliveryAgent = pkgs.writeScriptBin "send-lda" ''
          #!${pkgs.stdenv.shell}

          exec ${pkgs.dovecot}/libexec/dovecot/deliver -d bob <<MAIL
          From: root@localhost
          To: bob@localhost
          Subject: Something else...

          I'm running short of ideas!
          MAIL
        '';
        testImap = pkgs.writeScriptBin "test-imap" ''
          #!${pkgs.python3.interpreter}
          import imaplib

          with imaplib.IMAP4('localhost') as imap:
            imap.login('alice', 'foobar')
            imap.select()
            status, refs = imap.search(None, 'ALL')
            assert status == 'OK'
            assert len(refs) == 1
            status, msg = imap.fetch(refs[0], 'BODY[TEXT]')
            assert status == 'OK'
            assert msg[0][1].strip() == b'Hello world!'
        '';
      in
      [ sendTestMail sendTestMailViaDeliveryAgent testImap ];
  };

  testScript = ''
    machine.wait_for_unit("postfix.service")
    machine.wait_for_unit("dovecot2.service")
    machine.succeed("send-testmail")
    machine.succeed("send-lda")
    machine.wait_until_fails('[ "$(postqueue -p)" != "Mail queue is empty" ]')
    machine.succeed("test-imap")
  '';
}
