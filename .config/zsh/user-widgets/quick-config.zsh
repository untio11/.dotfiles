### ================
### quick-config
### ================
###
### Initiate a fuzzy find of config files
### starting at $XDG_CONFIG_HOME (~/.config
### as set by my ~/.zshenv)
### 
### Makes available `ec` and `rc` for use

### Base function for initiating the fuzzy
### find in the config directory.
### Blacklist directories by adding them 
### as `! -path '*/DIR_NAME/*'`
###
### Input:
### 	$@: First argument should be initial 
###			query for fzf to narrow down the
###			initially shown content.
###			The rest of the arguments can be
###			used to configure fzf as normal.
###
### Output:
###		Print the fzf selection to stdout.
###
### Exit Status (from fzf):
###		0: OK
###		1: No match
###		2: Error
###		130: Interrupted with ^c or ESC.
function _c() {
	find "$XDG_CONFIG_HOME" \
		-type f \
		! -path '*/gcloud/*' \
		! -path '*/.zsh_sessions/*' \
		! -path '*/automatic_backups/*' \
		| fzf -q "$1"
}

### Use _c to find a config file and edit
### it in the default text editor.
function ec() {
	result=$(_c "$@")
	
	# Only run the command if fzf
	# exited successfully.
	if [[ $? == 0 ]]; then
		eval "$EDITOR $result"
		# print -s also puts the performed 
		# command in the history for better
		# ux.
		print -s "$EDITOR $result"
	fi
}

### Use _c to find a config file and source
### it into the current shell session.
function rc() {
	result=$(_c "$@")

	# Only run the command if fzf
	# exited successfully.
	if [[ $? == 0 ]]; then
		source "$result"
		# print -s puts the command in the
		# history.
		print -s "source $result"
	fi
}
