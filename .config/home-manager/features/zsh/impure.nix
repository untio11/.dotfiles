{
  programs.zsh.profileExtra = ''## Include some stuff managed by homebrew 😒
    ### =========
    ### Homebrew
    ### =========
    
    eval "$(/opt/homebrew/bin/brew shellenv)"
  
    ### ===========
    ### NVM Config
    ### ===========

    export NVM_DIR="$HOME/.nvm"
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


    ### ==========================
    ### GCloud SDK Path inclusion
    ### ==========================

    source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
    source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
  '';
}
