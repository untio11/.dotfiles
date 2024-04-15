{config, ...}: let
  ov-config-file = "${config.xdg.configHome}/ov/config.yaml";
in {
  home.file.ov-config = {
    target = ov-config-file;
    enable = true;
    text = ''
      KeyBind:
        - previous_section: "`"
    '';
  };
}
