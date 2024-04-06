{nixpkgs}: let
  pre-cfg = pkgs: {
    prompt = "";
    git = {
      userEmail = "robin@skunk.team";
      extraConfig.credential = {
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
    };
    zsh = {
      shellAliases = {
        subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
        # nxtm = "nxtm"; TODO: see profileExtra in zsh.nix
      };
      imports = [../features/zsh/impure.nix]; # TODO: make them proper modules!
    };
    helix.theme = "new_moon";
  };
in rec {
  cfg = pre-cfg pkgs;
  system = "aarch64-darwin";
  pkgs = nixpkgs.legacyPackages.${system};
  username = "robin.kneepkens";
  base-home-dir = "/Users";
}
