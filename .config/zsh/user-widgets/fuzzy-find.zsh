### ================
### Fuzzy Find
### ================
###
### Fuzzy find a path in the current subtree.
###
### This function is intended to be invoked
### through a keyboard shortcut in the process
### of typing a command (e.g. cat FILE, git 
### add FILE).
###
### _fuzzy-find will take the word that's 
### currently being typed as initial query
### for the fuzzy find. This is triggered
### when the cursor is currently on a non-
### empty character.
###
### If the cursor is not on an alphanumerical
### character, the fuzzy find is started with
### an empty query.
### 
### If the fuzzy find is aborted with ESC or 
### ^C, the prompt will be restored to the 
### condition that it was in before invoking
### _fuzzy-find.
###
### By default ignores node_modules directories.
### TODO: Add an option to set blacklist array
###		as environment variable or something.
function _fuzzy-find() {
	local query=""

	# Get the character that's currently under
	# under the cursor.
	current_char="${BUFFER: -1}"

	# Only perform backward-kill-word if we're
	# in the middle of typing a word. This means
	# that current_char should not be whitespace.
	#
	# ${var// } removes all space characters (see
	# https://unix.stackexchange.com/questions/146942/how-can-i-test-if-a-variable-is-empty-or-contains-only-spaces)
	if [[ ! -z "${current_char// }" ]]; then
		zle backward-kill-word
		# CUTBUFFER contains the result of 
		# backward-kill-word.
		query="$CUTBUFFER"
	fi

	local completion="$( \
		find . \
		! -path '*/node_modules/*' | \
		fzf -q "$query" --height=12 --reverse \
	)"

	# If a completion has been returned, append
	# it to the current buffer.
	if [[ ! -z "$completion" ]]; then
		BUFFER+="'$completion' "
	else
		# Otherwise, bring back the buffer to
		# the original state by appending back
		# the contents of query.
		BUFFER+="$query"
	fi

	# Move the curser to the end of the line
	# for easy continuation.
	zle end-of-line

	# Redisplay so the prompt shows up properly.
	zle redisplay
}

# Create a new widget from the function.
zle -N _fuzzy-find

# And bind it to control-f
bindkey "^f" _fuzzy-find
