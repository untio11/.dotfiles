{
  nixpkgs,
  overlays,
}:
let
  hostname = "gathering-hub";
  username = "untio11";
  base-home-dir = "/home";
  hm = "${base-home-dir}/${username}/.config/home-manager";
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
      languages.language-server.nixd.config.nixd.options.nixos.expr =
        "(builtins.getFlake \"${hm}\").nixosConfigurations.\"${hostname}\".options";
    };
  };
in
rec {
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };
  cfg = pre-cfg pkgs;
  inherit hostname username base-home-dir;
  userConfigDir = "${base-home-dir}/${username}/.config";
  nixos-configuration =
    {
      config,
      lib,
      ...
    }:
    let
      backup-root-dir = "/data/backups";
      ports = {
        vaultwarden = 8222;
      };
    in
    {
      imports = [
        ../services/adguard.nix
        ../services/home-assistant.nix
        ../services/paperless.nix
        ../services/zigbee2mqtt.nix
        ../services/syncthing.nix
      ];

      gathering-hub.ports = {
        adguard = 3000;
        home-assistant = 8123;
        mosquitto = 1883;
        paperless = 28981;
        paperless-gpt = 8081;
        zigbee2mqtt = 8080;
        syncthing = 8384;
      };

      gathering-hub.mediaDirs = {
        syncthing-root = "/data/syncthing";
      };

      sops = {
        defaultSopsFile = ../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets."untio11_gathering_hub_password_hash".neededForUsers = true;

        secrets."mijnhost_api_key" = { };
        # Render an environment file in RAM for ACME to read
        templates."acme-mijnhost.env" = {
          content = ''
            MIJNHOST_API_KEY="${config.sops.placeholder.mijnhost_api_key}"
          '';
        };
        secrets."mijnhost_ddns_password" = { };
        secrets."restic_password" = { };
        secrets."gcp_restic_credentials_json" = { };
        secrets."vaultwarden_admin_token_hash" = { };
        templates."vaultwarden.env" = {
          content = ''
            ADMIN_TOKEN='${config.sops.placeholder.vaultwarden_admin_token_hash}'
          '';
        };
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
              proxyPass = "http://127.0.0.1:${toString config.gathering-hub.ports.home-assistant}";
              extraConfig = "proxy_buffering off;";
            };
            "paperless.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString config.gathering-hub.ports.paperless}";
            };
            "paperless-gpt.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString config.gathering-hub.ports.paperless-gpt}";
            };
            "syncthing.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString config.gathering-hub.ports.syncthing}/";
            };
            "zigbee2mqtt.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString config.gathering-hub.ports.zigbee2mqtt}";
            };
            "adguard.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString config.gathering-hub.ports.adguard}";
            };
            "vaultwarden.${domain}" = mkVhost {
              proxyPass = "http://127.0.0.1:${toString ports.vaultwarden}";
            };
          };
      };
      # PostgreSQL database for Home Assistant, Paperless, and Vaultwarden
      # (Note: the `vaultwarden` database & user are automatically provisioned via `services.vaultwarden.configurePostgres = true`)
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
        databases = [
          "hass"
          "paperless"
          "vaultwarden"
        ];
      };

      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        configurePostgres = true;
        domain = "vaultwarden.furahiya.nexus";
        environmentFile = config.sops.templates."vaultwarden.env".path;
        config = {
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = ports.vaultwarden;
          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
          ENABLE_WEBSOCKET = true;
        };
      };

      # Ensure the `/data/backups` directory exists.
      systemd.tmpfiles.rules = [
        "d ${backup-root-dir} 0755 root root -"
        "f /var/lib/hass/automations.yaml 0644 hass hass -"
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
            6666 # Tuya local discovery (unencrypted)
            6667 # Tuya local discovery (encrypted)
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

      nixpkgs.pkgs = pkgs;
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
            "users"
          ];
          home = "${base-home-dir}/${username}";
          shell = pkgs.zsh;
        };
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

      services.restic.backups =
        let
          resticSensors = import ../hass/sensors/restic.nix {
            inherit pkgs;
            mosquittoPort = config.gathering-hub.ports.mosquitto;
          };

          commonRestic = {
            initialize = true;
            passwordFile = config.sops.secrets."restic_password".path;

            paths = [
              # Machine-specific keys necessary to access sops.
              "/etc/ssh/ssh_host_ed25519_key"
              "/etc/ssh/ssh_host_ed25519_key.pub"
              "/etc/ssh/ssh_host_rsa_key"
              "/etc/ssh/ssh_host_rsa_key.pub"

              "/var/lib/nixos"
              "/var/lib/hass"
              "/var/lib/zigbee2mqtt"
              "/var/lib/paperless"
              "/var/lib/bitwarden_rs"
              "/var/lib/acme"
              "/var/lib/mosquitto"
              "/var/lib/private/AdGuardHome"

              "${backup-root-dir}/postgresql"
              "${backup-root-dir}/paperless"
              "/data/paperless/consume"
              config.gathering-hub.mediaDirs.syncthing-root

              # User home data
              "${base-home-dir}/${username}"
            ];

            exclude = [
              "${base-home-dir}/${username}/.cache"
              "${base-home-dir}/${username}/.config/syncthing/index*"
              "/var/lib/hass/.cache"
              "/var/lib/hass/*.log*"
              "/var/lib/hass/backups" # Ignore the encrypted hass backups, as restic backs up all those files too.
              "/var/lib/zigbee2mqtt/log"
              "/var/lib/paperless/log"
              "/var/lib/private/AdGuardHome/data/filters"
            ];

            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 5"
              "--keep-monthly 12"
              "--keep-yearly 3"
            ];
          };
        in
        {
          local =
            commonRestic
            // (resticSensors.mkHooks {
              name = "local";
              label = "Local";
              repo = "${backup-root-dir}/restic";
              icon = "mdi:harddisk";
            })
            // {
              timerConfig = {
                OnCalendar = "02:00";
                Persistent = true;
              };
            };

          gcs =
            commonRestic
            // (resticSensors.mkHooks {
              name = "gcs";
              label = "GCS";
              repo = "gs:gathering-hub-restic-8acc3d4:/";
              icon = "mdi:cloud-upload";
            })
            // {
              timerConfig = {
                OnCalendar = "03:00";
                Persistent = true;
              };
              environmentFile = "${pkgs.writeText "restic-gcs.env" ''
                GOOGLE_PROJECT_ID=robotic-circle-456517-e7
                GOOGLE_APPLICATION_CREDENTIALS=${config.sops.secrets."gcp_restic_credentials_json".path}
              ''}";
            };
        };

      system.stateVersion = "23.05";
    };
}
