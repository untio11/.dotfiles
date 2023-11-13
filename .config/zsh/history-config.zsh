### ===========================
### zsh Command history config
### ===========================

## History file

# Point to non-default file for storing
# history of entered commands.
export HISTFILE="$HOME/.cache/zsh/zsh_history"

# Defines how many commands from the 
# history are loaded during a session
# when searching.
export HISTSIZE=1000

# Increase the size of the history to 
# be stored.
export SAVEHIST=$HISTSIZE

## History options

# Write the history file in the ':start:elapsed;command' format.
setopt EXTENDED_HISTORY          

# Shared history between all sessions that's immediately available.
setopt SHARE_HISTORY

# Remove reduntant whitespace
setopt HIST_REDUCE_BLANKS

# Do not write a duplicate event to the history file.
setopt HIST_SAVE_NO_DUPS

# Expire a duplicate event first when trimming history.
setopt HIST_EXPIRE_DUPS_FIRST

# Delete previously recorded command if a new command is a duplicate.
setopt HIST_IGNORE_ALL_DUPS      

# When searching in the history, never find duplicates multiple times.
setopt HIST_FIND_NO_DUPS

# Do not execute immediately upon history expansion.
setopt HIST_VERIFY

# Don't store history commands (fc -l)
setopt HIST_NO_STORE

## History grepping
# Run grep on the current history file and highlight matches.
# Might be useful at some point, but probably nicer to use
# fuzzy-history.
function h() {
    # check if we passed any parameters
    if [ -z "$*" ]; then
        # if no parameters were passed print entire history
        history 1
    else
        # if words were passed use it as a search
        history 1 | egrep --color=auto "$@"
    fi
}

## Remap up and down arrow to search history completions
## taking into account the current content of the prompt.

bindkey "\e[A" history-beginning-search-backward
bindkey "\e[B" history-beginning-search-forward
