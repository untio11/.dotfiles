{
  nixpkgs,
  self,
  overlays,
}:
let
  hostname = "pokke-village";
  cfg = {
    profile.prompt = "";
    programs = {
      git.settings = {
        user.email = "robin.kneepkens@hotmail.com";
        credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      };
      jujutsu.settings = {
        user.email = "robin.kneepkens@hotmail.com";
      };
      zsh = {
        dirHashes.void = "$HOME/Development/.Void";
        shellAliases = {
          subl = "/mnt/c/Program\\ Files/Sublime\\ Text/subl.exe";
          explorer = "/mnt/c/Windows/explorer.exe";
        };
      };
      helix = {
        settings.theme = "flexoki_dark";
        languages.language-server.nixd.config.options.nixos.expr =
          "(builtins.getFlake \"${self}\").nixosConfigurations.\"${hostname}\".options";
      };
    };
    home.sessionVariables = {
      # So I can refer to this from the .Void project.
      OBSIDIAN_PERSONAL_VAULT = "/mnt/d/Obsidian/robin-personal-vault";
    };
  };
in
rec {
  # This should be a home manager module.
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system overlays; };
  inherit cfg;
  zsh.extraImports = [ ];
  username = "untio11";
  inherit hostname;
  base-home-dir = "/home";
  # NixOS Module
  nixos-configuration =
    { pkgs, ... }:
    {
      networking.hostName = hostname;
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

      time.timeZone = "Europe/Amsterdam";
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
