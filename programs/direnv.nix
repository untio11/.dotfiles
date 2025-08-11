{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    config = {
      hide_env_diff = true;
      warn_timeout = "10s"; # Default is 5s, but that basically always triggers on flakes.
      strict_env = true; # Runs .envrc with set -euo pipefail
      bash_path = "${pkgs.bash}/bin/bash"; # Force direnv to always use bash from nix store.
    };
  };
}
