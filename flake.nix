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

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    nixos-wsl = (import ./profiles/nixos-wsl.nix { inherit nixpkgs; });
    macos-skunk = (import ./profiles/work.nix { inherit nixpkgs; });
    profiles = [ nixos-wsl macos-skunk ];
  in {
    homeConfigurations.${macos-skunk.username} = with macos-skunk;
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [./home.nix];
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
        modules = [./home.nix];
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit inputs;
          profile = nixos-wsl;
        };
      };
  };
}
