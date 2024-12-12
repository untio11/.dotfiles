{...}: {
  imports = [
    # C-f:  fuzzy find in line
    ./fuzzy-find.nix
    # C-h:  fuzzy find command history
    ./fuzzy-history.nix
    # C-g:  stach current prompt line to recursively run a command
    ./quick-insert.nix
    # `ec`: fuzzy find config files to open with $EDITOR
    ./quick-config.nix
    # `changelog`: automate some steps for creating usr changelog entries
    ./changelog.nix
    # `watch-file-run`: watch a file for save events, run command.
    ./watch-file-run.nix
  ];
}
