{ pkgs, config, ... }:

{
  programs.lsd = {
    enable = true;
    settings = {
      blocks = [ "date" "size" "name" ];
      indicators = true;
    };
  };
}