{
  config,
  lib,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  options.gathering-hub.domain = lib.mkOption {
    type = lib.types.str;
    default = "furahiya.nexus";
    description = lib.mdDoc ''
      Base domain name used for ACME certificates, Dynamic DNS, and Nginx virtual hosts
    '';
  };
  # Move to services/vaultwarden.nix once Vaultwarden is migrated to its own module.
  options.gathering-hub.ports.vaultwarden = lib.mkOption {
    type = lib.types.port;
    default = 8222;
    description = lib.mdDoc ''
      Vaultwarden Web UI port
    '';
  };

  config.sops = {
    secrets."mijnhost_api_key" = { };
    # Render an environment file in RAM for ACME to read
    templates."acme-mijnhost.env" = {
      content = ''
        MIJNHOST_API_KEY="${config.sops.placeholder.mijnhost_api_key}"
      '';
    };
    secrets."mijnhost_ddns_password" = { };
  };

  config.services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    clientMaxBodySize = "100m"; # Allow uploading large documents for Paperless.
    virtualHosts =
      let
        mkVhost = proxyConfig: {
          useACMEHost = cfg.domain;
          forceSSL = true;
          locations."/" = proxyConfig // {
            proxyWebsockets = true;
            # Otherwise nginx will spit out connection-timed-out errors for most services.
            extraConfig = ''
              proxy_read_timeout 3600s;
              proxy_send_timeout 3600s;
              ${proxyConfig.extraConfig or ""}
            '';
          };
        };
      in
      {
        "home-assistant.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.home-assistant}";
          extraConfig = "proxy_buffering off;";
        };
        "paperless.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.paperless}";
        };
        "paperless-gpt.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.paperless-gpt}";
        };
        "syncthing.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.syncthing}/";
        };
        "zigbee2mqtt.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.zigbee2mqtt}";
        };
        "adguard.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.adguard}";
        };
        "vaultwarden.${cfg.domain}" = mkVhost {
          proxyPass = "http://127.0.0.1:${toString cfg.ports.vaultwarden}";
        };
      };
  };

  config.security.acme = {
    acceptTerms = true;
    defaults.email = "robin.kneepkens@hotmail.com";
    certs.${cfg.domain} = {
      # Issue certificate to all service subdomains `<service>.furahiya.nexus`.
      extraDomainNames = [ "*.${cfg.domain}" ];
      dnsProvider = "mijnhost";
      # File contains the API key.
      environmentFile = config.sops.templates."acme-mijnhost.env".path;
      group = "nginx"; # Give nginx permission to read the certificate.
      dnsResolver = "1.1.1.1:53"; # Resolve via Cloudflare
    };
  };

  # Dynamic DNS - Update Mijn Host `gate.furahiya.nexus` DNS entry periodically to
  # point to my public IP address.
  config.services.ddclient = {
    enable = true;
    server = "mijn.host";
    username = "ddns_f928877f9d95";
    passwordFile = config.sops.secrets."mijnhost_ddns_password".path;
    domains = [ "gate.${cfg.domain}" ];
  };

  # Enable mDNS so `gathering-hub.local` resolves to this machine's IP address on LAN.
  config.services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # Open port 5353 for UDP mDNS traffic
    settings.publish.publish-addresses = true;
  };
}
