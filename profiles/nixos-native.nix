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
    helix.theme = "base16_transparent";
  };
in rec {
  cfg = pre-cfg pkgs;
  system = "x86_64-linux";
  pkgs = import nixpkgs {inherit system;};
  username = "untio11";
  hostName = "gathering-hub";
  base-home-dir = "/home";
  nixos-configuration = {pkgs, ...}: {
    networking.hostName = hostName;
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = ["root" username];
    };

    environment.systemPackages = with pkgs; [
      git
      helix
      lsd
      bat
    ];

    programs = {
      zsh.enable = true;
    };

    users.users = {
      # untio11
      "${username}" = {
        home = "${base-home-dir}/${username}";
        shell = pkgs.zsh;
      };
    };

    system.stateVersion = "23.11";
  };
}
