{nixpkgs}: let
  cfg = {
    prompt = "";
    git = {
      extraConfig.credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      userEmail = "robin.kneepkens@hotmail.com";
    };
    zsh = {
      shellAliases.subl = "/mnt/c/Program\\ Files/Sublime\\ Text/subl.exe";
      imports = [];
    };
    helix.theme = "base16_transparent";
  };
in rec {
  inherit cfg;
  system = "x86_64-linux";
  pkgs = import nixpkgs {inherit system;};
  username = "untio11";
  base-home-dir = "/home";
}
