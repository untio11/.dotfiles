{nixpkgs}: let
  cfg = {
    prompt = "";
    git = {
      userEmail = "robin@skunk.team";
    };
    zsh = {
      shellAliases = {
        subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
        # nxtm = "nxtm"; TODO: see profileExtra in zsh.nix
      };
      imports = [../features/zsh/impure.nix]; # TODO: make them proper modules!
    };
  };
in rec {
  inherit cfg;
  system = "aarch64-darwin";
  pkgs = nixpkgs.legacyPackages.${system};
  username = "robin.kneepkens";
  base-home-dir = "/Users";
}
