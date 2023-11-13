function _quick-insert() {
	local prev_buffer="$BUFFER"
	zle kill-whole-line

	() {
		zle recursive-edit
		eval "echo && $BUFFER && echo && echo && echo "
	}

	BUFFER="$prev_buffer"
	zle end-of-line
	zle redisplay
}

zle -N _quick-insert

bindkey "^g" _quick-insert
