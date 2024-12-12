{...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    config.hide_env_diff = true;
  };
}
