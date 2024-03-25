{config, ...}: let
  history-config = "${config.xdg.configHome}/zsh/history-config.zsh";
in {
  programs.zsh = {
    history = {
      # Non-default history file location
      path = "${config.xdg.cacheHome}/zsh/zsh_history";

      # Increase the size of the stored history
      save = 1000000;
      size = 1000000;
    };

    initExtra = "source ${history-config}";
  };

  home.file.history-config = {
    target = history-config;
    enable = true;
    text = ''
      ## Zsh History Options (Because who doesn't have a strong opinion on this 🙄?)

      # Better file locking: less chance for corruption on modern systems.
      setopt HIST_FCNTL_LOCK

      # Write the history file in the ':start:elapsed;command' format.
      setopt EXTENDED_HISTORY

      # Shared history between all sessions that's immediately available.
      setopt SHARE_HISTORY

      # Do not write a duplicate event to the history file.
      setopt HIST_SAVE_NO_DUPS

      # Expire a duplicate event first when trimming history.
      setopt HIST_EXPIRE_DUPS_FIRST

      # Delete previously recorded command if a new command is a duplicate.
      setopt HIST_IGNORE_ALL_DUPS

      # When searching in the history, never find duplicates multiple times.
      setopt HIST_FIND_NO_DUPS

      # Remove redundant whitespace
      setopt HIST_REDUCE_BLANKS

      # Do not execute immediately upon history expansion.
      setopt HIST_VERIFY

      # Don't store history commands (fc -l)
      setopt HIST_NO_STORE

      ## Remap up and down arrow to search history completions
      ## taking into account the current content of the prompt.

      # When in insert mode, up arrow should start backward history
      # search and also put us into command mode. Makes it a lot
      # easier to edit the command that we just found ('A' to go to
      # end of line to add a flag? :smirk:)
      function _history-search-cmd-mode() {
        zle history-beginning-search-backward;
        zle vi-cmd-mode;
      }
      zle -N _history-search-cmd-mode;

      # Remap arrow keys in insert mode.
      bindkey "\e[A" _history-search-cmd-mode
      bindkey "\eOA" _history-search-cmd-mode
      bindkey "\e[B" history-beginning-search-forward
      bindkey "\eOB" history-beginning-search-forward

      # Also remap them in command mode, otherwise it'll start doing
      # normal backward history search instead of content-aware.
      bindkey -a "\e[A" history-beginning-search-backward
      bindkey -a "\e[B" history-beginning-search-backward
      bindkey -a "\eOA" history-beginning-search-backward
      bindkey -a "\eOB" history-beginning-search-backward
    '';
  };
}
