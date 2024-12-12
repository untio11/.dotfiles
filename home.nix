{
  config,
  pkgs,
  inputs,
  profile,
  ...
}: let
  # Note: the `xdg.*Home` properties use `home.homeDirectory` as a base.
  hm = "${config.xdg.configHome}/home-manager";
in {
  home = with profile; {
    inherit username;
    homeDirectory = "${base-home-dir}/${username}";
    sessionVariables = {
      HM_HOME = hm;
    };
    shellAliases = {
      home = "cd ${hm}";
    };
    packages = with pkgs; [
      # Personal packages
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.dejavu-sans-mono
      bat
      fzf
      cowsay
      neofetch
      ov # No nice home manager module with options, so config file manually placed by ./programs/ov.nix
      devenv

      # SkunkTeam/usr development
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
    stateVersion = "23.05";
  };

  nix = {
    package = pkgs.nix; # Use the Nix version as pinned by the home-manager flake.
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    settings = {
      max-jobs = "auto"; # Set the maximum allowed number of parallel builders equal to #cores on host machine.
      fallback = true; # Automatically fall back to locally building if binary substitution fails.
      trusted-users = ["untio11"]; # So devenv can manage cachix cache for me.
      experimental-features = [
        "nix-command" # Enable new-style nix (nix <subcommand> instead of nix-subcommand). Necessary for flakes.
        "flakes" # The MVP
        "auto-allocate-uids" # So builds stop giving warnings?
      ];
    };
  };

  imports = [
    # Enable nix-colors.
    inputs.nix-colors.homeManagerModule

    # Import programs with their configuration
    ./programs/lsd.nix
    ./programs/git.nix
    ./programs/alacritty.nix
    ./programs/tmux.nix
    ./programs/direnv.nix
    ./programs/helix.nix
    ./programs/zsh/zsh.nix
    ./programs/ov.nix
    ./util/hswitch.nix
  ];

  # Expose the `nix-colors` color scheme under `config.colorScheme`.
  colorScheme = import ./global/colorschemes/default-terminal.nix;
  # Enable Home Manager to install user fonts. Added in `home.packages`.
  fonts.fontconfig.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
