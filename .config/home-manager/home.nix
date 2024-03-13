{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "robin.kneepkens";
  home.homeDirectory = "/Users/robin.kneepkens";
  nix = {
    package = pkgs.nix; # Use the Nix version as pinned by the home-manager flake.
    settings = {
      max-jobs = "auto"; # Set the maximum allowed number of parallel builders equal to #cores on host machine.
      fallback = true; # Automatically fall back to locally building if binary substitution fails.
      experimental-features = [ 
        "nix-command" # Enable new-style nix (nix <subcommand> instead of nix-subcommand). Necessary for flakes.
        "flakes" # The MVP
        "auto-allocate-uids" # So builds stop giving warnings?
      ];
      auto-allocate-uids = true;
    };
  };

  imports = [
    # Enable nix-colors.
    inputs.nix-colors.homeManagerModule 

    # Import programs with their configuration
    ./features/lsd.nix
    ./features/git.nix
    ./features/alacritty.nix
    ./features/tmux.nix
    ./features/direnv.nix
    ./features/helix.nix
    ./features/zsh/zsh.nix
  ];

  colorScheme = (import ./global/colorschemes/default-terminal.nix);

  # Enable Home Manager to install user fonts. Added in home.packages.
  fonts.fontconfig.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Personal packages
    (nerdfonts.override { fonts = [ "DejaVuSansMono" ]; })
    bat # Not really worth more config yet
    fzf
    cowsay
    neofetch
    manix # Search nix/nixos/home-manager options

    # SkunkTeam/usr development
    jq
    nodejs_20
    zulu
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.beta
    ])
    awscli2
    azure-cli
    p7zip
  ];
   
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
