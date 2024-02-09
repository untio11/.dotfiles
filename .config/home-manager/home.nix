{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "robin.kneepkens";
  home.homeDirectory = "/Users/robin.kneepkens";

  imports = [
    # Enable nix-colors.
    inputs.nix-colors.homeManagerModule 

    # Import programs with their configuration
    ./features/lsd.nix
    ./features/git.nix
    ./features/alacritty.nix
    ./features/tmux.nix
	./features/nvim/nvim.nix
	# ./features/zsh/zsh.nix # Currently unstable, don't want to worry about that now.
  ];

  colorScheme = (import ./global/colorschemes/default-terminal.nix);

  # Enable Home Manager to install user fonts. Added in home.packages.
  fonts.fontconfig.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "DejaVuSansMono" ]; })
    fswatch
  ];
  
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
  
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
