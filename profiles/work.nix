{nixpkgs}: let
  pre-cfg = pkgs: {
    profile.prompt = "";
    programs = {
      git = {
        userEmail = "robin@skunk.team";
        extraConfig.credential = {
          helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
        };
      };
      jujutsu.settings = {
        user.email = "robin@skunk.team";
      };
      zsh = {
        shellAliases = {
          subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
        };
        profileExtra = "nxtm() { nx run-many -t test -p \"$1\" --parallel=1 --skip-nx-cache; };";
      };
      helix.settings.theme = "bogster";
      direnv.stdlib = ''
        source_up_if_exists .envrc.usr-flake
      '';
    };
    home.packages = with pkgs; [
      jq
      nodejs_20
      zulu
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.beta
      ])
      python311
      awscli2
      azure-cli
      p7zip
      protobuf
    ];
  };
in rec {
  system = "aarch64-darwin";
  pkgs = nixpkgs.legacyPackages.${system};
  cfg = pre-cfg pkgs;
  zsh.extraImports = [../programs/zsh/impure.nix];
  username = "robin.kneepkens";
  base-home-dir = "/Users";
}
