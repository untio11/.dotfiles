# Machine Configs

This repo contains configurations for my different machines. This includes `home-manager` configs,
as well as NixOS configs.

## Home Manager

Clone this repo to `~/.config/home-manager`:
```shell
git clone https://github.com/untio11/.dotfiles ~/.config/home-manager
```

On a fresh system, you won't have `home-manager` installed to switch to the profile.

To run it directly from github:
```shell
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake .#${USER_NAME}@${HOSTNAME}
```

## NixOS Config

To build one of the NixOS configs in this flake (`gathering-hub`, `pokke-village`), use the following command:

```shell
sudo nixos-rebuild --extra-experimental-features "nix-command flakes" switch --flake .#${HOSTNAME}
```

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
