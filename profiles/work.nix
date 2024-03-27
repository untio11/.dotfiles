{nixpkgs}: let
  cfg = {
    git = {
      userEmail = "robin@skunk.team";
    };
    zsh = {
      shellAliases.subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
    };
  };
in rec {
  inherit cfg;
  system = "aarch64-darwin";
  pkgs = nixpkgs.legacyPackages.${system};
  username = "robin.kneepkens";
  base-home-dir = "/Users";
}
