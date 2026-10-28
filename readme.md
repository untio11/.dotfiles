# Machine Configs

This repository contains the Nix configurations for my machines, managed via a single Nix Flake (`home-manager`, `nix-darwin`, `NixOS`, and `sops-nix`).

## Machines & Profiles

| Hostname | OS / Platform | Profile File | User | Targets |
| :--- | :--- | :--- | :--- | :--- |
| **`Yukomo`** | macOS (`aarch64-darwin`) | [`profiles/work.nix`](./profiles/work.nix) | `robin.kneepkens` | `homeConfigurations."robin.kneepkens@Yukomo"`<br>`darwinConfigurations.Yukomo` |
| **`gathering-hub`** | NixOS (`x86_64-linux`) | [`profiles/nixos-native.nix`](./profiles/nixos-native.nix) | `untio11` | `homeConfigurations."untio11@gathering-hub"`<br>`nixosConfigurations.gathering-hub` |
| **`pokke-village`** | NixOS-WSL (`x86_64-linux`) | [`profiles/nixos-wsl.nix`](./profiles/nixos-wsl.nix) | `untio11` | `homeConfigurations."untio11@pokke-village"`<br>`nixosConfigurations.pokke-village` |

---

## Setup & Usage

Clone this repository to `~/.config/home-manager`:

```shell
git clone https://github.com/untio11/.dotfiles ~/.config/home-manager
cd ~/.config/home-manager
```

### 1. Home Manager (All Machines)

On a fresh system without `home-manager` installed, bootstrap your user profile directly from the flake:

```shell
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake .#${USER}@${HOSTNAME}
```

Once bootstrapped, switch generations using the `hswitch` shell alias (defined in [`util/hswitch.nix`](./util/hswitch.nix)) or directly via `home-manager`:

```shell
hswitch
# or explicitly:
home-manager switch --flake .#${USER}@${HOSTNAME}
```

### 2. macOS System Config (`nix-darwin` — `Yukomo`)

Bootstrap `nix-darwin` on a fresh Mac:

```shell
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake .#Yukomo
```

Apply subsequent changes:

```shell
sudo darwin-rebuild switch --flake .#Yukomo
```

### 3. NixOS System Config (`gathering-hub` & `pokke-village`)

Build and activate a NixOS configuration directly from `~/.config/home-manager`:

```shell
sudo nixos-rebuild switch --flake .#${HOSTNAME}
```

*(Note: On `pokke-village`, if `/etc/nixos/flake.nix` is still configured as a wrapper flake pointing to `git+file:/home/untio11/.config/home-manager`, prefer passing `--flake .#pokke-village` directly from this repository so you don't need to update a separate lockfile in `/etc/nixos`).*

---

## Secrets Management (`sops-nix`)

Secrets are encrypted in [`secrets/api-keys.yaml`](./secrets/api-keys.yaml) using `sops` and Age keys configured in [`.sops.yaml`](./.sops.yaml).

Both `Yukomo` (via `~/.config/sops/age/keys.txt`) and `gathering-hub` (via `/etc/ssh/ssh_host_ed25519_key` and `SOPS_AGE_KEY_CMD`) can decrypt and edit secrets directly:

```shell
sops secrets/api-keys.yaml
```

After editing secrets, apply the updated configuration on `gathering-hub` with `sudo nixos-rebuild switch --flake .#gathering-hub` so `sops-nix` updates `/run/secrets/*` and `/run/secrets-rendered/*`.

---

## Documentation

- [Gathering Hub — Backup & Disaster Recovery Runbook](./docs/gathering-hub-recovery.md)
