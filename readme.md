# Git Bash RTC Helper

Tired of manually typing the RTC ticket number into your commit message every
time?

With a little setup, this is a thing of the past. Just set the RTC number once
when you start working on a branch and you're ready to go.

You'll be able to:
- use `setRTC XXXXXX` to set the RTC ticket number in the current branch 
  to `XXXXXX` and automatically run `patchHooks` if it was the first time.
- use `patchHooks` to replace the standard git hooks with better ones that
  support the new RTC tracking. Also can extract RTC ticket numbers from 
  branch names.
- Have git bash always show you the RTC ticket number for your current branch.

## Installation

Installation and updating is fully taken care of by an installer script. In turn, downloading and running the installer script can easily be executed from git bash:

- Open a git bash instance anywhere
- Run the following command:  
  ```
  curl "http://git.eu.paccar.com:7990/users/robin.kneepkens/repos/dotfiles/raw/installGitbashRTC.sh?at=refs%2Fheads%2Fmain" --output "$HOME"'/installGitbashRTC.sh' && cd "$HOME" && ./installGitbashRTC.sh && source .bashrc
  ```

This will download and run the [installer script](http://git.eu.paccar.com:7990/users/robin.kneepkens/repos/dotfiles/browse/installGitbashRTC.sh).

You can test if installation was successful by calling `setRTC` in your current git bash. This should give an error message like `Not a git repository`.

To update to the latest versions of the relevant files, just run `installGitbashRTC.sh` again. This file will be located in your user home directory.

## Usage

The usage is as straightforward as can be. Call `setRTC XXXXXX` in the git repo
with the branch you want to set the ticket number of checked out. Replace 
`XXXXXX` with your RTC ticket number.

If this is the first time using these scripts in a repository, `patchHooks` will
be called automatically and a file called `.rtc` will be created at the root 
of the repository. You're now ready to go:

- Calling `git commit` will open your default text editor with "[RTC:XXXXXX]"  
  or "[RTC:\<ticket-number\>]" as a default message depending on whether a  
  ticket number has been set.
- Calling `git commit -m "This is a commit message"` will also prepend your message  
  with the tag.
- In all cases, if no RTC ticket number can be found for the current branch in the `.rtc`  
  file, an attempt will be made to extract an RTC ticket number from the branch name.  
  It will look for the substring "RTC" followed by 6 digits in the branch name.

If you need to update the RTC ticket number of the current branch, simply call `setRTC` again with the new number

If you want to disable RTC tracking again, delete the `.rtc` file at the root directory of the git repository.

## What's Introduced?

### Bash functions

Running the installer will make the following functions available in your git bash:  
- `currBranch`: Returns the current branch name if we're in a git repo 
  otherwise returns empty string.
- `setRTC`: Set the RTC ticket number for the current branch.
- `getRTC`: Returns the RTC ticket number of the current branch after
  it has been set using `setRTC`.
- `gitPS1RTC`: Output a nicely formatted RTC tag containing the 
  RTC number set for this branch.
- `patchHooks`: Patch the git hooks in the current git repository.

___

### Better git hooks

Git hooks are scripts that get invoked at certain points during the git workflow, like right before commiting or after adding.

At DAF, there are a few hooks in place to generate a template commit message and to check the format of the commit message to ensure a valid RTC tag is at the start of the message.

To make sure our commit message templates contain the RTC ticket number as tracked with `setRTC`, the default git hooks need to be overriden. This can be done automatically with `patchHooks`. Additionally, `setRTC` will call `patchHooks` if it doesn't find an existing `.rtc` file in the git repo.

This is what's been changed to the git hooks:

- `prepare-commit-msg`: This hook runs just after executing `git commit` and
  generates the template commit message.  
  This patch makes it so the commit message will contain the RTC ticket number
  as set with `setRTC`. This also works for commit messages created with:  
  ```
  git commit -m "Message"  
  # Resulting commit message: [RTC:XXXXXX] Message
  ```
  This updated hook will also be able to retrieve an RTC ticket number from 
  the current branch name, even if no RTC number has been set with `setRTC`.
  It will look for the sequence `RTC` followed by six digits in the branch
  name and use that.  
  RTC tags set with `setRTC` have priority over RTC tags in the branch name.
- `commit-msg`: This hook validates the content of the commit message
  to see if it follows policy guidelines.  
  This patch removes the annoying behaviour where it would open a Teams 
  channel in your browser if you have an incorrect commit message.  
  Additionally, the output formatting has been improved a bit and the incorrect
  commit message will be printed in the command line for easy copy-pasting and 
  adjusting it.

___

### Improved git prompt

When tracking RTC tickets with `setRTC`, it's useful to be able to see what RTC ticket is set for the current branch. The updated git prompt will display exactly that before the branch name.

If no valid RTC number can be found for this branch, a placeholder `[RTC:XXXXXX]` will be used.

Note, the default git prompt is not very pretty. Feel free to experiment with
the `git-prompt.sh` file. My personal prompt can be found in `.config/git/git-prompt.sh`.

This prompt also has a little function to display the Model Year you're currently working in.

Other ways to customise your git bash is through color themes (see `.mintty/themes`) and `.minttyrc`

## Troubleshooting

Contact Robin Kneepkens if you have any questions or suggestions.

## Features to add in the future

- Add `unpatchHooks` to revert to the original git hooks when necessary.

___

# Dotfile Backup
[Source](https://www.atlassian.com/git/tutorials/dotfiles) for more elaboration on the steps.  
**NOTE:** In my setup, I renamed `/.cfg` to `/.dotfiles` and the `config` alias to `dotfile`.

## Creating a repo to manage dotfiles in user home directory:
```
git init --bare $HOME/.dotfiles
alias dotfile='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfile config --local status.showUntrackedFiles no
echo "alias dotfile='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> $HOME/.bashrc
```

After this setup, dotfiles should be managed like one normally would, but using `dotfile` instead of `git`:
```
dotfile status
dotfile add .vimrc
dotfile commit -m "Add vimrc"
dotfile add .bashrc
dotfile commit -m "Add bashrc"
dotfile push
```

## Restoring from repo to new machine:
**The commands below overwrite any existing files with the same name, so be cautious!**

```
cd ~
git clone --bare http://git.eu.paccar.com:7990/scm/~robin.kneepkens/dotfiles.git $HOME/.dotfiles
alias dotfile='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfile checkout --force
dotfile config --local status.showUntrackedFiles no
```
