{
  programs.zsh.profileExtra = ''
    ## Include some stuff managed by homebrew 😒
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';
}
