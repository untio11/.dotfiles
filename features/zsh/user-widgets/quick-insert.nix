{ pkgs, config, ... }:

let 
  quick-insert-file = "${config.xdg.configHome}/zsh/user-widgets/quick-insert.zsh";
in
{
  # Don't load at the top of the file: vi keymap would override keybinds
	programs.zsh.initExtra = "source ${quick-insert-file}"; 
  home.file.quick-insert = {
    target = quick-insert-file;
    enable = true;
    text = ''## In the middle of typing some command but forgot that ls/git status/cat?
      ###
      ### Hit C-g to get a clean prompt to type a command, then go back to the first 
      ### command you were typing. Feel free to recurse (at your own risk: very untested)
      
      function _quick-insert() {
      	local prev_buffer="$BUFFER"
      	zle kill-whole-line

      	() {
      		zle recursive-edit
          # bunch of newlines to align the previous prompt below the recursive one
      		eval "echo && $BUFFER && echo && echo && echo "
      	}

      	BUFFER="$prev_buffer"
      	zle end-of-line
      	zle redisplay
      }

      zle -N _quick-insert
      bindkey "^g" _quick-insert
    '';
  };
}
