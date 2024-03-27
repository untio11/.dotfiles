{
  config,
  pkgs,
  inputs,
  ...
}: let
  util-dir = ".util";
  hswitch-file = "${util-dir}/hswitch";
  revolver = "${inputs.revolver}/revolver";
in {
  home.shellAliases.hswitch = "${config.home.homeDirectory}/${hswitch-file}";
  home.file.hswitch = {
    executable = true;
    target = hswitch-file;
    enable = true;
    text = ''
      #!${pkgs.zsh}/bin/zsh
      LOG_DIR="${config.home.homeDirectory}/${util-dir}/log"
      [[ ! -d "$LOG_DIR" ]] && mkdir "$LOG_DIR"
      ${revolver} --style 'bouncingBall' start 'Building home manager config'
      home-manager build 2> $LOG_DIR/hm-switch.log

      if [[ $? -ne 0 ]]; then
        ${revolver} stop
        echo 'Build failed:'
        echo ""
        cat $LOG_DIR/hm-switch.log
        exit 1
      else
        ${revolver} update 'Activating profile'
        ./result/activate &> $LOG_DIR/hm-switch.log
        if [[ $? -ne 0 ]]; then
          ${revolver} stop
          echo 'Activation failed:'
          echo ""
          cat $LOG_DIR/hm-switch.log
          rm ./result
          exit 2;
        else
          ${revolver} update 'Formatting Nix files.'
          ${pkgs.alejandra}/bin/alejandra --quiet $HM_HOME/*/*.nix
          ${revolver} stop
          git -C $HM_HOME add -u
          hm_status=$(grep "profile generation" $LOG_DIR/hm-switch.log)
          echo "$hm_status"
          echo "$hm_status" > $LOG_DIR/hswitch-status
          if [[ "$hm_status" == *"reusing"* ]]; then
            rm ./result;
            exit 3
          else
            git -C $HM_HOME status
          fi
        fi
        rm ./result;
        exit 0;
      fi
    '';
  };
}
