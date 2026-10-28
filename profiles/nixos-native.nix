{
  nixpkgs,
  self,
  overlays,
}:
let
  hostname = "gathering-hub";
  pre-cfg = pkgs: {
    profile.prompt = ">";
    home.sessionVariables = {
      # So I can use `sudo sops edit` from gathering hub.
      SOPS_AGE_KEY_CMD = "sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key";
    };
    programs.git.settings = {
      user.email = "robin.kneepkens@hotmail.com";
      credential = {
        helper = "${pkgs.gh}/bin/gh auth git-credential";
        # credentialStore = "gpg";
      };
    };
    programs.jujutsu.settings = {
      user.email = "robin.kneepkens@hotmail.com";
    };
    programs.helix = {
      settings.theme = "penumbra+";
      languages.language-server.nixd.config.options.nixos.expr =
        "(builtins.getFlake \"${self}\").nixosConfigurations.\"${hostname}\".options";
    };
  };
in
rec {
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system overlays; };
  cfg = pre-cfg pkgs;
  username = "untio11";
  inherit hostname;
  base-home-dir = "/home";
  nixos-configuration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      backup-root-dir = "/data/backups";
      syncthing-root-dir = "/data/syncthing";
      ports = {
        home-assistant = "8123";
        paperless = 28981;
        syncthing = "8384";
        mosquitto = 1883;
        zigbee2mqtt = 8080;
        adguard = "3000";
      };
    in
    {
      # Home Assistant related setup
      services.home-assistant = {
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
          ];
      };

      services.mosquitto = {
        enable = true;
        listeners = [
          {
            address = "127.0.0.1";
            port = ports.mosquitto;
            omitPasswordAuth = true; # Do I want to enable this eventually?
            settings.allow_anonymous = true;
            acl = [ "pattern readwrite #" ];
          }
        ];
      };
      services.zigbee2mqtt = {
        enable = true;
        settings = {
          version = 5;
          homeassistant.enabled = true;
          permit_join = false; # Toggle via web UI when pairing new devices.
          mqtt.server = "mqtt://127.0.0.1:${toString ports.mosquitto}";
          # SMLIGHT SLZB-07 config
          serial = {
            port = "/dev/serial/by-id/usb-SMLIGHT_SMLIGHT_SLZB-07_9e2fd2b588d5ef1183fb694b49d2c684-if00-port0";
            adapter = "ember";
            baudrate = 115200;
            rtscts = true;
          };
          frontend = {
            enabled = true;
            host = "127.0.0.1";
            port = ports.zigbee2mqtt;
          };
          # First time deployment with value `GENERATE` generated these values.
          advanced = {
            # `zigbee2mqtt-secret.yaml` created by sops.
            network_key = "!secret network_key";
            pan_id = 2296;
            ext_pan_id = [
              90
              195
              14
              142
              202
              41
              196
              14
            ];
          };
        };
      };

      sops = {
        defaultSopsFile = ../secrets/api-keys.yaml;
        defaultSopsFormat = "yaml";
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

        secrets."mijnhost_api_key" = { };
        # Render an environment file in RAM for ACME to read
        templates."acme-mijnhost.env" = {
          content = ''
            MIJNHOST_API_KEY="${config.sops.placeholder.mijnhost_api_key}"
          '';
        };

        secrets."zigbee2mqtt_network_key" = { };
        templates."zigbee2mqtt-secret.yaml" = {
          owner = "zigbee2mqtt";
          path = "/var/lib/zigbee2mqtt/secret.yaml";
          content = ''
            network_key: ${config.sops.placeholder.zigbee2mqtt_network_key}
          '';
        };

        secrets."mijnhost_ddns_password" = { };

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
        secrets."untio11_gathering_hub_password_hash".neededForUsers = true;
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "robin.kneepkens@hotmail.com";

        certs."furahiya.nexus" = {
          # Issue certificate to all service subdomains `<service>.furahiya.nexus`.
          extraDomainNames = [ "*.furahiya.nexus" ];
          dnsProvider = "mijnhost";
          # File contains the API key.
          environmentFile = config.sops.templates."acme-mijnhost.env".path;
          group = "nginx"; # Give nginx permission to read the certificate.
          dnsResolver = "1.1.1.1:53"; # Resolve via Cloudflare to circumvent Ziggo's negative cache resonse.
        };
      };

      # Configure Gathering Hub as local DNS server that filters requests to known ad and malware domains.
      services.adguardhome = {
        enable = true;
        settings = {
          http.address = "127.0.0.1:${ports.adguard}";
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

      # Enable mDNS so `gathering-hub.local` resolves to this machine's IP address
      # on LAN.
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true; # Open port 5353 for UDP mDNS traffic
        settings.publish.publish-addresses = true;
      };
      # Dynamic DNS - Update Mijn Host `gate.furahiya.nexus` DNS entry periodically to
      # point to my public IP address.
      services.ddclient = {
        enable = true;
        server = "mijn.host";
        username = "ddns_f928877f9d95";
        passwordFile = config.sops.secrets."mijnhost_ddns_password".path;
        domains = [ "gate.furahiya.nexus" ];
      };
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        clientMaxBodySize = "100m"; # Allow uploading large documents for Paperless.
        virtualHosts =
          let
            domain = "furahiya.nexus";
            mkVhost = proxyConfig: {
              useACMEHost = domain;
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
            "home-assistant.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${ports.home-assistant}";
              extraConfig = "proxy_buffering off;";
            };
            "paperless.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString ports.paperless}";
            };
            "syncthing.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${ports.syncthing}/";
            };
            "zigbee2mqtt.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString ports.zigbee2mqtt}";
            };
            "adguard.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${ports.adguard}";
            };
          };
      };
      # PostgreSQL database for Home Assistant and Paperless
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_18;
        ensureDatabases = [
          "hass"
          "paperless"
        ];
        ensureUsers = [
          {
            name = "hass";
            ensureDBOwnership = true;
          }
          {
            name = "paperless";
            ensureDBOwnership = true;
          }
        ];
      };
      services.postgresqlBackup = {
        # Default schedule: daily at 01:15 (`startAt` property.)
        enable = true;
        location = "${backup-root-dir}/postgresql";
      };

      services.paperless = {
        enable = true;
        address = "127.0.0.1";
        port = ports.paperless;
        consumptionDir = "/data/paperless/consume";
        consumptionDirIsPublic = true;
        settings = {
          PAPERLESS_URL = "https://paperless.furahiya.nexus";
          # Languages for Optical Character Recognition (OCR).
          PAPERLESS_OCR_LANGUAGE = "eng+nld";
          PAPERLESS_TIME_ZONE = "Europe/Amsterdam";
          # Database Config
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "/run/postgresql";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBUSER = "paperless";
          # Document consumption config
          PAPERLESS_CONSUMER_DELETE_DUPLICATES = true; # Simply delete documents from the consumer dir in case of duplicate detection.
          PAPERLESS_CONSUMER_RECURSIVE = true; # Allow paperless to consume documents from subdirectories of the consumer dir.
          PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true; # Subdirectories leading to the consumed document will be added as tags.
        };
        exporter = {
          enable = true;
          directory = "${backup-root-dir}/paperless";
          onCalendar = "weekly";
        };
      };

      services.syncthing = {
        enable = true;
        # Makes sure the files managed by syncthing belong to my user account.
        user = username;
        group = "users";
        dataDir = syncthing-root-dir;
        configDir = "${base-home-dir}/${username}/.config/syncthing";
        openDefaultPorts = true;
        guiAddress = "127.0.0.1:${ports.syncthing}"; # Localhost only; Nginx will expose it
        settings.gui.insecureSkipHostcheck = true; # For reverse proxy support.
        # Allow stateful management of devices and shared folders without NixOS overwriting
        # the config on rebuild.
        overrideDevices = false;
        overrideFolders = false;
      };

      # Ensure the `/data/backups` directory exists.
      systemd.tmpfiles.rules = [
        "d ${backup-root-dir} 0755 root root -"

        # Ensure the base consume folder exists with full access
        "d /data/paperless/consume 0777 paperless paperless -"

        # Force DEFAULT ACLs so any subfolder/file created by Syncthing or you
        # automatically inherits read, write, and delete permissions for the paperless user
        "A+ /data/paperless/consume - - - - default:user:paperless:rwx,default:group:users:rwx,default:other::rwx"
        "A+ /data/paperless/consume - - - - user:paperless:rwx,group:users:rwx,other::rwx"
      ];

      # Otherwise tty1 hangs after boot. Switch to tty2 when multi-user system target
      # is reached (ctrl+alt+f2).
      systemd.services."kmsconvt@tty1".enable = false;
      services.xserver.xkb = {
        layout = "us";
        variant = "dvorak";
      };
      services.getty.autologinUser = username;
      services.kmscon = {
        enable = true;
        useXkbConfig = true;
        extraOptions = "--term xterm-256color --rotate right";
        config = {
          hwaccel = true;
          font-name = "FiraCode Nerd Font Mono";
          font-size = 15;
        };
      };
      fonts.packages = [
        pkgs.nerd-fonts.fira-code
      ];
      console = {
        keyMap = "dvorak";
        earlySetup = true;
        packages = [
          pkgs.terminus_font
        ];
        font = "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";
        colors = [
          "222222"
          "D81765"
          "6FD01A"
          "F6B841"
          "16B1FB"
          "D783FF"
          "76D6FF"
          "EBEBEB"
          "666666"
          "F2163E"
          "80CC33"
          "FFB000"
          "289CD5"
          "F736C4"
          "00D4D4"
          "F8F8F8"
        ];
      };
      boot = {
        kernelParams = [
          "fbcon=rotate:1" # Rotate 90 deg clockwise
          "video=1920x1080@60"
          "nvidia-drm.modeset=1"
          "nvidia-drm.fbdev=1"
        ];
        loader = {
          systemd-boot = {
            enable = true;
            consoleMode = "max";
          };
          efi.canTouchEfiVariables = true;
        };
        kernelModules = [ "kvm-intel" ];
        initrd.availableKernelModules = [
          "xhci_pci"
          "ehci_pci"
          "ahci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];
      };
      hardware.cpu.intel.updateMicrocode = true;
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false; # Use proprietery drivers
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580; # Necessary for GTX 750
      };
      networking = {
        hostName = hostname;
        useDHCP = lib.mkDefault true;
        networkmanager.enable = true;
        firewall = {
          enable = true;
          allowedTCPPorts = [
            22 # SSH
            53 # AdGuard Home DNS
            80 # HTTP for nginx reverse proxy
            443 # HTTPS
          ];
          allowedUDPPorts = [
            53 # AdGuard Home DNS
          ];
        };
      };
      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ username ];
        };
      };
      environment.systemPackages = with pkgs; [
        git
        helix
        lsd
        bat
        zsh
        pass
        tmux
        nmap
      ];

      nixpkgs = {
        inherit system;
        config.allowUnfree = true;
      };
      programs = {
        zsh.enable = true;
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          enableExtraSocket = true;
        };
      };
      services.openssh.enable = true;

      users.users = {
        # untio11
        "${username}" = {
          isNormalUser = true;
          hashedPasswordFile = config.sops.secrets."untio11_gathering_hub_password_hash".path;
          description = "Robin Kneepkens";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          home = "${base-home-dir}/${username}";
          shell = pkgs.zsh;
        };
        # So paperless can interect with my files.
        paperless.extraGroups = [ "users" ];
      };

      # Locale/internationalisation properties.
      time.timeZone = "Europe/Amsterdam";
      i18n.defaultLocale = "en_US.UTF-8";

      fileSystems = {
        "/" = {
          # sda2
          device = "/dev/disk/by-uuid/8d57c9c0-ac30-47bd-b659-3b9dc4b5de29"; # SSD
          fsType = "ext4";
        };
        "/boot" = {
          # sda1
          device = "/dev/disk/by-uuid/015C-82D5"; # SSD
          fsType = "vfat";
        };
        "/data" = {
          # sdb1
          device = "/dev/disk/by-uuid/776808a4-707d-40fd-baae-895785d0bd3a"; # HDD
          fsType = "ext4";
          options = [ "nofail" ];
        };
      };
      swapDevices = [
        # sda3
        { device = "/dev/disk/by-uuid/9025aa85-720d-46f7-a7d6-d0cd15793355"; } # SSD
      ];

      system.stateVersion = "23.05";
    };
}
