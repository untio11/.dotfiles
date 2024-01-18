{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "robin@skunk.team"; # TODO: Make more modular -> Work vs private? Just in general custom profiles.
    userName = "Robin Kneepkens";

	ignores = [
		".todo/"
	];
    
    extraConfig = {
      credential = {
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
    };

    aliases = {
      list-alias = "! git config --global -l | grep 'alias'"; # List all available aliases.
      
      olog = "log --pretty='%C(auto)%h%C(auto)%d%C(reset) %s %C(brightblack)%<(5,trunc)%an' --color=auto --decorate=short --graph"; # Show branching graph with commit titles in terminal. Only show local refs and remote refs relevant to them.

      alog = "olog --all"; # Show branching graph with commit titles in terminal. Show all refs (also remote).
      
      plog = "log --pretty=format:'%C(yellow)%h %Cred%ad %Cgreen%an%C(cyan)%d %Creset%s' --date=short --abbrev-commit"; # Dense, summarized history of all commits contributing to current branch.
      
      last = "! f() { [[ -z $1 ]] && amount=1 || amount=$1; git log --stat -$amount HEAD; }; f"; # Show the last $1 commit messages. Defaults to 1 when no parameter is given.
      
      url = "! git config --local --get remote.origin.url | sed -e s,'\\\.git',,g"; # Return just the url of the remote repository "origin", no .git at the end.
      
      bb = "!open -u `git url`"; # Open the remote repository url in default browser. (originally from Bit Bucket, hence 'bb')
      
      restore = "!git clean -dfX && git reset --hard @"; # Bring tracked files to initial state of current commit. Will only delete files in .gitignore
      
      nuke = "!git clean -dfx && git reset --hard @"; # Bring repository to initial state for current commit. Will delete ALL files that are not in remote.
      
      tracked = "ls-tree --full-tree --name-only -r HEAD"; # Show all tracked files in repo for current branch
      
      lt = "!${pkgs.lsd}/bin/lsd --tree $(git rev-parse --show-toplevel)"; # Show a nicely formatted tree of the git repository (requires lsd-rs)
      
      amend = "commit --amend --no-edit"; # Quickly amend last commit, keeping the old message.

	  branch-url = "!echo `git url`/tree/`git branch --show-current`"; # Print the url of the remote reposity with the current branch checked out.

	  pr-url = "! pr-url() { curr=`git branch --show-current 2> /dev/null || echo null`; if [[ \"$curr\" = null ]]; then return 1; fi; ${pkgs.gh}/bin/gh api -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' \"/search/issues?q=head:$curr\" | jq '.items[0].html_url' | sed -e s/\\\"//g; }; pr=`pr-url`; repo=`git url 2> /dev/null`; if [[ ! -z $repo ]]; then if [[ \"$pr\" == \"$repo\"* ]]; then echo $pr; fi; fi; "; # Print the url of the open PR for the current branch if it exists.

	  pr = "! url=\"`git pr-url`\"; open -u `[[ -n \"$url\" ]] && echo \"$url\" || git branch-url 2> /dev/null` 2> /dev/null && echo \"`[[ -n \"$url\" ]] && echo \"$url\" || git branch-url;`\" || echo \"No (remote) repo.\""; # Open PR (if it exists) of current branch in browser
    };
  };
}
