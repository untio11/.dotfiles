{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs = {
    overlays = [
      (final: prev: {
        vimPlugins =
          prev.vimPlugins
          // {
            monokai-pro = prev.vimUtils.buildVimPlugin {
              name = "monokai-pro";
              src = inputs.plugin-monokai-pro;
            };
          };
      })
    ];
  };

  programs.neovim = let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: toLua builtins.readFile file;
  in {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraConfig = ''
      ${builtins.readFile ./init.vim}
    '';

    plugins = with pkgs.vimPlugins; [
      vim-sandwich
      nvim-web-devicons
      {
        plugin = monokai-pro;
        config = toLua ''
          require("monokai-pro").setup({
          	devicons = true,
          	filter = "spectrum",
          	override = function(c) end,
          })
        '';
      }
    ];
  };
}
