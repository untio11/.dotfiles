{
  config,
  pkgs,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  config.services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
  };

  config.services.postgresqlBackup = {
    # Default schedule: daily at 01:15 (`startAt` property.)
    enable = true;
    location = "${cfg.backup.root-dir}/postgresql";
    # Automatically back up all databases declared via `services.postgresql.ensureDatabases`
    # (including services like Vaultwarden that provision theirs via `configurePostgres = true`).
    databases = config.services.postgresql.ensureDatabases;
  };

  config.gathering-hub.backup.paths = [
    config.services.postgresqlBackup.location
  ];
}
