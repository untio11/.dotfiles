{ pkgs, config, ... }:

let 
  changelog-shortcut-file = "${config.xdg.configHome}/zsh/user-widgets/changelog-shortcut.zsh";
in
{
	programs.zsh.initExtraFirst = "source ${changelog-shortcut-file}";
  home.file.changelog-shortcut = {
    target = changelog-shortcut-file;
    enable = true;
    text = ''## Automate some common steps when creating changelog entries for usr.
      ###
      ### See the big-ass echo block down below for instructions.
      ### Or just call the function with no arguments.
      ### 
      ### Return value codes:
      ###   0: success
      ###   1: No changelog directory found.
      ###   2: Invalid/No changelog category provided.
      function changelog() {
      	PR_NUMBER="$1"
      	CATEGORY="$2"
      	[[ ! -z $3 ]] && SEQUENCE_NR=".$3" || SEQUENCE_NR=""

      	if [[ ! -d "./changelog" ]]; then
      		echo "Changelog directory not found:"
      		echo "    ./changelog"
      		return 1
      	fi

      	if [[ -z $CATEGORY ]]; then
      		echo "Changelog entry category cannot be empty"
      		echo
      		echo "Command usage:"
      		echo "    changelog [PR_NUMBER] [CATEGORY] [SEQUENCE_NR?]"
      		echo 
      		echo "With:"
      		echo "    [PR_NUMBER]:      Number of the PR. Don't provide leading '#'"
      		echo "    [CATEGORY]:       One of {" $(ls ./changelog/draft | sed -E 's,([a-z]+)/,"\1",g') "}"
      		echo "    [SEQUENCE_NR?]:   Optional sequence number when you want to add more changelog entries per PR"
      		echo
      		return 2
      	fi

      	if [[ -d "./changelog/draft/$CATEGORY" ]]; then
      		ENTRY="./changelog/draft/$CATEGORY/$PR_NUMBER$SEQUENCE_NR.md"
      		touch "$ENTRY"
      		code "$ENTRY" "./changelog/README.md"
      		return 0
      	fi

      	echo "Cant find:"
      	echo "    ./changelog/draft/$CATEGORY"
      	return 2
      }
    '';
  };
}
