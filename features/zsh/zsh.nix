{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    dotDir = ".config/zsh";
    sessionVariables = {
      EDITOR = "hx";
      WORDCHARS = "*?[]~=&;!#$%^(){}<>";
      SHELL = "${pkgs.zsh}/bin/zsh"; # So alactritty actually loads the correct zsh
      DIRENV_LOG_FORMAT = ""; # Stop direnv from vomiting on the screen.
    };

    shellAliases = {
      ls =      "lsd";
      hm =      "home-manager";
      la =      "lsd -a --group-dirs first";
      lla =     "lsd -la --group-dirs first";
      lt =      "lsd --tree --group-dirs last --no-symlink";
      catp =    "bat";
      cat =     "bat --paging=never";
      subl =    "/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl";
      python =  "python3";
      zcp =     "zmv -C";
      zln =     "zmv -L";
      zrc =     "source $ZDOTDIR/.zshrc";
      dotfile = "git --work-tree=$HOME --git-dir=$HOME/.dotfiles"; # For managing dotfiles in ~/.
      tmux =    "tmux -u"; # To enable unicode characters.
      vim =     "nvim";
    };

    dirHashes = {
      dev = "$HOME/Development";
      doc = "$HOME/Documents";
      hm  = "$HOME/.config/home-manager";
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [ "brackets" ]; # In addition to main command syntax highlighting.
    };

    initExtraFirst = ''## All the way at the top of .zshrc

    '';
    initExtraBeforeCompInit = ''## Followed by this.

      ### ========================
      ### Autoloading z functions
      ### ========================

      # zmv allows for parametrised file renaming.
      autoload zmv

      ### =======================
      ### Settings configuration
      ### =======================

      # Increase open file limit for development purposes
      ulimit -n 8192

      # Assume dvorak layout for assessing spelling mistakes.
      # Used by CORRECT and CORRECT_ALL.
      setopt DVORAK

      # Enable correction suggestion when detecting a possible typo.
      setopt CORRECT

      # Always move cursor to end when doing tab-completion
      setopt ALWAYS_TO_END

      # By unsetting this option, the list of possible completions
      # is displayed directly after tab-completing to the longest
      # unambiguous match.
      # Otherwise, first tab completes to longest unambiguous match
      # and a second tab is needed to show the options.
      unsetopt LIST_AMBIGUOUS

      # Allow wildcards to be cycled through with tab-completion.
      setopt GLOB_COMPLETE

      # Enable tab-completion for alias commands (specifically dotfile
      # was not working otherwise)
      setopt COMPLETE_ALIASES

      # Make path completion case-insensitive
      unsetopt CASE_GLOB 
    '';
    
    enableCompletion = true; # Then this in .zshrc
    completionInit = ''## My inner nerdness knows no bounds
      zstyle ':completion:*' completer _extensions _complete _approximate
      zstyle ':completion:*' menu select
      zstyle ':completion:*:*:*:*:descriptions' format '%F{magenta}%d%f'
      zstyle ':completion:*' group-name \'\'
      zstyle ':completion:*:git*:*' list-grouped false
      zstyle ':completion:*' verbose true
      zstyle ':completion:*' show-ambiguity true
      zstyle ':completion:*:git*:*' list-packed false
      zstyle ':completion:*approximate*:git-checkout:argument-rest:heads*' hidden true
      autoload -U compinit
      if [[ "$HOME/.zshenv" -nt "$ZDOTDIR/.zcompdump" ]]; then
        echo "[info] Regenerating .zcompdump"
        compinit
      else
        compinit -C
      fi
    '';

    loginExtra = ''## tmux startup. .zlogin is called after .zshrc
      ###
      ### Only connect to a new tmux window if we're not already
      ### in tmux, we're not in the vscode terminal emulator, and
      ### we're not not in a warp shell session.
      if [[ ! ( -v "TMUX" || -v "VSCODE_INJECTION" || -v "WARP_IS_LOCAL_SHELL_SESSION" ) ]]; then
      	tmux new-window -t "GLOBAL:" \; attach -t "GLOBAL:$" || tmux new -s "GLOBAL"
      fi
    '';

    profileExtra = "";
    envExtra = "";
  };

  imports = [
    ./history-config.nix
    ./prompt.nix
    ./user-widgets
    ./impure.nix
  ];
}
