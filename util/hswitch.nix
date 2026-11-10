{
  config,
  pkgs,
  inputs,
  profile,
  ...
}:
let
  util-dir = ".util";
  hswitch-file = "${util-dir}/hswitch";
  revolver = "${inputs.revolver}/revolver";
  flake-attr = ''homeConfigurations.\"${profile.username}@${profile.hostname}\".activationPackage'';
in
{
  home.shellAliases.hswitch = "${config.home.homeDirectory}/${hswitch-file}";
  home.file.hswitch = {
    executable = true;
    target = hswitch-file;
    enable = true;
    text = ''
      #!${pkgs.zsh}/bin/zsh
      LOG_DIR="${config.home.homeDirectory}/${util-dir}/log"
      RESULT_LINK="$LOG_DIR/result"
      [[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"
      ${revolver} --style 'bouncingBall' start 'Building home manager config'
      nix build "$HM_HOME#${flake-attr}" --out-link "$RESULT_LINK" 2> $LOG_DIR/hm-switch.log

      if [[ $? -ne 0 ]]; then
        ${revolver} stop
        echo 'Build failed:'
        echo ""
        cat $LOG_DIR/hm-switch.log
        exit 1
      else
        ${revolver} update 'Activating profile'
        "$RESULT_LINK/activate" &> $LOG_DIR/hm-switch.log
        if [[ $? -ne 0 ]]; then
          ${revolver} stop
          echo 'Activation failed:'
          echo ""
          cat $LOG_DIR/hm-switch.log
          rm "$RESULT_LINK"
          exit 2;
        else
          ${revolver} stop
          hm_status=$(grep "profile generation" $LOG_DIR/hm-switch.log)
          echo "$hm_status"
          echo "$hm_status" > $LOG_DIR/hswitch-status
          if [[ "$hm_status" == *"reusing"* ]]; then
            rm "$RESULT_LINK";
            exit 3
          else
            # Jujutsu status:
            jj -R $HM_HOME s
          fi
        fi
        rm "$RESULT_LINK";
        exit 0;
      fi
    '';
  };
}
