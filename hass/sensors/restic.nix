{
  pkgs,
  mosquittoPort,
}:
let
  mosqPub = "${pkgs.mosquitto}/bin/mosquitto_pub -h 127.0.0.1 -p ${toString mosquittoPort} -r";

  mkDiscoveryScript =
    {
      name,
      label,
      repo,
      icon,
    }:
    let
      stateTopic = "restic/backups/${name}/state";
      statsTopic = "restic/backups/${name}/stats";
      device = {
        identifiers = [ "restic_backup_${name}" ];
        name = "Restic Backup (${label})";
        manufacturer = "Restic";
        model = repo;
      };
      mkSensorCfg =
        topic: metric: cfg:
        builtins.toJSON (
          {
            unique_id = "restic_${name}_${metric}";
            object_id = "restic_${name}_${metric}";
            state_topic = topic;
            inherit device;
          }
          // cfg
        );
    in
    ''
      ${mosqPub} -t "homeassistant/sensor/restic_${name}_status/config" -m '${
        mkSensorCfg stateTopic "status" {
          name = "Status";
          value_template = "{{ value_json.status }}";
          inherit icon;
        }
      }'
      ${mosqPub} -t "homeassistant/sensor/restic_${name}_last_run/config" -m '${
        mkSensorCfg stateTopic "last_run" {
          name = "Last Run";
          value_template = "{{ value_json.last_run }}";
          device_class = "timestamp";
          icon = "mdi:clock-outline";
        }
      }'
      ${mosqPub} -t "homeassistant/sensor/restic_${name}_latest_snapshot_time/config" -m '${
        mkSensorCfg statsTopic "latest_snapshot_time" {
          name = "Latest Snapshot Time";
          value_template = "{{ value_json.latest_snapshot_time }}";
          device_class = "timestamp";
          icon = "mdi:calendar-clock";
        }
      }'
      ${mosqPub} -t "homeassistant/sensor/restic_${name}_snapshot_count/config" -m '${
        mkSensorCfg statsTopic "snapshot_count" {
          name = "Snapshot Count";
          value_template = "{{ value_json.snapshot_count }}";
          state_class = "measurement";
          unit_of_measurement = "snapshots";
          icon = "mdi:counter";
        }
      }'
      ${mosqPub} -t "homeassistant/sensor/restic_${name}_latest_snapshot_id/config" -m '${
        mkSensorCfg statsTopic "latest_snapshot_id" {
          name = "Latest Snapshot ID";
          value_template = "{{ value_json.latest_snapshot_id }}";
          icon = "mdi:identifier";
        }
      }'
      ${mosqPub} -t "homeassistant/sensor/restic_${name}_total_size_gb/config" -m '${
        mkSensorCfg statsTopic "total_size_gb" {
          name = "Repository Size";
          value_template = "{{ value_json.total_size_gb }}";
          device_class = "data_size";
          state_class = "measurement";
          unit_of_measurement = "GiB";
          suggested_display_precision = 2;
          icon = "mdi:database";
        }
      }'
    '';

  mkPrepareHook =
    {
      name,
      label,
      repo,
      icon,
    }:
    ''
      ${mkDiscoveryScript {
        inherit
          name
          label
          repo
          icon
          ;
      }}
      STATE_PAYLOAD="$(${pkgs.jq}/bin/jq -c -n \
        --arg last_run "$(date -Iseconds)" \
        '{
          status: "started",
          last_run: $last_run
        }')"
      ${mosqPub} -t "restic/backups/${name}/state" -m "$STATE_PAYLOAD"
    '';

  mkStatusHook =
    {
      name,
      label,
      repo,
      icon,
    }:
    ''
      ${mkDiscoveryScript {
        inherit
          name
          label
          repo
          icon
          ;
      }}
      STATE_PAYLOAD="$(${pkgs.jq}/bin/jq -c -n \
        --arg status "''${SERVICE_RESULT:-unknown}" \
        --arg last_run "$(date -Iseconds)" \
        '{
          status: $status,
          last_run: $last_run
        }')"
      ${mosqPub} -t "restic/backups/${name}/state" -m "$STATE_PAYLOAD"

      SNAPS="$(${pkgs.restic}/bin/restic snapshots --json 2>/dev/null || echo '[]')"
      STATS="$(${pkgs.restic}/bin/restic stats --mode raw-data --json 2>/dev/null || echo '{}')"
      STATS_PAYLOAD="$(${pkgs.jq}/bin/jq -c -n \
        --argjson snaps "$SNAPS" \
        --argjson stats "$STATS" \
        '{
          snapshot_count: ($snaps | length),
          latest_snapshot_id: ($snaps | last | .short_id // "none"),
          latest_snapshot_time: ($snaps | last | .time // null),
          total_size_gb: ((($stats.total_size // 0) / 1073741824 * 100 | round) / 100)
        }')"
      ${mosqPub} -t "restic/backups/${name}/stats" -m "$STATS_PAYLOAD"
    '';
in
{
  mkHooks =
    meta: {
      repository = meta.repo;
      backupPrepareCommand = mkPrepareHook meta;
      backupCleanupCommand = mkStatusHook meta;
    };
}
