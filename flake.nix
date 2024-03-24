{
  description = "Home Manager configuration of robin.kneepkens";

	inputs = {
		# Specify the source of Home Manager and Nixpkgs.
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		nix-colors = {
			url = "github:misterio77/nix-colors";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		zsh-spinner = {
			url = "github:molovo/revolver";
			flake = false;
		};
	};

	outputs = { nixpkgs, home-manager, ... }@inputs:
		let
			nixos-wsl = rec {
				system = "x86_64-linux";
				pkgs = nixpkgs.legacyPackages.${system};
				# Profile: passing the pkgs when importing.
				username = "untio11";
				base-home-dir = "/home";
				git.extraConfig.credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
				zsh.shellAliases = {
		      subl = "/mnt/c/Program\\ Files/Sublime\\ Text/subl.exe";
				};
			};
			macos-skunk = rec {
				system = "aarch64-darwin";
				pkgs = nixpkgs.legacyPackages.${system};
				username = "robin.kneepkens";
				base-home-dir = "/Users";
				zsh.shellAliases = {
					subl = "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
				};
			};
		in {
			homeConfigurations.${macos-skunk.username} = with macos-skunk; 
			home-manager.lib.homeManagerConfiguration {
				inherit pkgs;
				# Specify your home configuration modules here, for example,
				# the path to your home.nix.
				modules = [ ./home.nix ];
				# Optionally use extraSpecialArgs
				# to pass through arguments to home.nix
				extraSpecialArgs = {
					inherit inputs;
					profile = macos-skunk;
				};
			};
			homeConfigurations.${nixos-wsl.username} = with nixos-wsl;
			home-manager.lib.homeManagerConfiguration {
				inherit pkgs;
				# Specify your home configuration modules here, for example,
				# the path to your home.nix.
				modules = [ ./home.nix ];
				# Optionally use extraSpecialArgs
				# to pass through arguments to home.nix
				extraSpecialArgs = {
					inherit inputs;
					profile = nixos-wsl;
				};
			};
		};
}
