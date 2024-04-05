{
  pkgs,
  profile,
  ...
}: {
  programs.helix = {
    enable = true;
    settings = {
      theme = profile.cfg.helix.theme;

      editor = {
        cursor-shape.insert = "bar";
        line-number = "relative";
        cursorline = true;
        file-picker.hidden = false; # I think so .files show up in picker
        indent-guides.render = true;
        completion-trigger-len = 1;
        true-color = true;
        color-modes = true;
        popup-border = "all";

        statusline = {
          left = [
            "file-name"
            "file-modification-indicator"
            "spinner"
            "diagnostics"
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
    languages = {
      language-server = {
        rust-analyzer = {
          config = {
            check.command = "clippy";
          };
        };
      };
      language = [
        {
          name = "nix";
          auto-format = true;
          roots = ["flake.nix" "flake.lock" "default.nix"];
          formatter = {
            command = "alejandra";
            args = ["--quiet"];
          };
        }
      ];
    };
    extraPackages = with pkgs; [
      nil
      marksman
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      alejandra
    ];
  };
}
