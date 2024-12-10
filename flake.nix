{
  description = "Configurations for my various machines.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # For home desktop wsl system.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    # For animated spinner in hswitch command.
    revolver = {
      url = "github:molovo/revolver";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    nixos-wsl = import ./profiles/nixos-wsl.nix {inherit nixpkgs;};
    macos-skunk = import ./profiles/work.nix {inherit nixpkgs;};
  in {
    # Work macbook. Home manager only.
    homeConfigurations.${macos-skunk.username} = with macos-skunk;
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix];
        extraSpecialArgs = {
          inherit inputs;
          profile = macos-skunk;
        };
      };
    # Home desktop wsl. Home manager.
    homeConfigurations.${nixos-wsl.username} = with nixos-wsl;
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix];
        extraSpecialArgs = {
          inherit inputs;
          profile = nixos-wsl;
        };
      };
    # Home desktop wsl. NixOS config.
    nixosConfigurations.nixos = with nixos-wsl;
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {nix.registry.nixpkgs.flake = nixpkgs;}
          inputs.nixos-wsl.nixosModules.wsl
          nixos-configuration
        ];
      };
    templates = {
      rust-basic = {
        path = ./templates/rust-basic;
        description = "Basic cargo/nix rust project, ready to go.";
      };
    };
  };
}
