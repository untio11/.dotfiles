{
  config,
  lib,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  options.gathering-hub.ports.adguard = lib.mkOption {
    type = lib.types.port;
    default = 3000;
    description = lib.mdDoc ''
      AdGuard Home Web UI port
    '';
  };
  # Configure Gathering Hub as local DNS server that filters requests to known ad and malware domains.
  config.services.adguardhome = {
    enable = true;
    settings = {
      http.address = "127.0.0.1:${toString cfg.ports.adguard}";
      dns = {
        # Listen to DNS requests on all network interfaces.
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        # Forward unknown domain name queries to these public DNS servers.
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://cloudflare-dns.com/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
        # Resolve local client names via UniFi.
        private_dns = [ "192.168.0.1" ]; # UniFi Router IP
        use_private_dns_resolvers = true;
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
        rewrites = [ ];
      };
      # Herschrijf furahiya.nexus + *.furahiya.nexus naar 192.168.0.3,
      # maar laat gate.furahiya.nexus met rust (zodat die het echte WAN-IP houdt):
      user_rules = [
        "||furahiya.nexus^$dnsrewrite=192.168.0.3"
        "@@||gate.furahiya.nexus^$dnsrewrite"
      ];
      filters = [
        {
          enabled = true;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        }
        {
          enabled = true;
          name = "HaGeZi's Pro Blocklist";
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
        }
        {
          enabled = true;
          name = "OISD Blocklist Big";
          url = "https://big.oisd.nl";
        }
      ];
      clients = {
        persistent = [
          {
            name = "Yukomo (WireGuard)";
            ids = [ "192.168.3.2" ];
            use_global_settings = true;
            use_global_blocked_services = true;
          }
          {
            name = "FlowTellie (WireGuard)";
            ids = [ "192.168.3.3" ];
            use_global_settings = true;
            use_global_blocked_services = true;
          }
          {
            name = "PC-Robin (WireGuard)";
            ids = [ "192.168.3.4" ];
            use_global_settings = true;
            use_global_blocked_services = true;
          }
        ];
      };
    };
  };
}
