{ nixpkgs, wslpath }:
let
  cfg = {
    profile.prompt = "";
    programs = {
      git = {
        extraConfig.credential = {
          helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
        };
        userEmail = "robin.kneepkens@hotmail.com";
      };
      jujutsu.settings = {
        user.email = "robin.kneepkens@hotmail.com";
      };
      zsh = {
        shellAliases = {
          subl = "/mnt/c/Program\\ Files/Sublime\\ Text/subl.exe";
          explorer = "/mnt/c/Windows/explorer.exe";
        };
        profileExtra = ''
          # Broken: expects an installation of php in /usr/bin. 
          wslpath() { ${wslpath}/wslpath $@ }
        '';
      };
      helix.settings.theme = "flexoki_dark";
    };
  };
in
rec {
  # This should be a home manager module.
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system; };
  inherit cfg;
  zsh.extraImports = [ ];
  username = "untio11";
  hostName = "pokke-village";
  base-home-dir = "/home";
  # NixOS Module
  nixos-configuration =
    { pkgs, ... }:
    {
      networking.hostName = hostName;
      wsl = {
        enable = true;
        defaultUser = username;
        startMenuLaunchers = true;
      };

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ username ];
      };

      environment.systemPackages = with pkgs; [
        helix
        lsd
        bat
        git
        wget
      ];

      programs = {
        nix-ld.enable = true;
        zsh.enable = true;
        direnv = {
          enable = true;
          enableZshIntegration = true;
        };
      };

      users.users = {
        root = {
          # Otherwise I get an error when logging in as root.
          extraGroups = [ "root" ];
        };
        # untio11
        "${username}" = {
          home = "${base-home-dir}/${username}";
          shell = pkgs.zsh;
        };
      };

      system.stateVersion = "23.11";
    };
}
