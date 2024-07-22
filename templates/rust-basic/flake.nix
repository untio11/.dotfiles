{
  description = "Model my accounting in Rust and manage it with Nix because why not.";

  inputs = {
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "rust-overlay/nixpkgs";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        code = pkgs.callPackage ./. {
          inherit pkgs;
        };
      in rec {
        packages = {
          app = code.app;
          default = packages.app;
        };

        devShells.default = import ./shell.nix {inherit pkgs;};
      }
    );
}
