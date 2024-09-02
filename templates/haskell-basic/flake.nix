{
  description = "Following along with [Learn Haskell](https://learn-haskell.blog)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "aarch64-darwin";
      name = "blog-generator";
      pkgs = nixpkgs.legacyPackages.${system};
      package = pkgs.haskellPackages.callCabal2nix name ./. {};
    in 
    {
      defaultPackage.${system} = package;
      devShell.${system} = pkgs.mkShell {
        buildInputs = with pkgs.haskellPackages; [
          haskell-language-server
          ghcid
          cabal-install
        ];
        packages = with pkgs; [
          nil
        ];
      };
    };
}
