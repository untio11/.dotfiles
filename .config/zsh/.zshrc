# Enable vi mode
bindkey -v

### =====================
### Prompt customization
### =====================
source "$ZDOTDIR/prompt.zsh"


### =====================
### Widgets and keybinds
### =====================

# Bind fuzzy history search to ^h
source "$ZDOTDIR/user-widgets/fuzzy-history.zsh"

# Bind quick insert to ^g
source "$ZDOTDIR/user-widgets/quick-insert.zsh"

# Bind fuzzy find to ^f
source "$ZDOTDIR/user-widgets/fuzzy-find.zsh" 

# Make `ec` and `rc` available for quick config file editing and sourcing
source "$ZDOTDIR/user-widgets/quick-config.zsh" 


### ========================
### Autoloading z functions
### ========================

# zmv allows for parametrised file renaming.
autoload zmv


### =======================
### Settings configuration
### =======================

# Increase open file limit for development purposes
ulimit -n 8192

# Set up shell history to my liking. Intoduces
# h() function for grepping history.
source "$ZDOTDIR/history-config.zsh"

# Assume dvorak layout for assessing spelling mistakes.
# Used by CORRECT and CORRECT_ALL.
setopt DVORAK

# Enable correction suggestion when detecting a possible
# typo.
setopt CORRECT

# Always move cursor to end when doing tab-completion
setopt ALWAYS_TO_END

# By unsetting this option, the list of possible completions
# is displayed directly after tab-completing to the longest
# unambiguous match.
# Otherwise, first tab completes to longest unambiguous match
# and a second tab is needed to show the options.
unsetopt LIST_AMBIGUOUS

# Allow wildcards to be cycled through with tab-completion.
setopt GLOB_COMPLETE

# Enable tab-completion for alias commands (specifically dotfile
# was not working otherwise)
setopt COMPLETE_ALIASES

# Make path completion case-insensitive
unsetopt CASE_GLOB 

# Set sublime as default editor for programs that refer to $EDITOR
export EDITOR='subl'


### ========
### Aliases
### ========

alias ls='lsd'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias catp='bat'
alias cat='bat --paging=never'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias python='python3'
alias zrc='source $ZDOTDIR/.zshrc'
alias zcp='zmv -C'
alias zln='zmv -L'
alias dotfile='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME' # For managing dotfiles in ~/.
alias tmux='tmux -u' # To enable unicode characters.
alias vim='nvim'


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

### ========================
### zsh syntax highlighting
### ========================

# NOTE: Needs to be included at the end of .zshrc
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"


### ======================================
### Always connect to global tmux session
### ======================================
if [[ -z "$TMUX" ]]; then
	tmux new-window -t "GLOBAL:" \; attach -t "GLOBAL:$" || tmux new -s "GLOBAL"
fi





