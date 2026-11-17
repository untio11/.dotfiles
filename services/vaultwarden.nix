{
  config,
  lib,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  options.gathering-hub.ports.vaultwarden = lib.mkOption {
    type = lib.types.port;
    default = 8222;
    description = lib.mdDoc ''
      Vaultwarden Web UI port
    '';
  };

  config.sops = {
    secrets."vaultwarden_admin_token_hash" = { };
    templates."vaultwarden.env" = {
      content = ''
        ADMIN_TOKEN='${config.sops.placeholder.vaultwarden_admin_token_hash}'
      '';
    };
  };

  config.services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    configurePostgres = true;
    domain = "vaultwarden.${cfg.domain}";
    environmentFile = config.sops.templates."vaultwarden.env".path;
    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = cfg.ports.vaultwarden;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      ENABLE_WEBSOCKET = true;
    };
  };

  config.gathering-hub.backup.paths = [
    # StateDirectory is named `bitwarden_rs` when `system.stateVersion` < 24.11.
    "/var/lib/bitwarden_rs"
  ];
}
