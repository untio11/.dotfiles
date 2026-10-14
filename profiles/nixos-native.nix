{
  nixpkgs,
  self,
  overlays,
}:
let
  hostname = "gathering-hub";
  pre-cfg = pkgs: {
    profile.prompt = ">";
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
      ports = {
        home-assistant = "8123";
        paperless = 28981;
        syncthing = "8384";
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
        ];
        config = {
          homeassistant = {
            name = "Astera";
            unit_system = "metric";
          };
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
            brother
            pyipp
          ];
      };

      # Enable mDNS so `gathering-hub.local` resolves to this machine's IP address
      # on LAN.
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true; # Open port 5353 for UDP mDNS traffic
        publish = {
          enable = true;
          addresses = true;
        };
      };
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        clientMaxBodySize = "100m"; # Allow uploading large documents for Paperless.
        # `gathering-hub.local`
        virtualHosts."${hostname}.local" = {
          default = true;
          # Home Assistant at root.
          locations."/" = {
            proxyPass = "http://127.0.0.1:${ports.home-assistant}";
            proxyWebsockets = true;
            extraConfig = "proxy_buffering off;";
          };
          # Paperless at `/paperless`
          locations."^~ /paperless" = {
            proxyPass = "http://127.0.0.1:${toString ports.paperless}";
            proxyWebsockets = true;
          };
          # Paperless Django Channels expect websockets at `/ws/` instead of `/paperless/ws/`.
          locations."^~ /paperless/ws/" = {
            proxyPass = "http://127.0.0.1:${toString ports.paperless}/ws/";
            proxyWebsockets = true;
          };
          # Syncthing UI at `/syncthing`.
          locations."^~ /syncthing/" = {
            proxyPass = "http://127.0.0.1:${ports.syncthing}/";
            proxyWebsockets = true;
            # Otherwise nginx will spit out connection-timed-out errors.
            extraConfig = ''
              proxy_read_timeout 120s;
              proxy_send_timeout 120s;
            '';
          };
        };
      };
      # PostgreSQL database for Home Assistant and Paperless
      services.postgresql = {
        enable = true;
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

      services.paperless = {
        enable = true;
        address = "127.0.0.1";
        port = ports.paperless;
        settings = {
          # Support running paperless at `gathering-hub.local/paperless` via mDNS.
          PAPERLESS_FORCE_SCRIPT_NAME = "/paperless";
          PAPERLESS_STATIC_URL = "/paperless/static/";
          PAPERLESS_URL = "http://${hostname}.local";
          # Languages for Optical Character Recognition (OCR).
          PAPERLESS_OCR_LANGUAGE = "eng+nld";
          PAPERLESS_TIME_ZONE = "Europe/Amsterdam";
          # Database Config
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "/run/postgresql";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBUSER = "paperless";
        };
        exporter = {
          enable = false;
          # TODO: Configure backups
          onCalendar = "weekly";
        };

      };

      services.syncthing = {
        enable = true;
        # Makes sure the files managed by syncthing belong to my user account.
        user = username;
        group = "users";
        dataDir = "${base-home-dir}/${username}/syncthing-default";
        configDir = "${base-home-dir}/${username}/.config/syncthing";
        openDefaultPorts = true;
        guiAddress = "127.0.0.1:${ports.syncthing}"; # Localhost only; Nginx will expose it
        settings.gui.insecureSkipHostcheck = true; # For reverse proxy support.
      };

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
        inherit colors;
        keyMap = "dvorak";
        earlySetup = true;
        packages = [
          pkgs.terminus_font
        ];
        font = "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";
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
            80 # HTTP for nginx reverse proxy
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
          description = "Robin Kneepkens";
          extraGroups = [
            "networkmanager"
            "wheel"
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
          device = "/dev/disk/by-uuid/8d57c9c0-ac30-47bd-b659-3b9dc4b5de29"; # SSD
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/015C-82D5"; # SSD
          fsType = "vfat";
        };
        # "/data" = {
        #   device = "/dev/disk/by-uuid/776808a4-707d-40fd-baae-8957850bd3a"; # HDD
        #   fsType = "ext4";
        # };
      };
      swapDevices = [
        { device = "/dev/disk/by-uuid/9025aa85-720d-46f7-a7d6-d0cd15793355"; } # SSD
      ];

      system.stateVersion = "23.05";
    };
}
