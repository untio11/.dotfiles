{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "untio11";
  home.homeDirectory = "/home/untio11";
  home.sessionVariables = {
    COLORTERM = "truecolor";
    EDITOR = "hx";
  };

  imports = [
    # Enable nix-colors.
    inputs.nix-colors.homeManagerModule 

    # Import programs with their configuration
    ./features/lsd.nix
    ./features/git.nix
    ./features/tmux.nix
    ./features/direnv.nix
    ./features/helix.nix
    ./features/zsh/zsh.nix
  ];

  colorScheme = (import ./global/colorschemes/default-terminal.nix);
  
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    bat # Not really worth more config yet
    fzf
    jq
    wget
    gh
  ];
   
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
