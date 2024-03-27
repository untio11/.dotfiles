{nixpkgs}: let
  cfg = {
    prompt = "";
    git = {
      userEmail = "robin@skunk.team";
    };
    zsh = {
      shellAliases.subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
      imports = [./impure.nix];
    };
  };
in rec {
  inherit cfg;
  system = "aarch64-darwin";
  pkgs = nixpkgs.legacyPackages.${system};
  username = "robin.kneepkens";
  base-home-dir = "/Users";
}
