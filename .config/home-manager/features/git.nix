{ config, pkgs, ... }:

let
  # Lets me write a multiline zsh script for git aliases in here, but have it as a single line in result
  collapse = multiline: builtins.replaceStrings ["\n"] [" "] multiline;
in
{
  programs.git = {
    enable = true;
    userEmail = "robin@skunk.team"; # TODO: Make more modular -> Work vs private? Just in general custom profiles.
    userName = "Robin Kneepkens";

	ignores = [
		# I tend to use these directories for temp files
		".todo/"
		".scrap/"
    # Gets created by direnv. I use it for flake-defined dev environments.
    ".direnv"
	];
    
    extraConfig = {
      credential = {
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
      init = {
        defaultBranch = "main";
      };
      diff.external = collapse ''
        ${pkgs.difftastic}/bin/difft
        --color auto
        --syntax-highlight off
        --tab-width 4
        --display side-by-side-show-both
      '';
    };

    aliases = {
      # List all available aliases.
      list-alias = "!git config --global -l | grep 'alias'"; 
	  
      # Show git log with diffs using difftastic  
      dlog = collapse ''!
        dlog() { 
          GIT_EXTERNAL_DIFF=${pkgs.difftastic}/bin/difft git log -p --ext-diff $@; 
        };
        
        dlog
      ''; 
      
      # Show branching graph with commit titles in terminal. Only show local refs and remote refs relevant to them.
      olog = "log --pretty='%C(auto)%h%C(auto)%d%C(reset) %s %C(brightblack)%<(5,trunc)%an' --color=auto --decorate=short --graph"; 

      # Show branching graph with commit titles in terminal. Show all refs (also remote).
      alog = "olog --all"; 
      
      # Dense, summarized history of all commits contributing to current branch.
      plog = "log --pretty=format:'%C(yellow)%h %Cred%ad %Cgreen%an%C(cyan)%d %Creset%s' --date=short --abbrev-commit"; 
      
      # Show the last $1 commit messages. Defaults to 1 when no parameter is given.  
      last = collapse ''!
        last() { 
          [[ -z $1 ]] && amount=1 || amount=$1; 
          git log --stat -$amount HEAD; 
        }; 
        
        last
      ''; 
      
      # Return just the url of the remote repository "origin", no .git at the end.
      url = "!git config --local --get remote.origin.url | sed -e s,'\\\.git',,g"; 
      
      # Open the remote repository url in default browser. (originally from Bit Bucket, hence bb)
      bb = "!open -u $(git url)"; 
      
      # Show all tracked files in repo for current branch
      tracked = "ls-tree --full-tree --name-only -r HEAD"; 
      
      # Show a nicely formatted tree of the git repository. TODO: add .gitignore support
      lt = "!${pkgs.lsd}/bin/lsd --tree $(git rev-parse --show-toplevel)"; 
      
      # Quickly amend last commit, keeping the old message.
      amend = "commit --amend --no-edit"; 

      # Print the url of the remote reposity with the current branch checked out.
	    branch-url = "!echo $(git url)/tree/$(git branch --show-current)"; 

      # Print the url of the open PR for the current branch if it exists.  
	    pr-url = collapse ''!
        pr-url() { 
          curr=$(git branch --show-current 2> /dev/null || echo "null"); 
          if [[ "$curr" == "null" ]]; then 
            return 1;
          fi;

          ${pkgs.gh}/bin/gh api -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "/search/issues?q=head:$curr" | jq '.items[0].html_url' | sed -e s/\"//g; 
        };

        repo=$(git url 2> /dev/null); 
        if [[ ! -z "$repo" ]]; then 
          pr=$(pr-url); 
          if [[ "$pr" == "$repo"* ]]; then 
            echo "$pr";
          fi;
        fi;
      ''; 

      # Try to open Pull Request page on github of current branch.
      # If no PR exists, try to open branch in code view on github.
	    pr = collapse ''!
        try-open() {
          if [[ -n "$1" ]]; then
            echo "$1";
            open -u "$1";
            return 0;
          fi;
          
          return 1;
        };
        
        url=$(try-open "$(git pr-url)");
        if [[ -z "$url" ]]; then  
          url=$(try-open "$(git branch-url)");
          if [[ -z "$url" ]]; then
            echo "No (remote) repo";
          fi;
        fi;
      ''; 
    };
  };
}
