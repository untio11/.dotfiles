{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.gathering-hub.ports.home-assistant = lib.mkOption {
    type = lib.types.port;
    default = 8123;
    description = lib.mdDoc ''
      Home Assistant Web UI port
    '';
  };

  config.sops = {
    secrets."home_latitude" = { };
    secrets."home_longitude" = { };
    secrets."parents_latitude" = { };
    secrets."parents_longitude" = { };
    secrets."skunk_latitude" = { };
    secrets."skunk_longitude" = { };
    templates."hass-secrets.yaml" = {
      owner = "hass";
      path = "/var/lib/hass/secrets.yaml";
      content = ''
        home_latitude: ${config.sops.placeholder.home_latitude}
        home_longitude: ${config.sops.placeholder.home_longitude}
        parents_latitude: ${config.sops.placeholder.parents_latitude}
        parents_longitude: ${config.sops.placeholder.parents_longitude}
        skunk_latitude: ${config.sops.placeholder.skunk_latitude}
        skunk_longitude: ${config.sops.placeholder.skunk_longitude}
      '';
    };
  };

  # Home Assistant related setup
  config.services.home-assistant = {
    enable = true;
    extraComponents = [
      # Minimal set of components for initial setup
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      "isal" # Recommended for fast zlib compression
      "mqtt" # For zigbee2mqtt
      "adguard" # Accessible AdGuard Toggle and stats
      "unifi" # Integrate UniFi Network stuff
      "systemmonitor" # Monitor Gathering-Hub host
      "syncthing" # Monitor syncthing status
      "cert_expiry" # Monitor furahiya.nexus Let's Encrypt certificate
      "dnsip" # Track public ip via `gate.furahiya.nexus`
      "buienradar"
    ];
    customComponents = [ (import ../hass/custom_components/local-tuya.nix { inherit pkgs; }) ];
    config = {
      homeassistant = {
        name = "Astera";
        unit_system = "metric";
        latitude = "!secret home_latitude";
        longitude = "!secret home_longitude";
        radius = "20";
        elevation = "3";
      };
      zone = [
        {
          name = "Ouders";
          latitude = "!secret parents_latitude";
          longitude = "!secret parents_longitude";
          radius = 50;
        }
        {
          name = "Werk";
          latitude = "!secret skunk_latitude";
          longitude = "!secret skunk_longitude";
          radius = 50;
        }
      ];
      default_config = { };
      # Editable automations via the Home Assistant UI (/var/lib/hass/automations.yaml).
      automation = "!include automations.yaml";
      # Declarative automations managed via Nix.
      "automation nix" = import ../hass/automations/control.nix;
      # Use postgresql instead of default sqlite.
      recorder.db_url = "postgresql://@/hass";
      http = {
        # Note: this config should be set via the home-assistant ui
        # To manually edit the value there, edit `/var/lib/hass/.storage/http`
        # You might need to `sudo chown hass:hass` and `sudo chmod 644`
        # that file after editing it.
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
    };
    extraPackages =
      python3Packages: with python3Packages; [
        psycopg2 # postgresql support
        pyatv
        getmac
        brother # Printer
        pyipp
        aioshelly
        ephem # Season tracking
        pypaperless # Paperless ngx integration
      ];
  };
}
