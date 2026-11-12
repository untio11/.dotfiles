{
  config,
  lib,
  profile,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  options.gathering-hub.ports.syncthing = lib.mkOption {
    type = lib.types.port;
    default = 8384;
    description = lib.mdDoc ''
      Syncthing Web UI port
    '';
  };
  options.gathering-hub.mediaDirs.syncthing-root = lib.mkOption {
    type = lib.types.str;
    default = "/data/syncthing";
    description = lib.mdDoc ''
      Root directory where Syncthing synchronises directorie
    '';
  };

  config.services.syncthing = {
    enable = true;
    # Makes sure the files managed by syncthing belong to my user account.
    user = profile.username;
    group = "users";
    dataDir = cfg.mediaDirs.syncthing-root;
    configDir = "${profile.userConfigDir}/syncthing";
    openDefaultPorts = true;
    guiAddress = "127.0.0.1:${toString cfg.ports.syncthing}"; # Localhost only; Nginx will expose it
    settings.gui.insecureSkipHostcheck = true; # For reverse proxy support.
    # Allow stateful management of devices and shared folders without NixOS overwriting
    # the config on rebuild.
    overrideDevices = false;
    overrideFolders = false;
    # Synchronize pulumi filesystem state between gathering-hub and yukomo.
    settings = {
      devices."MBP-Robin" = {
        id = "MABD5SD-PZT6Z72-U45H24C-DMMSBDS-EQ3A7FH-TYAHQ5M-UVMAQ4R-BUTC3QV";
      };
      folders."pulumi-state" = {
        id = "pulumi-state";
        label = "Pulumi State (.dotfiles)";
        path = "${profile.userConfigDir}/home-manager/pulumi/state";
        devices = [ "MBP-Robin" ];
      };
    };
  };
}
