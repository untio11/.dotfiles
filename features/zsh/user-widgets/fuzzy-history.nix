{config, ...}: let
  fuzzy-history-file = "${config.xdg.configHome}/zsh/user-widgets/fuzzy-history.zsh";
in {
  # TODO: Idea - perform some smarter history optimization via an external program that rewrites your history based on patterns?
  programs.zsh.initExtra = "source ${fuzzy-history-file}"; # Don't load before setting vi keymap
  home.file.fuzzy-history = {
    target = fuzzy-history-file;
    enable = true;
    text = ''
      ## Fuzzy History Search
      ###
      ### Perform a fuzzy find on the history file
      ### that's currently available to this shell
      ### session.
      ###
      ### If a match is selected from the fzf inter-
      ### face, the selected command will be performed
      ### right away.
      function _fuzzy-history() {
        local command=$( \
          ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | \
          fzf +s --height=12 --reverse --tac | \
          sed 's/ *[0-9]* *//' \
        )

        if [[ ! -z "$command" ]]; then
          BUFFER="$command"
          zle .accept-line
        fi

        zle end-of-line
        zle redisplay
      }

      # Create a new zle widget.
      zle -N _fuzzy-history

      # And bind it to control-H.
      bindkey "^h" _fuzzy-history
    '';
  };
}
