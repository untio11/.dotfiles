{
  nixpkgs,
  self,
  overlays,
}:
let
  hostname = "Yukomo";
  pre-cfg = pkgs: {
    profile.prompt = "";
    programs = {
      git.settings = {
        user.email = "robin@skunk.team";
        credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
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
        profileExtra = "nxtm() { nx run-many -t test -p \"$1\" --parallel=1 --skip-nx-cache; };";
        dirHashes.void = "$HOME/Development/personal/.Void";
      };
      helix = {
        settings.theme = "carbonfox";
        extraPackages = [ pkgs.vscode-langservers-extracted ];
        languages.language-server.nixd.config.options.darwin.expr =
          "(builtins.getFlake \"${self}\").darwinConfigurations.\"${hostname}\".options";
      };
    };
    home.sessionVariables = {
      # So I can refer to this from the .Void project.
      OBSIDIAN_PERSONAL_VAULT = "$HOME/Documents/Obsidian/robin-personal-vault";
    };
    home.packages = with pkgs; [
      jq
      jiq # Interactive jq query editor
      nodejs_22
      zulu
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.beta
      ])
      python3
      awscli2
      azure-cli
      p7zip
      protobuf
      blueutil
    ];
  };
in
rec {
  inherit hostname;
  system = "aarch64-darwin";
  pkgs = import nixpkgs { inherit system overlays; };
  cfg = pre-cfg pkgs;
  zsh.extraImports = [ ../programs/zsh/impure.nix ];
  username = "robin.kneepkens";
  base-home-dir = "/Users";
  nix-darwin-configuration =
    { ... }:
    {
      users.users."${username}" = {
        home = "/Users/${username}";
        description = "Robin Kneepkens";
        ignoreShellProgramCheck = true; # Home Manager takes care of this.
      };
      system = {
        primaryUser = username;
        stateVersion = 6;
        defaults.smb.NetBIOSName = hostname;
      };
      security.pam.services.sudo_local = {
        touchIdAuth = true; # Enable touchID to authenticate sudo.
        reattach = true; # Fix so touchID sudo authentication also works in tmux.
      };

      # Setting this make Nix Darwin ignore all other options inside nixpkgs.
      # Just inherit the version of pkgs we configure via home-manager.
      nixpkgs.pkgs = pkgs;
      nix.enable = false; # Home manager takes care of this.

      homebrew = {
        enable = true; # Allow Nix Darwin to manage homebrew packages. Doesn't install homebrew for us though.
        # Global settings that apply when manually running homebrew:
        global = {
          brewfile = true; # Global `brew bundle` commands will refer to the bundle created by nix-darwin.
        };
        onActivation = {
          autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
          upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
          cleanup = "zap";
        };
        # brew install --cask ${name}
        casks = [
          "1password"
          "1password-cli"
          {
            name = "alacritty";
            args = {
              no_quarantine = true;
            };
          }
          "docker-desktop"
          {
            # Three finger tap for scroll-wheel click.
            name = "middleclick";
            args = {
              no_quarantine = true;
            };
          }
          "obsidian"
          "rectangle" # Windows-like keyboard shortcuts for resizing windows. Import other/RectangleConfig.json
          "karabiner-elements" # Rebinding caps-lock to backspace. See other/karabiner.json
          "syncthing-app"
          "visual-studio-code"
          "font-fira-mono-nerd-font"
          "font-hack-nerd-font"
          "localsend"
        ];
        # brew install ${name}
        brews = [
          "pulumi" # TODO: Uninstall when usr flake merges pulumi-bin fix.
          "duti" # Open markdown in chrome: `duti -s com.google.Chrome md`
        ];
        taps = [
          "pulumi/tap" # TODO: Probably also remove this when I remove global pulumi.
        ];
      };

      networking = {
        hostName = hostname;
        computerName = hostname;
      };

      time.timeZone = "Europe/Amsterdam";
    };
}
