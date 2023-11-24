{ pkgs, config, ... }:

{
  programs.tmux = {
    enable = true;

    # Sets window _and_ pane index
    baseIndex = 1;

    escapeTime = 10;
    historyLimit = 1000000;
    mouse = true;
    prefix = "C-Space";
    terminal = "screen-256color";

    extraConfig = ''
      # Reload config file with prefix-r hotkey
      unbind r
      bind r source-file "$XDG_CONFIG_HOME/tmux/tmux.conf" \; display "Reloaded tmux config"

      # Also renumber windows on deletion
      set -g renumber-windows on

      # Nicer pane splitting
      unbind v
      unbind h
      unbind %
      unbind '"'
      # Opens a new pane in the cwd of the 'parent' pane.
      bind-key h split-window -v -c "#{pane_current_path}"
      bind-key v split-window -h -c "#{pane_current_path}"

      # Enable on-focus event
      set -g focus-events on

      # Fix colors
      set -ag terminal-overrides ",$TERM:RGB"

      # Kill panes quicker
      unbind x
      bind-key C-w kill-pane

      # Kill windows quicker
      bind-key x kill-window

      # Stylin'
      set -g status on
      set -g status-position "top"
      set -g status-interval 1

      # Left portion of status bar
      set -g status-left "[#S]" # [SESSION_NAME] 
      set -g status-left-length 20

      # Center portion of status bar
      set -g status-justify "absolute-centre"

      # Right portion of status bar
      set -g status-right "%a %e %b - %k:%M" # Day 00 Month - 00:00
      set -g status-right-length 20

      # Base status bar style
      set -g status-style "bg=terminal,fg=cyan,underscore dim"

      # Base window selector style
      set -g window-status-format "#W"
      set -g window-status-current-format "#W"
      set -g window-status-separator ""
      set -g automatic-rename-format "#{?window_zoomed_flag,>#{pane_current_command}<, #{pane_current_command} }"

      # Current window
      set -g window-status-current-style "double-underscore bold"

      # Last active window
      set -g window-status-last-style "curly-underscore"

      # Pane borders
      set -g pane-active-border-style "fg=cyan"
      set -g pane-border-style "fg=white" 

      # Status bar message
      set -g message-style "bg=cyan,fg=brightblack"
    '';

  };
}