{pkgs, ...}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user.name = "Robin Kneepkens";
      aliases = {
        # Short log with no paging for quick reference
        lg = ["log" "-n10" "--no-pager"];
      };
      ui = {
        pager = ["${pkgs.ov}/bin/ov" "-F"];
        diff.tool = [
          "${pkgs.difftastic}/bin/difft"
          "--color=always"
          "--syntax-highlight=off"
          "--tab-width=4"
          "--display=side-by-side-show-both"
          "$left"
          "$right"
        ];
      };

      # Start of condition options:
      "--scope" = [
        {"--when.commands" = ["diff"];}
        {
          ui.pager = [
            "${pkgs.ov}/bin/ov"
            "-F"
            "--section-delimiter=( --- )"
            "--section-header"
          ];
        }
      ];
    };
  };
  # Enable dynamic command completions. See: https://jj-vcs.github.io/jj/latest/install-and-setup/#dynamic_1
  programs.zsh.initExtra = "source <(COMPLETE=zsh ${pkgs.jujutsu}/bin/jj)";
}
