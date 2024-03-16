{
  programs.zsh.profileExtra = ''## Include some stuff managed by homebrew 😒
    ### =========
    ### Homebrew
    ### =========
    
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';
}
