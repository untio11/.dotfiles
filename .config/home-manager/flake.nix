{
  description = "Home Manager configuration of robin.kneepkens";

	inputs = {
		# Specify the source of Home Manager and Nixpkgs.
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		nix-colors.url = "github:misterio77/nix-colors";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		plugin-monokai-pro = {
			url = "github:loctvl842/monokai-pro.nvim";
			flake = false;
		};
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { nixpkgs, home-manager, flake-utils, ... }@inputs:
		let
			system = "aarch64-darwin";
			pkgs = nixpkgs.legacyPackages.${system};
		in {
			homeConfigurations."robin.kneepkens" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;
				# Specify your home configuration modules here, for example,
				# the path to your home.nix.
				modules = [ ./home.nix ];
				# Optionally use extraSpecialArgs
				# to pass through arguments to home.nix
				extraSpecialArgs = {
					inherit inputs;
				};
			};
		};
}
