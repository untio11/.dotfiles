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
    {
      imports = [
        ../services/adguard.nix
        ../services/backup.nix
        ../services/home-assistant.nix
        ../services/hosting.nix
        ../services/paperless.nix
        ../services/postgresql.nix
        ../services/zigbee2mqtt.nix
        ../services/syncthing.nix
      ];

      gathering-hub.domain = "furahiya.nexus";

      gathering-hub.ports = {
        adguard = 3000;
        home-assistant = 8123;
        mosquitto = 1883;
        paperless = 28981;
        paperless-gpt = 8081;
        zigbee2mqtt = 8080;
        syncthing = 8384;
        vaultwarden = 8222;
      };

      gathering-hub.mediaDirs = {
        syncthing-root = "/data/syncthing";
      };

      gathering-hub.backup = {
        root-dir = "/data/backups";
        # Move to `services/vaultwarden.nix` once extracted.
        paths = [
          "/var/lib/bitwarden_rs"
        ];
      };

      sops = {
        defaultSopsFile = ../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";

        # Host secrets
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets."untio11_gathering_hub_password_hash".neededForUsers = true;

        # Vaultwarden secrets
        secrets."vaultwarden_admin_token_hash" = { };
        templates."vaultwarden.env" = {
          content = ''
            ADMIN_TOKEN='${config.sops.placeholder.vaultwarden_admin_token_hash}'
          '';
        };
      };

      # TODO: Move to `services/vaultwarden.nix` including secrets definitions
      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        configurePostgres = true;
        domain = "vaultwarden.${config.gathering-hub.domain}";
        environmentFile = config.sops.templates."vaultwarden.env".path;
        config = {
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = config.gathering-hub.ports.vaultwarden;
          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
          ENABLE_WEBSOCKET = true;
        };
      };

      virtualisation.podman.enable = true;

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

      system.stateVersion = "23.05";
    };
}
