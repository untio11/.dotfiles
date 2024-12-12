# Machine Configs

This repo contains configurations for my different machines. This includes `home-manager` configs,
as well as NixOS configs.

## Home Manager

Clone this repo to `~/.config/home-manager`.

## NixOS Config

Currently only using this for my wsl box (pokke-village). Set up by having `/etc/nixos/flake.nix`
point to the home manager flake:
```nix
{
  description = "Just a wrapper around my core config.";

  inputs = {
    hm-flake.url = "git+file:/home/untio11/.config/home-manager";
  };

  outputs = { hm-flake, ... }: let
    hostName = "pokke-village";
  in {
    nixosConfigurations.${hostName} = hm-flake.nixosConfigurations.${hostName};
  };
}
```
**NOTE:** To build a new NixOS generation:
- Update the `nixos-wsl.nix` profile in the `home-manager` flake.
- Commit the changes.
- Update the flake in `/etc/nixos`.
- `sudo nixos-rebuild switch`
