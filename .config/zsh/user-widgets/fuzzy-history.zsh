### ======================
### Fuzzy History Search
### ======================
###
### Perform a fuzzy find on the history file
### that's currently available to this shell
### session.
###
### If a match is selected from the fzf inter-
### face, the selected command will be performed
### right away.
function _fuzzy-history() {
	local command=$( \
		([ -n "$ZSH_NAME" ] && fc -l 1 || history) | \
		fzf +s --height=12 --reverse --tac | \
		sed 's/ *[0-9]* *//' \
	)

	if [[ ! -z "$command" ]]; then
		BUFFER="$command"
		zle .accept-line
	fi
	
	zle end-of-line
	zle redisplay
}

# Create a new zle widget.
zle -N _fuzzy-history

# And bind it to control-H.
bindkey "^h" _fuzzy-history
