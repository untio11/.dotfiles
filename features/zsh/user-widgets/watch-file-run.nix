{
  pkgs,
  config,
  ...
}: let
  watch-file-run-file = "${config.xdg.configHome}/zsh/user-widgets/watch-file-run.zsh";
in {
  programs.zsh.initExtraFirst = "source ${watch-file-run-file}";
  home.file.watch-file-run = {
    target = watch-file-run-file;
    enable = true;
    text = ''
      ## Watch a file for save events and run a command when that happens.
      ###
      ### First argument: file path to watch
      ### The rest ''${@:2}: the command with its arguments to execute on save.

      function watch-file-run () {
        ${pkgs.fswatch}/bin/fswatch -0 -o $1 |  xargs -0 -n1 -I{} ''${@:2}
      }
    '';
  };
}
