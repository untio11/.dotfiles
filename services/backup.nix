{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
let
  cfg = config.gathering-hub;
  userHomeDir = "${profile.base-home-dir}/${profile.username}";
in
{
  options.gathering-hub.backup = {
    root-dir = lib.mkOption {
      type = lib.types.str;
      default = "/data/backups";
      description = lib.mdDoc ''
        Root directory where local backups and database dumps are stored
      '';
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Paths to include in Restic backups across local and cloud repositories
      '';
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc ''
        Path patterns to exclude from Restic backups
      '';
    };
  };

  config.sops = {
    secrets."restic_password" = { };
    secrets."gcp_restic_credentials_json" = { };
  };

  # Ensure the `/data/backups` directory exists.
  config.systemd.tmpfiles.settings."backups".${cfg.backup.root-dir}.d = { };

  # Core machine & user home state backed up on the host.
  config.gathering-hub.backup = {
    paths = [
      # Machine-specific keys necessary to access sops.
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"

      "/var/lib/nixos"

      # User home data
      userHomeDir
    ];
    exclude = [
      "${userHomeDir}/.cache"
    ];
  };

  config.services.restic.backups =
    let
      resticSensors = import ../hass/sensors/restic.nix {
        inherit pkgs;
        mosquittoPort = cfg.ports.mosquitto;
      };

      commonRestic = {
        initialize = true;
        passwordFile = config.sops.secrets."restic_password".path;
        inherit (cfg.backup) paths exclude;

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 3"
        ];
      };
    in
    {
      local =
        commonRestic
        // (resticSensors.mkHooks {
          name = "local";
          label = "Local";
          repo = "${cfg.backup.root-dir}/restic";
          icon = "mdi:harddisk";
        })
        // {
          timerConfig = {
            OnCalendar = "02:00";
            Persistent = true;
          };
        };

      gcs =
        commonRestic
        // (resticSensors.mkHooks {
          name = "gcs";
          label = "GCS";
          repo = "gs:gathering-hub-restic-8acc3d4:/";
          icon = "mdi:cloud-upload";
        })
        // {
          timerConfig = {
            OnCalendar = "03:00";
            Persistent = true;
          };
          environmentFile = "${pkgs.writeText "restic-gcs.env" ''
            GOOGLE_PROJECT_ID=robotic-circle-456517-e7
            GOOGLE_APPLICATION_CREDENTIALS=${config.sops.secrets."gcp_restic_credentials_json".path}
          ''}";
        };
    };
}
