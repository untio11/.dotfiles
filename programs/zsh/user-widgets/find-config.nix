{
  config,
  ...
}:
let
  find-config-file = "${config.xdg.configHome}/zsh/user-widgets/find-config.zsh";
in
{
  # Don't put it at the top with `initContent = lib.mkBefore`, because setting vi keymap happens afterwards and overrides keybinds
  programs.zsh.initContent = "source ${find-config-file}";
  home.file.find-config = {
    target = find-config-file;
    enable = true;
    text = ''
      ### Look for a file called $1 in directory $2 (fallback to the current directory),
      ### recurse upwards if it's not found.
      function find-config() {
        local base_dir=$(
            proto=$(realpath ''${2-$PWD})
            if [[ -f $proto ]]; then
                dirname "$proto"
            elif [[ -d $proto ]]; then
                echo "$proto"
            else
                echo "$proto" is not a file or directory.
                exit 1
            fi
        )
        local target="$base_dir/$1"

        if [ -f "$target" ]; then
            printf '%s\n' "$target"
        elif [ "$base_dir" = / ]; then
            false
        else
            # Recurse upwards, works because of the realpath call at the start.
            find-config "$1" "$base_dir/.."
        fi
      }
    '';
  };
}
