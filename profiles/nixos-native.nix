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
        };
        extraPackages =
          python3Packages: with python3Packages; [
            psycopg2 # postgresql support
            pyatv
            getmac
          ];
      };
      services.nginx = {
        enable = false;
        recommendedProxySettings = true;
        virtualHosts = {
          # Home Assistant reverse proxy.
          "home-assistant.nexus" = {
            extraConfig = "proxy_buffering off;";
            locations."/" = {
              proxyPass = "http://[::1]:8123";
              proxyWebsockets = true;
            };
          };
        };
      };
      # PostgreSQL database for Home Assistant
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "hass" ];
        ensureUsers = [
          {
            name = "hass";
            ensureDBOwnership = true;
          }
        ];
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
            22
            80
            443
            8123 # Home Assistant default port
            5432 # PostgreSQL port
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
