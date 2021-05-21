final: prev:
let
  ## Google Public DNS servers.

  googleV4DNS = [ "8.8.8.8" "8.8.4.4" ];
  googleV6DNS = [ "2001:4860:4860::8888" "2001:4860:4860::8844" ];
  googleDNS = googleV4DNS ++ googleV6DNS;


  ## Cloudflare Public DNS servers.

  cloudflareV4DNS = [ "1.1.1.1" "1.0.0.1" ];
  cloudflareV6DNS = [ "2606:4700:4700::1111" "2606:4700:4700::1001" ];
  cloudflareDNS = cloudflareV4DNS ++ cloudflareV6DNS;

  ## Cloudflare Public DNS servers, DNS over TLS with certificate checking.
  ##
  ## Note that this format is only useful with the Unbound recursive
  ## caching DNS server, in combination with with Unbound
  ## tls-cert-bundle and forward-tls-upstream directives.

  cfIPToTLS = ip: "${ip}@853#cloudflare-dns.com";
  cloudflareV4DNSOverTLS = map cfIPToTLS cloudflareV4DNS;
  cloudflareV6DNSOverTLS = map cfIPToTLS cloudflareV6DNS;
  cloudflareDNSOverTLS = cloudflareV4DNSOverTLS ++ cloudflareV6DNSOverTLS;


  ## A&A's DoT service.
  #
  # This format is only useful with Unbound; see notes on the
  # Cloudflare equivalent service above.
  #
  # See https://support.aa.net.uk/DoH_and_DoT.

  aAndAV4DNSOverTLS = [ "217.169.20.22@853#dns.aa.net.uk" "217.169.20.23@853#dns.aa.net.uk" ];
  aAndAV6DNSOverTLS = [ "2001:8b0::2022@853#dns.aa.net.uk" "2001:8b0::2023@853#dns.aa.net.uk" ];
  aAndADNSOverTLS = aAndAV4DNSOverTLS ++ aAndAV6DNSOverTLS;
in
{
  lib = (prev.lib or { }) // {
    dns = (prev.lib.dns or { }) // {
      inherit googleV4DNS googleV6DNS googleDNS;
      inherit cloudflareV4DNS cloudflareV6DNS cloudflareDNS;
      inherit cloudflareV4DNSOverTLS cloudflareV6DNSOverTLS cloudflareDNSOverTLS;
      inherit aAndAV4DNSOverTLS aAndAV6DNSOverTLS aAndADNSOverTLS;
    };
  };
}
