{ pkgs, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user.name = "Robin Kneepkens";
      aliases = {
        # Short log with no paging for quick reference.
        lg = [
          "log"
          "-n10"
          "--no-pager"
        ];
        # Show ancestors and descendants of current head that aren't in remote trunk yet.
        olog = [
          "log"
          "-r"
          "branch_commits"
        ];
        # Update the closest bookmark to the current working commit.
        bup = [
          "bookmark"
          "move"
          "-f"
          "closest_bookmark"
          "-t"
          "@"
        ];
        git_branch = [
          "log"
          "--no-graph"
          "-r"
          "closest_bookmark"
          "-T"
          "bookmarks"
        ];
        s = [
          "status"
          "--no-pager"
        ];
      };

      ui = {
        default-command = [
          "olog"
          "-n10"
          "--no-pager"
        ];
        pager = [
          "${pkgs.ov}/bin/ov"
          "-F"
        ];
        diff-formatter = [
          "${pkgs.difftastic}/bin/difft"
          "--color=always"
          "--syntax-highlight=off"
          "--tab-width=4"
          "--display=side-by-side-show-both"
          "$left"
          "$right"
        ];
      };

      revset-aliases = {
        # All commits contributing to the current head (@) that aren't in remote master (trunk) yet.
        branch_commits = "present(trunk())::present(@) | present(trunk())..present(@)";
        # Find the first ancestor commit of the current head that's also a bookmark.
        closest_bookmark = "latest(::present(@) & bookmarks())";
      };

      # Start of conditional options:
      "--scope" =
        let
          ov = "${pkgs.ov}/bin/ov";
        in
        [
          {
            "--when" = {
              commands = [ "diff" ];
            };
            ui.pager = [
              ov
              "-F"
              # Matches difft section headers for easy jumping through them.
              "--section-delimiter=( --- )"
              "--section-header"
            ];
          }
          {
            "--when" = {
              commands = [ "log" ];
            };
            ui.pager = [
              ov
              "-F"
              # Matches commits that are bookmarked or tagged. Match node icon, timestamp and then checks if
              # there's at least one string followed by a space before the commit hash at the end of the line.
              "--section-delimiter=[○◆].+(\\d{2}:?){3} (.+ )+\\w+$"
              "--section-header"
            ];
          }
        ];
    };
  };
  # Enable dynamic command completions. See: https://jj-vcs.github.io/jj/latest/install-and-setup/#dynamic_1
  programs.zsh.initContent = "source <(COMPLETE=zsh ${pkgs.jujutsu}/bin/jj)";
}
