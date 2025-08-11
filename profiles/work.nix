{ nixpkgs }:
let
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
        aliases = {
          # TODO: Some script/alias to automate checking out for review.
          # Needs to:
          # - checkout a branch/bookmark: jj new <bookmark>
          # - start tracking it: jj b track <bookmark>
          # - start tracking in git: git branch --set-upstream-to=origin/<bookmark> <bookmark>
          # - check out the branch in git: git checkout <bookmark>
          #
          # After jj starts tracking, we can use the `jj git_branch` alias.
        };
      };
      zsh = {
        shellAliases = {
          subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
        };
        profileExtra = "nxtm() { nx run-many -t test -p \"$1\" --parallel=1 --skip-nx-cache; };";
      };
      helix.settings.theme = "carbonfox";
    };
    home.packages = with pkgs; [
      jq
      nodejs_22
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
in
rec {
  system = "aarch64-darwin";
  pkgs = nixpkgs.legacyPackages.${system};
  cfg = pre-cfg pkgs;
  zsh.extraImports = [ ../programs/zsh/impure.nix ];
  username = "robin.kneepkens";
  base-home-dir = "/Users";
}
