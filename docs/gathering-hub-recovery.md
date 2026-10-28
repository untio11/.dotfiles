# Gathering Hub — Backup & Disaster Recovery Draaiboek

Dit document beschrijft hoe de backups van `gathering-hub` zijn ingericht en hoe je (onderdelen van) de server herstelt bij dataverlies of een volledige SSD-crash.

---

## 1. Overzicht van de Backup-architectuur

Elke nacht draaien er op `gathering-hub` drie geautomatiseerde stappen achter elkaar:

| Tijdstip | Systemd Service | Wat doet het? | Locatie |
| :--- | :--- | :--- | :--- |
| **`01:15`** | `postgresqlBackup.service` | Maakt consistente SQL-dumps van de `hass` en `paperless` databases. | `/data/backups/postgresql/*.sql.gz` |
| **`01:30`** | `paperless-exporter.service` | Exporteert alle Paperless-documenten, metadata en database-JSON. | `/data/backups/paperless/` |
| **`02:00`** | `restic-backups-local.service` | Maakt een versleuteld, gededupliceerd snapshot van alle state, secrets, dumps en media, gevolgd door `forget --prune`. | `/data/backups/restic/` |

### Waar vind je het `restic_password`?
De Restic-repository op `/data/backups/restic` is versleuteld met `restic_password`. Je kunt dit wachtwoord op **twee plekken** terugvinden als `gathering-hub` zelf niet beschikbaar is:
1. **In je externe password manager.**
2. **Op `Yukomo` (MacBook) via `sops`:**
   ```bash
   cd ~/.config/home-manager
   sops -d secrets/api-keys.yaml | grep restic_password
   ```

---

## 2. Dagelijks gebruik & Losse bestanden herstellen (Scenario A)

Op een draaiende `gathering-hub` heeft NixOS een wrapper-commando **`restic-local`** aangemaakt. Dit commando vult automatisch het repository-pad (`/data/backups/restic`) én het wachtwoord (`/run/secrets/restic_password`) in.

### Snapshots en inhoud bekijken
```bash
# Toon alle aanwezige snapshots:
sudo restic-local snapshots

# Zoek een specifiek bestand door alle snapshots heen:
sudo restic-local find "naam-van-bestand"

# Bekijk de bestanden in het nieuwste snapshot op een specifiek pad:
sudo restic-local ls latest /var/lib/hass
```

### Één specifieke map of bestand terugzetten
> [!TIP]
> Restore bij twijfel eerst naar een tijdelijke map (`/tmp/restore`) zodat je bestanden rustig kunt bekijken of vergelijken voordat je live data overschrijft.

```bash
# Voorbeeld: herstel /var/lib/zigbee2mqtt uit het laatste snapshot naar /tmp/restore
sudo restic-local restore latest \
  --include /var/lib/zigbee2mqtt \
  --target /tmp/restore
```
Wil je een bestand of map **direct op de originele plek** terugzetten? Gebruik dan `--target /` (stop bij een service eerst even de bijbehorende systemd-unit):
```bash
sudo systemctl stop zigbee2mqtt.service
sudo restic-local restore latest --include /var/lib/zigbee2mqtt --target /
sudo systemctl start zigbee2mqtt.service
```

### Interactief door al je snapshots bladeren (`restic mount`)
Je kunt de hele Restic-repository tijdelijk als een leesbare map mounten:
```bash
sudo mkdir -p /mnt/restic
sudo restic-local mount /mnt/restic
```
In een tweede terminal kun je nu gewoon met `cd /mnt/restic/snapshots/latest/...` door al je backups wandelen en bestanden kopiëren. Sluit af met `Ctrl+C` in het eerste venster.

---

## 3. Volledige Disaster Recovery bij een SSD-crash (Scenario B)

Stel dat de systeemschijf (SSD `/`) van `gathering-hub` volledig kapotgaat, terwijl je `/data` HDD (of een kopie van de Restic-repo) nog intact is.

> [!IMPORTANT] De Gouden Volgorde voor NixOS + `sops-nix`
> Zet bij een herinstallatie **eerst `/etc/ssh/ssh_host_*` en `/var/lib/nixos` terug uit Restic vóórdat je de volledige NixOS-flake activeert**.
> 1. `/etc/ssh/ssh_host_ed25519_key` zorgt ervoor dat `sops-nix` direct je `secrets/api-keys.yaml` kan ontsleutelen.
> 2. `/var/lib/nixos` zorgt ervoor dat NixOS aan alle systeemgebruikers (`hass`, `paperless`, `zigbee2mqtt`, `postgres`) exact dezelfde UID/GID-nummers toewijst als vóór de crash, zodat alle bestandsrechten direct kloppen.

### Stap 1: Basis NixOS installeren & `/data` mounten
1. Installeer een minimale NixOS op de nieuwe SSD (of start op vanaf de NixOS Live-USB en mount de nieuwe root-partitie en `/data`).
2. Pas in [`profiles/nixos-native.nix`](../profiles/nixos-native.nix) onder `fileSystems."/"` en `fileSystems."/boot"` (en `swapDevices`) de UUID's aan naar de UUID's van de nieuwe SSD-partities (te vinden met `lsblk -f`).
3. Zorg dat de `/data` schijf gemount is op `/data`:
   ```bash
   sudo mkdir -p /data
   sudo mount /dev/disk/by-uuid/776808a4-707d-40fd-baae-895785d0bd3a /data
   ```

### Stap 2: SSH Host Keys, `/var/lib/nixos` en `/home/untio11` herstellen
Omdat `restic-local` en `sops-nix` op een vers systeem nog niet actief zijn, roepen we `restic` hier eenmalig direct aan via `nix-shell` en typen we het **`restic_password`** handmatig in:

```bash
sudo nix-shell -p restic --run "restic -r /data/backups/restic restore latest \
  --include /etc/ssh \
  --include /var/lib/nixos \
  --include /home/untio11 \
  --target /"
```

Controleer of de rechten van de SSH host-key goed staan (`0600 root:root`):
```bash
sudo chown root:root /etc/ssh/ssh_host_*
sudo chmod 600 /etc/ssh/ssh_host_*_key
sudo chmod 644 /etc/ssh/ssh_host_*.pub
```

### Stap 3: Service State (`/var/lib/...`) herstellen
Herstel nu de state-mappen van alle services (nog vóór of terwijl de services gestopt zijn):

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

*(Mocht ook de `/data` schijf zelf vervangen zijn en restore je vanaf een externe kopie van de Restic-repo, voeg dan ook `--include /data` toe aan bovenstaand commando).*

### Stap 4: De NixOS Flake uitrollen!
Omdat `/etc/ssh/ssh_host_ed25519_key`, `/var/lib/nixos` en `/home/untio11/.config/home-manager` nu weer op hun plek staan, kun je de volledige configuratie in één keer uitrollen:

```bash
cd /home/untio11/.config/home-manager
sudo nixos-rebuild switch --flake .#gathering-hub
```
`sops-nix` ontsleutelt nu automatisch alle secrets, zet je `untio11` wachtwoord-hash terug in `/etc/shadow`, en start alle services en `restic-local` weer op!

---

## 4. PostgreSQL Databases herstellen (`hass` & `paperless`)

Na een volledige herinstallatie van de SSD heeft PostgreSQL een lege database-map aangemaakt in `/var/lib/postgresql`. Je zet de laatst gebackupte SQL-dumps uit `/data/backups/postgresql` zo terug:

### 1. Stop Home Assistant en Paperless tijdelijk
Zodat ze geen open verbindingen met de database vasthouden:
```bash
sudo systemctl stop home-assistant.service paperless-scheduler.service paperless-consumer.service paperless-task-queue.service paperless-web.service
```

### 2. Herstel de `hass` en `paperless` databases
```bash
# Zoek eerst de nieuwste dumps op in /data/backups/postgresql:
ls -lh /data/backups/postgresql/

# Herstel de Home Assistant database (vervang eventueel de bestandsnaam door de juiste dump):
sudo -u postgres psql -c "DROP DATABASE IF EXISTS hass; CREATE DATABASE hass OWNER hass;"
sudo -u postgres sh -c "zcat /data/backups/postgresql/hass.sql.gz | psql hass"

# Herstel de Paperless database:
sudo -u postgres psql -c "DROP DATABASE IF EXISTS paperless; CREATE DATABASE paperless OWNER paperless;"
sudo -u postgres sh -c "zcat /data/backups/postgresql/paperless.sql.gz | psql paperless"
```

### 3. Start de services weer op
```bash
sudo systemctl start home-assistant.service paperless-scheduler.service paperless-consumer.service paperless-task-queue.service paperless-web.service
```

> [!NOTE] Alternatieve Paperless Restore (via `document_importer`)
> Mocht er ooit iets mis zijn met de PostgreSQL-dump van Paperless, dan heb je in `/data/backups/paperless` óók nog de dagelijkse export van Paperless zelf staan. Die kun je op een lege Paperless-database altijd volledig importeren met:
> ```bash
> sudo /var/lib/paperless/paperless-manage document_importer /data/backups/paperless
> ```
