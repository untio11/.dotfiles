{pkgs, ...}: {
  programs.helix = {
    enable = true;
    settings = {
      theme = "new_moon";

      editor = {
        cursor-shape.insert = "bar";
        line-number = "relative";
        cursorline = true;
        file-picker.hidden = false; # I think so .files show up in picker
        indent-guides.render = true;
        # shell = # TODO: pass my zsh shell here.

        statusline = {
          left = [
            "file-name"
            "file-modification-indicator"
            "spinner"
          ];
          center = [
            "read-only-indicator"
          ];
          right = [
            "register"
            "mode"
          ];
        };
      };

      keys.normal = {
        # See https://docs.helix-editor.com/remapping.html#special-keys-and-modifiers
        A-up = ["extend_to_line_bounds" "delete_selection" "move_line_up" "paste_before"]; # Alt-up: move selection up
        A-down = ["extend_to_line_bounds" "delete_selection" "paste_after"]; # Alt-down: move selection down
      };
    };
    extraPackages = with pkgs; [
      nil
      marksman
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
    ];
  };
}
