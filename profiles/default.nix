{ ... }@inputs:
{
  imports = builtins.map import [
    ./nixos-wsl.nix
    ./work.nix
  ];
}
