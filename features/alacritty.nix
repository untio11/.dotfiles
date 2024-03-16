{ config, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 6; y = 6; };
        dynamic_padding = true;
        decorations = "none";
        option_as_alt = "OnlyLeft";
        opacity = 0.8;
        blur = true;
      };

      font = {
        normal.family = "FiraCode Nerd Font Mono";
        size = 15;
      };
  
      colors = with config.colorScheme.palette; {
        primary = {
          background = "#${base00}";
          foreground = "#${base07}";
        };
  
        cursor.cursor = "#${base07}";
  
        selection.background = "#${base06}";
  
        normal = {
          black =      "#${base00}";
          red =        "#${base01}";
          green =      "#${base02}";
          yellow =     "#${base03}";
          blue =       "#${base04}";
          magenta =    "#${base05}";
          cyan =       "#${base06}";
          white =      "#${base07}";
        };
    
        bright = {
          black =      "#${base08}";
          red =        "#${base09}";
          green =      "#${base0A}";
          yellow =     "#${base0B}";
          blue =       "#${base0C}";
          magenta =    "#${base0D}";
          cyan =       "#${base0E}";
          white =      "#${base0F}";
        };
      };
    };
  };
}
