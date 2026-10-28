# Gathering Hub — Backup & Disaster Recovery Runbook

This document describes the backup architecture of `gathering-hub` and how to restore individual files, databases, or the entire server in the event of data loss or a full SSD crash.

---

## 1. Backup Architecture Overview

Every night, three automated systemd timers run sequentially on `gathering-hub`:

| Time | Systemd Service | Description | Destination |
| :--- | :--- | :--- | :--- |
| **`01:15`** | `postgresqlBackup.service` | Creates consistent SQL dumps of the `hass` and `paperless` databases. | `/data/backups/postgresql/*.sql.gz` |
| **`01:30`** | `paperless-exporter.service` | Exports all Paperless documents, metadata, and database JSON. | `/data/backups/paperless/` |
| **`02:00`** | `restic-backups-local.service` | Creates an encrypted, deduplicated snapshot of all service state, secrets, dumps, and media, followed by `forget --prune`. | `/data/backups/restic/` |

### Where to find `restic_password`
The Restic repository at `/data/backups/restic` is encrypted with `restic_password`. If `gathering-hub` itself is unavailable, you can retrieve this password in **two places**:
1. **Your external password manager.**
2. **On `Yukomo` (MacBook) via `sops`:**
   ```bash
   cd ~/.config/home-manager
   sops -d secrets/api-keys.yaml | grep restic_password
   ```

---

## 2. Day-to-Day Usage & Restoring Individual Files (Scenario A)

On a running `gathering-hub`, NixOS provides the **`restic-local`** wrapper command. This wrapper automatically configures the repository path (`/data/backups/restic`) and password file (`/run/secrets/restic_password`).

### Inspecting Snapshots and Contents
```bash
# List all available snapshots:
sudo restic-local snapshots

# Search for a specific file across all snapshots:
sudo restic-local find "filename"

# List files inside the latest snapshot under a specific path:
sudo restic-local ls latest /var/lib/hass
```

### Restoring a Specific Directory or File
> [!TIP]
> When in doubt, restore to a temporary directory (`/tmp/restore`) first so you can inspect or diff files before overwriting live service data.

```bash
# Example: restore /var/lib/zigbee2mqtt from the latest snapshot into /tmp/restore
sudo restic-local restore latest \
  --include /var/lib/zigbee2mqtt \
  --target /tmp/restore
```
To restore a file or directory **directly to its original location**, use `--target /` (stop the corresponding systemd service first):
```bash
sudo systemctl stop zigbee2mqtt.service
sudo restic-local restore latest --include /var/lib/zigbee2mqtt --target /
sudo systemctl start zigbee2mqtt.service
```

### Browsing Snapshots Interactively (`restic mount`)
You can mount the entire Restic repository as a read-only FUSE filesystem:
```bash
sudo mkdir -p /mnt/restic
sudo restic-local mount /mnt/restic
```
In a second terminal, browse `/mnt/restic/snapshots/latest/...` and copy any files you need. Press `Ctrl+C` in the first terminal to unmount.

---

## 3. Full Bare-Metal Disaster Recovery After an SSD Crash (Scenario B)

Suppose the root SSD (`/`) of `gathering-hub` fails completely while the `/data` HDD (or an external copy of the Restic repository) remains intact.

> [!IMPORTANT] The Golden Ordering Rule for NixOS + `sops-nix`
> On a fresh OS installation, **restore `/etc/ssh/ssh_host_*` and `/var/lib/nixos` from Restic BEFORE activating the full NixOS flake**.
> 1. `/etc/ssh/ssh_host_ed25519_key` allows `sops-nix` to immediately decrypt `secrets/api-keys.yaml` without needing to re-key `.sops.yaml`.
> 2. `/var/lib/nixos` preserves the persistent NixOS UID/GID map so all system users (`hass`, `paperless`, `zigbee2mqtt`, `postgres`) receive the exact same numeric UIDs/GIDs as before the crash.

### Step 1: Install Base NixOS & Mount `/data`
1. Install a minimal NixOS system on the replacement SSD (or boot from a NixOS Live USB and mount the new root partition and `/data`).
2. Update the partition UUIDs under `fileSystems."/"` and `fileSystems."/boot"` (and `swapDevices`) in [`profiles/nixos-native.nix`](../profiles/nixos-native.nix) to match the new SSD partitions (check via `lsblk -f`).
3. Ensure the `/data` drive is mounted at `/data`:
   ```bash
   sudo mkdir -p /data
   sudo mount /dev/disk/by-uuid/776808a4-707d-40fd-baae-895785d0bd3a /data
   ```

### Step 2: Restore SSH Host Keys, `/var/lib/nixos`, and `/home/untio11`
Because `restic-local` and `sops-nix` are not active yet on a fresh system, run `restic` directly via `nix-shell` and enter **`restic_password`** when prompted:

```bash
sudo nix-shell -p restic --run "restic -r /data/backups/restic restore latest \
  --include /etc/ssh \
  --include /var/lib/nixos \
  --include /home/untio11 \
  --target /"
```

Verify that the SSH host key permissions are strict (`0600 root:root`):
```bash
sudo chown root:root /etc/ssh/ssh_host_*
sudo chmod 600 /etc/ssh/ssh_host_*_key
sudo chmod 644 /etc/ssh/ssh_host_*.pub
```

### Step 3: Restore Service State (`/var/lib/...`)
Restore the state directories for all stateful services before starting them:

```bash
sudo nix-shell -p restic --run "restic -r /data/backups/restic restore latest \
  --include /var/lib/hass \
  --include /var/lib/zigbee2mqtt \
  --include /var/lib/paperless \
  --include /var/lib/acme \
  --include /var/lib/mosquitto \
  --include /var/lib/private/AdGuardHome \
  --target /"
```

*(If the `/data` drive itself was also replaced and you are restoring from an external copy of the Restic repository, add `--include /data` to the command above).*

### Step 4: Deploy the NixOS Flake
With `/etc/ssh/ssh_host_ed25519_key`, `/var/lib/nixos`, and `/home/untio11/.config/home-manager` restored, deploy the complete server configuration in one step:

```bash
cd /home/untio11/.config/home-manager
sudo nixos-rebuild switch --flake .#gathering-hub
```
`sops-nix` will now automatically decrypt all secrets, restore the `untio11` password hash into `/etc/shadow`, and start all services along with the `restic-local` wrapper.

---

## 4. Restoring PostgreSQL Databases (`hass` & `paperless`)

After a fresh SSD installation, PostgreSQL initializes an empty database cluster in `/var/lib/postgresql`. Restore the latest SQL dumps from `/data/backups/postgresql` as follows:

### 1. Temporarily stop Home Assistant and Paperless
Ensure no services hold active connections to the databases:
```bash
sudo systemctl stop home-assistant.service paperless-scheduler.service paperless-consumer.service paperless-task-queue.service paperless-web.service
```

### 2. Restore the `hass` and `paperless` databases
```bash
# Inspect the available dumps in /data/backups/postgresql:
ls -lh /data/backups/postgresql/

# Restore the Home Assistant database:
sudo -u postgres psql -c "DROP DATABASE IF EXISTS hass; CREATE DATABASE hass OWNER hass;"
sudo -u postgres sh -c "zcat /data/backups/postgresql/hass.sql.gz | psql hass"

# Restore the Paperless database:
sudo -u postgres psql -c "DROP DATABASE IF EXISTS paperless; CREATE DATABASE paperless OWNER paperless;"
sudo -u postgres sh -c "zcat /data/backups/postgresql/paperless.sql.gz | psql paperless"
```

### 3. Start the services again
```bash
sudo systemctl start home-assistant.service paperless-scheduler.service paperless-consumer.service paperless-task-queue.service paperless-web.service
```

> [!NOTE] Alternative Paperless Restore (via `document_importer`)
> If there is ever an issue with the Paperless PostgreSQL dump, `/data/backups/paperless` also contains the daily native Paperless export. You can import it into a fresh Paperless database at any time using:
> ```bash
> sudo /var/lib/paperless/paperless-manage document_importer /data/backups/paperless
> ```
