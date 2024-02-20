{ config, pkgs, ... }:

{
	programs.direnv = {
		enable = true;
		nix-direnv.enable = true;
		enableZshIntegration = true; # I think this might not be working yet, since I don't manage zsh through home-manager yet
	};
}
