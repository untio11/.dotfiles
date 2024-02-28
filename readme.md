# Dotfile Backup
[Source](https://www.atlassian.com/git/tutorials/dotfiles) for more elaboration on the steps.  
**NOTE:** In my setup, I renamed `/.cfg` to `/.dotfiles` and the `config` alias to `dotfile`.

## Creating a repo to manage dotfiles in user home directory:
```
git init --bare $HOME/.dotfiles
alias dotfile='git --work-tree=$HOME --git-dir=$HOME/.dotfiles'
dotfile config --local status.showUntrackedFiles no

# Consider adding the alias to your shell config:
echo "alias dotfile='git --work-tree=$HOME' --git-dir=$HOME/.dotfiles" >> $HOME/.bashrc
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
git clone --bare https://github.com/untio11/.dotfiles.git $HOME/.dotfiles
alias dotfile='git --work-tree=$HOME --git-dir=$HOME/.dotfiles'
dotfile config --local status.showUntrackedFiles no

# Careful!
dotfile checkout --force
```
