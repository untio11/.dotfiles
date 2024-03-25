{config, ...}: let
  # TODO: Make this proper module options.
  prompt = ""; # , , , , , , 󱏿, , , , ⏾, , , 
  prompt-color = "white";
  direnv-prompt = "";
  prompt-file = "${config.xdg.configHome}/zsh/prompt.zsh";
in {
  programs.zsh.initExtraFirst = "source ${prompt-file}";
  home.file.prompt = {
    target = prompt-file;
    enable = true;
    text = ''
      ## zsh prompt config (yes I know there are easier ways...)
      # Enable the ''${} substitution in the prompt.
      setopt PROMPT_SUBST

      # Autoload zsh add-zsh-hook and vcs_info functions
      # (-U autoload w/o substition, -z use zsh style)
      autoload -Uz add-zsh-hook vcs_info

      # Only enable vcs_info for git
      zstyle ':vcs_info:*' enable git

      # Enable checking for (un)staged changes, enabling use of %u and %c
      zstyle ':vcs_info:git:*' check-for-changes true

      # Set custom strings for an unstaged git repo changes (*) and staged changes (+)
      zstyle ':vcs_info:git:*' unstagedstr '*'
      zstyle ':vcs_info:git:*' stagedstr '+'

      # Set the format of the Git information for vcs_info
      # The `formats` and `actionformats` setting define
      # arrays of strings that will generated by vcs_info.
      #
      # These strings will be made available in the
      # vcs_info_msg_N_ variables. N is set with
      # `max-exports` varible below. 2 is the
      # default value.
      zstyle ':vcs_info:*' max-exports '2'

      # See https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Version-Control-Information
      # for the substitution valuables used below. `formats`
      # is used in normal contexts.
      zstyle ':vcs_info:git:*' formats ' %b' '%u%c' # Nerd font branch icon

      # `actionformats` is used when git is the process
      # of merging, cherry-picking, rebasing or other
      # interactive situations.
      zstyle ':vcs_info:git:*' actionformats ' %b (%%U%a%%u)' '%u%c'

      ### The actual function used to generate the prompt.
      ### This will be run every time before the prompt
      ### is printed by adding it as a precmd hook.
      function _generate-prompt() {
      #        \n New line.
      #        %B Start bold formatting.
      # %F{green} Start green text coloring.
      #      [%T] Print 24 hour time in square brackets.
      #        %n Print user name.
      #      %b%f Stop bold and color formatting
      #       %2~ Print current directory and its parent dir.
      #           Abbreviates home directory to `~`
      #        \n Newline
      # (trying to format the above comment in helix was a mindfuck lol)
      PROMPT=$'\n%B%F{green}[%T] %n%b%f''${DIRENV_DIFF+ ${direnv-prompt}} %2~\n'

      # vcs_info_msg_1_ contains information about
      # current changes. Only run this part of the
      # prompt generation if it contains information.
      if [[ ! -z $vcs_info_msg_1_ ]]; then
      # Bold formatted and cyan colored.
      # Print in square brackets:
      #     * for unstaged changes
      #     + for staged changes
      # Ending bold and color formatting.
      # Followed by a space.
      PROMPT+=$'%B%F{cyan}[''${vcs_info_msg_1_}]%f%B '
      fi

      # vcs_info_0_ contains information about
      # the current repository and branch. Also
      # only run this part if there's actual
      # information (e.g. we're in a git repo).
      if [[ ! -z $vcs_info_msg_0_ ]]; then
      # Also bold and cyan formatting.
      # Print repo-name/branch-name
      # Stop bold and color formatting.
      # Insert newline.
      PROMPT+=$'%B%F{cyan}''${vcs_info_msg_0_}%f%b\n'
      fi

      # only present '$ ' as a prompt to type
      # the command when we're not in a Warp terminal.
      if [[ -z "$WARP_IS_LOCAL_SHELL_SESSION" ]]; then
      PROMPT+='%F{${prompt-color}}${prompt}%f '
      fi
      }

      # Printed before prompt lines that are waiting
      # for a closing '"'. For example, a multiline
      # echo or git commit message.
      # Only indent when we're not in a Warp terminal.
      # By doing this, the prompt is aligned with
      # the starting character of the command in both
      # terminals.
      if [[ -z "$WARP_IS_LOCAL_SHELL_SESSION" ]]; then
      export PS2='  %F{white}↳%f '
      else
      export PS2='%F{white}↳%f '
      fi

      # Add vcs_info and _generate-prompt as pre-command hook
      # widgets. These are called before the prompt is printed
      # to the console.
      # vcs_info needs to run before _generate-prompt to populate
      # the vcs_info_msg_1_ variables that _generate-prompts
      # uses.
      add-zsh-hook precmd vcs_info
      add-zsh-hook precmd _generate-prompt
    '';
  };
}
