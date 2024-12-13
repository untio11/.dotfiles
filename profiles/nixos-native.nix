{nixpkgs}: let
  pre-cfg = pkgs: {
    profile.prompt = "󱏿";
    programs.git = {
      extraConfig.credential = {
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
        credentialStore = "gpg";
      };
      userEmail = "robin.kneepkens@hotmail.com";
    };
    programs.helix.settings.theme = "penumbra+";
  };
in rec {
  system = "x86_64-linux";
  pkgs = import nixpkgs {inherit system;};
  cfg = pre-cfg pkgs;
  zsh.extraImports = [];
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
        device = "/dev/disk/by-uuid/8d57c9c0-ac30-47bd-b659-3b9dc4b5de29"; # SSD
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/015C-82D5"; # SSD
        fsType = "vfat";
      };
      "/data" = {
        device = "/dev/disk/by-uuid/776808a4-707d-40fd-baae-8957850bd3a"; # HDD
        fsType = "ext4";
      };
    };
    swapDevices = [
      {device = "/dev/disk/by-uuid/9025aa85-720d-46f7-a7d6-d0cd15793355";} # SSD
    ];

    system.stateVersion = "23.05";
  };
}
