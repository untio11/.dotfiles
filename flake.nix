{
  description = "Configurations for my various machines.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl = {
      # NixOS WSL compatibility. For home desktop WSL system.
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      # Manage dotfiles/user profiles via Nix.
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      # Manage MacOS via Nix.
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    revolver = {
      # For animated spinner in hswitch command.
      url = "github:molovo/revolver";
      flake = false;
    };
    # Manage secrets with sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      self,
      ...
    }@inputs:
    let
      overlays = [ ];
      nixos-wsl = import ./profiles/nixos-wsl.nix {
        inherit nixpkgs self overlays;
      };
      macos-skunk = import ./profiles/work.nix { inherit nixpkgs self overlays; };
      nixos-native = import ./profiles/nixos-native.nix { inherit nixpkgs self overlays; };
    in
    {
      # Work macbook. Home manager.
      # Bootstrap: nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake .#robin.kneepkens
      # home-manager switch --flake .#robin.kneepkens
      homeConfigurations."${macos-skunk.username}@${macos-skunk.hostname}" =
        with macos-skunk;
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit inputs self;
            profile = macos-skunk;
          };
        };
      # Work macbook. Nix Darwin.
      # Bootstrap: sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake .#Yukomo
      # Normal: sudo darwin-rebuild switch --flake .#Yukomo
      darwinConfigurations.${macos-skunk.hostname} =
        with macos-skunk;
        nix-darwin.lib.darwinSystem {
          modules = [
            nix-darwin-configuration
            inputs.sops-nix.darwinModules.sops
          ];
        };
      # Home desktop wsl. Home manager.
      # Bootstrap: nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake .#untio11@pokke-village
      homeConfigurations."${nixos-wsl.username}@${nixos-wsl.hostname}" =
        with nixos-wsl;
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit inputs self;
            profile = nixos-wsl;
          };
        };
      # Home server. Home manager config.
      # nix run home-manager/master -- switch --flake .#untio11@gathering-hub
      homeConfigurations."${nixos-native.username}@${nixos-native.hostname}" =
        with nixos-native;
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit inputs self;
            profile = nixos-native;
          };
        };
      # Home desktop wsl. NixOS config.
      # Normal: sudo nixos-rebuild switch --flake .#pokke-village
      nixosConfigurations.${nixos-wsl.hostname} =
        with nixos-wsl;
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nix.registry.nixpkgs.flake = nixpkgs; }
            inputs.nixos-wsl.nixosModules.wsl
            nixos-configuration
          ];
        };
      # Home server. NixOS config.
      # sudo nixos-rebuild switch --flake .#gathering-hub
      nixosConfigurations.${nixos-native.hostname} =
        with nixos-native;
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
            }
            nixos-configuration
            inputs.sops-nix.nixosModules.sops
          ];
        };
      templates = {
        rust-basic = {
          path = ./templates/rust-basic;
          description = "Basic cargo/nix rust project, ready to go.";
        };
      };

      # DevShell for managing GCP infrastructure via Pulumi (in ./pulumi)
      devShells =
        let
          mkPulumiShell =
            pkgs:
            pkgs.mkShell {
              name = "dotfiles-pulumi";
              packages = with pkgs; [
                nodejs_24
                pulumi
                pulumiPackages.pulumi-nodejs
                (google-cloud-sdk.withExtraComponents [
                  google-cloud-sdk.components.beta
                ])
                sops
                jq
              ];
              env = {
                PROJECT_ID = "robotic-circle-456517-e7";
                GOOGLE_PROJECT = "robotic-circle-456517-e7";
                CLOUDSDK_CORE_PROJECT = "robotic-circle-456517-e7";
                PULUMI_BACKEND_URL = "file://./state";
                PULUMI_DIY_BACKEND_DISABLE_CHECKPOINT_BACKUPS = "true";
              };
            };
        in
        {
          ${macos-skunk.system}.default = mkPulumiShell macos-skunk.pkgs;
          ${nixos-native.system}.default = mkPulumiShell nixos-native.pkgs;
        };
    };
}
