{
  config,
  lib,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  options.gathering-hub.ports.zigbee2mqtt = lib.mkOption {
    type = lib.types.port;
    default = 8080;
    description = lib.mdDoc ''
      Zigbee2MQTT Web UI port
    '';
  };
  options.gathering-hub.ports.mosquitto = lib.mkOption {
    type = lib.types.port;
    default = 1883;
    description = lib.mdDoc ''
      Mosquitto message broker port
    '';
  };

  config.services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "127.0.0.1";
        port = cfg.ports.mosquitto;
        omitPasswordAuth = true; # Do I want to enable this eventually?
        settings.allow_anonymous = true;
        acl = [ "pattern readwrite #" ];
      }
    ];
  };
  config.services.zigbee2mqtt = {
    enable = true;
    settings = {
      version = 5;
      homeassistant.enabled = true;
      permit_join = false; # Toggle via web UI when pairing new devices.
      mqtt.server = "mqtt://127.0.0.1:${toString cfg.ports.mosquitto}";
      # SMLIGHT SLZB-07 config
      serial = {
        port = "/dev/serial/by-id/usb-SMLIGHT_SMLIGHT_SLZB-07_9e2fd2b588d5ef1183fb694b49d2c684-if00-port0";
        adapter = "ember";
        baudrate = 115200;
        rtscts = true;
      };
      frontend = {
        enabled = true;
        host = "127.0.0.1";
        port = cfg.ports.zigbee2mqtt;
      };
      # First time deployment with value `GENERATE` generated these values.
      advanced = {
        # `zigbee2mqtt-secret.yaml` created by sops.
        network_key = "!secret network_key";
        pan_id = 2296;
        ext_pan_id = [
          90
          195
          14
          142
          202
          41
          196
          14
        ];
      };
    };
  };
}
