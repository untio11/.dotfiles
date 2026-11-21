{
  nixpkgs,
  overlays,
}:
let
  hostname = "Seliana";
  username = "untio11";
  base-home-dir = "/home";
  hm = "${base-home-dir}/${username}/.config/home-manager";
  pre-cfg = pkgs: {
    profile.prompt = ">";
    # TODO:
    # home.sessionVariables = {
    #   # So I can use `sudo sops edit` from gathering hub.
    #   SOPS_AGE_KEY_CMD = "sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key";
    # };
    programs.git.settings = {
      user.email = "robin.kneepkens@hotmail.com";
      credential = {
        helper = "${pkgs.gh}/bin/gh auth git-credential";
      };
    };
    programs.jujutsu.settings = {
      user.email = "robin.kneepkens@hotmail.com";
    };
    programs.helix = {
      settings.theme = "flexoki_dark";
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
      lib,
      ...
    }:
    {
      imports = [
        ./hardware-configuration.nix
        ./disko.nix
      ];

      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";

        # TODO: Host secrets
        # age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        # secrets."untio11_gathering_hub_password_hash".neededForUsers = true;
      };

      services.xserver.xkb = {
        layout = "us";
        variant = "dvorak";
      };
      services.getty.autologinUser = username;
      services.kmscon = {
        enable = true;
        useXkbConfig = true;
        extraOptions = "--term xterm-256color";
        config = {
          hwaccel = true;
          font-name = "FiraCode Nerd Font Mono";
          font-size = 30;
        };
      };
      fonts.packages = [
        pkgs.nerd-fonts.fira-code
      ];
      console = {
        keyMap = "dvorak";
        earlySetup = true;
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

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      boot = {
        supportedFilesystems = [ "zfs" ];
        kernelParams = [
          "zfs.zfs_arc_max=2147483648" # 2 GiB ARC (RAM Cache) cap.
          # For Plymouth
          "quiet"
          "splash"
        ];
        loader = {
          systemd-boot.enable = true; # Use f11 for bios-based os selection
          grub = {
            # Get a nice boot menu where I can choose windows/nixos
            enable = false;
            device = "nodev";
            efiSupport = true;
            useOSProber = true;
          };
          efi.canTouchEfiVariables = true;
        };
        initrd.kernelModules = [ "amdgpu" ];
        plymouth.enable = true;
      };

      networking = {
        hostId = "1fbbe0b5"; # Randomly generated during install
        hostName = hostname;
        useDHCP = lib.mkDefault true;
        networkmanager.enable = true;
        firewall.enable = true;
      };

      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ username ];
          # TODO: garbage cleaning
        };
      };
      environment.systemPackages = with pkgs; [
        git
        helix
        lsd
        bat
        zsh
        tmux
      ];

      nixpkgs.pkgs = pkgs;
      programs = {
        zsh.enable = true;
      };

      users.users = {
        # untio11
        "${username}" = {
          isNormalUser = true;
          # TODO: password via sops
          # hashedPasswordFile = config.sops.secrets."untio11_gathering_hub_password_hash".path;
          initialPassword = "temp";
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

      # Because of Windows dual-boot.
      time.hardwareClockInLocalTime = true;

      services.zfs.autoScrub.enable = true;
      fileSystems."/persist".neededForBoot = true;

      preservation = {
        enable = true;
        preserveAt."/persist" = {
          directories = [
            "/var/lib/nixos"
            "/var/log"
            "/etc/NetworkManager/system-connections"
            "/var/lib/bluetooth"
          ];
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
          ];
          users."${username}".directories = [
            ".config/home-manager"
            ".cache"
          ];
        };
      };

      # Preservation/Impermanence: wipe before boot.
      # boot.initrd.systemd.services.rollback = {
      #   description = "Rollback ZFS root dataset to blank snapshot";
      #   wantedBy = ["initrd.target"];
      #   after = ["zfs-import-zroot.service"];
      #   before = ["sysroot.mount"];
      #   path = [ pkgs.zfs ];
      #   unitConfig.DefaultDependencies = "no";
      #   serviceConfig.Type = "oneshot";
      #   script = "zfs rollback -r zroot/local/root@blank";
      # };

      system.stateVersion = "26.11"; # Did you read the comment?
    };
}
