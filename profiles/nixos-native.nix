{nixpkgs}: let
  pre-cfg = pkgs: {
    prompt = "󱏿";
    git = {
      extraConfig.credential = {
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
        credentialStore = "gpg";
      };
      userEmail = "robin.kneepkens@hotmail.com";
    };
    zsh = {
      shellAliases = {};
      imports = [];
    };
    helix.theme = "penumbra+";
  };
in rec {
  cfg = pre-cfg pkgs;
  system = "x86_64-linux";
  pkgs = import nixpkgs {inherit system;};
  username = "untio11";
  hostName = "gathering-hub";
  base-home-dir = "/home";
  nixos-configuration = {
    config,
    lib,
    pkgs,
    ...
  }: {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      kernelModules = ["kvm-intel"];
      initrd.availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    networking = {
      inherit hostName;
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
        trusted-users = [username];
      };
    };
    console.keyMap = "dvorak";
    environment.systemPackages = with pkgs; [
      git
      helix
      lsd
      bat
      zsh
      pass
      tmux
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
        extraGroups = ["networkmanager" "wheel"];
        home = "${base-home-dir}/${username}";
        shell = pkgs.zsh;
      };
    };

    # Locale/internationalisation properties.
    time.timeZone = "Europe/Amsterdam";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };

    fileSystems = {
      "/" = {
        device = "/dev/sda2"; # SSD
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/sda1"; # SSD
        fsType = "vfat";
      };
      "/data" = {
        device = "/dev/sdb1"; # HDD
        fsType = "ext4";
      };
    };
    swapDevices = [
      {device = "/dev/sda3";} # SSD
    ];

    system.stateVersion = "23.05";
  };
}
