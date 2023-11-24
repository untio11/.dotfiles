{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "robin@skunk.team"; # TODO: Make more modular -> Work vs private? Just in general custom profiles.
    userName = "Robin Kneepkens";
    
    extraConfig = {
      credential = {
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
    };

    aliases = {
      list-alias = "! git config --global -l | grep 'alias'"; # List all available aliases.
      
      olog = "log --oneline --graph --all"; # Show branching graph with commit titles in terminal.
      
      plog = "log --pretty=format:'%C(yellow)%h %Cred%ad %Cgreen%an%C(cyan)%d %Creset%s' --date=short --abbrev-commit"; # Dense, summarized history of all commits contributing to current branch.
      
      last = "! f() { [[ -z $1 ]] && amount=1 || amount=$1; git log --stat -$amount HEAD; }; f"; # Show the last $1 commit messages. Defaults to 1 when no parameter is given.
      
      url = "config --local --get remote.origin.url"; # Return just the url of the remote repository "origin".
      
      bb = "!open -u `git url`"; # Open the remote repository url in default browser. (originally from Bit Bucket, hence 'bb')
      
      restore = "!git clean -dfX && git reset --hard @"; # Bring tracked files to initial state of current commit. Will only delete files in .gitignore
      
      nuke = "!git clean -dfx && git reset --hard @"; # Bring repository to initial state for current commit. Will delete ALL files that are not in remote.
      
      tracked = "ls-tree --full-tree --name-only -r HEAD"; # Show all tracked files in repo for current branch
      
      lt = "!${pkgs.lsd}/bin/lsd --tree $(git rev-parse --show-toplevel)"; # Show a nicely formatted tree of the git repository (requires lsd-rs)
      
      amend = "commit --amend --no-edit"; # Quickly amend last commit, keeping the old message.
    };
  };
}