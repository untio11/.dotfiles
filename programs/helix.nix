{
  pkgs,
  self,
  profile,
  ...
}:
{
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        cursor-shape.insert = "bar";
        line-number = "relative";
        cursorline = true;
        indent-guides.render = true;
        completion-trigger-len = 1;
        true-color = true;
        color-modes = true;
        popup-border = "all";

        inline-diagnostics.cursor-line = "warning";

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
        A-up = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_before"
        ]; # Alt-up: move selection up
        A-down = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_after"
        ]; # Alt-down: move selection down
      };
    };
    languages = {
      language-server = {
        rust-analyzer = {
          config = {
            check.command = "clippy"; # Use `cargo-clippy` as that points to the local toolchain version of `clippy`.
          };
        };
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
          config = {
            # Should add completion of home-manager options to nixd, but seems to not really work.
            options.home-manager.expr = "(builtins.getFlake \"${self}\").homeConfigurations.\"${profile.username}@${profile.hostname}\".options";
          };
        };
      };
      language = [
        {
          name = "nix";
          language-servers = [ "nixd" ];
          auto-format = true;
          roots = [
            "flake.nix"
            "flake.lock"
            "default.nix"
          ];
          file-types = [ "nix" ];
          formatter = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
          };
        }
      ];
    };
    extraPackages = with pkgs; [
      nixd
      marksman
      bash-language-server
      typescript-language-server
    ];
  };
}
