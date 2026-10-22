{
  config,
  lib,
  ...
}:
let
  hybrid-workspace-file = "${config.xdg.configHome}/zsh/user-widgets/hybrid-workspace.zsh";
in
{
  programs.zsh.initContent = lib.mkBefore "source ${hybrid-workspace-file}";
  home.file.hybrid-workspace = {
    target = hybrid-workspace-file;
    enable = true;
    text = ''
      ## Hybrid Workspace Helpers (Git Worktree + Jujutsu Workspace)
      ###
      ### Manage secondary workspaces that are simultaneously registered as
      ### a Jujutsu workspace (`jj workspace`) and a Git worktree (`git worktree`)
      ### backed by the primary colocated repository.

      ### Locate the primary colocated jj/git repository from:
      ###   1. Inside the primary repo or any secondary jj workspace (or subdirectory)
      ###   2. Inside a git worktree whose primary repo has `.jj/repo`
      ###   3. A parent container directory holding a single primary repo subdirectory
      function _jj-main-repo() {
        local ws_root common_git
        if ws_root=$(jj --no-pager --ignore-working-copy workspace root 2>/dev/null); then
          if [[ -d "$ws_root/.jj/repo" ]]; then
            print -r -- "''${ws_root:P}"
            return 0
          elif [[ -f "$ws_root/.jj/repo" ]]; then
            local ptr="$(<"$ws_root/.jj/repo")"
            [[ "$ptr" != /* ]] && ptr="$ws_root/.jj/$ptr"
            print -r -- "''${ptr:P:h:h}"
            return 0
          fi
        fi

        if common_git=$(git --no-pager rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
          local git_root="''${common_git:h:P}"
          if [[ -d "$git_root/.jj/repo" ]]; then
            print -r -- "$git_root"
            return 0
          fi
        fi

        # Fallback: look for a direct child directory that owns a primary .jj/repo directory
        local -a roots=( */.jj/repo(/N:h:h:P) )
        if (( ''${#roots} == 1 )); then
          print -r -- "''${roots[1]}"
          return 0
        elif (( ''${#roots} > 1 )); then
          print -u2 "Multiple jj repositories found in $PWD: ''${roots:t}"
          return 1
        fi

        print -u2 "Could not locate a colocated jj/git repository."
        return 1
      }

      ### Create a hybrid Jujutsu workspace + Git worktree.
      ###
      ### Usage:
      ###   hybrid-workspace-add <name-or-path> [revset]
      function hybrid-workspace-add() {
        if [[ -z "$1" ]]; then
          print -u2 "Usage: hybrid-workspace-add <name-or-path> [revset]"
          return 1
        fi

        local repo
        repo=$(_jj-main-repo) || return 1

        # Bare names become siblings of the primary repo; paths with "/" resolve from $PWD
        local dest
        if [[ "$1" == */* ]]; then
          dest="''${1:P}"
        else
          dest="''${repo:h}/$1"
        fi
        local ws_name="''${dest:t}"
        local rev="''${2:-coalesce(trunk() ~ root(), @-)}"

        if [[ -e "$dest" ]]; then
          print -u2 "Destination already exists: $dest"
          return 1
        fi

        # Resolve to a single commit ID upfront so invalid/ambiguous revsets fail cleanly
        local -a commits
        commits=( ''${(f)"$(jj -R "$repo" --no-pager --ignore-working-copy log --no-graph -r "$rev" -T 'commit_id ++ "\n"')"} )
        if (( ''${#commits} == 0 )) || [[ -z "''${commits[1]}" ]]; then
          print -u2 "Revision '$rev' did not match any commits."
          return 1
        elif (( ''${#commits} > 1 )); then
          print -u2 "Revision '$rev' matched ''${#commits} commits; pass a single revision."
          return 1
        fi
        local commit="''${commits[1]}"

        git -C "$repo" --no-pager worktree add --no-checkout --detach "$dest" "$commit" || return 1
        local gitfile="$(<"$dest/.git")"
        rm -f "$dest/.git" && rmdir "$dest"

        if ! jj -R "$repo" --no-pager workspace add --name "$ws_name" "$dest" -r "$commit"; then
          git -C "$repo" --no-pager worktree prune
          return 1
        fi

        print -r -- "$gitfile" > "$dest/.git"
        print -r -- "/*" > "$dest/.jj/.gitignore"
        git -C "$dest" --no-pager reset -q

        if [[ -f "$dest/.envrc" ]] && (( $+commands[direnv] )); then
          direnv allow "$dest"
        fi
      }

      ### Remove a hybrid Jujutsu workspace + Git worktree.
      ###
      ### Usage:
      ###   hybrid-workspace-remove [name-or-path]
      function hybrid-workspace-remove() {
        local repo
        repo=$(_jj-main-repo) || return 1

        local target="$1"
        if [[ -z "$target" ]]; then
          if (( $+commands[fzf] )); then
            target=$(
              jj -R "$repo" --no-pager --ignore-working-copy workspace list \
                -T 'if(name != "default", name ++ "\n")' \
                | fzf --reverse --height=10 --prompt="Remove workspace > "
            )
          fi
          [[ -z "$target" ]] && { print -u2 "Usage: hybrid-workspace-remove <name-or-path>"; return 1; }
        fi

        # Resolve both workspace name and root path from jj's workspace store
        local ws_name ws_path line name root_path target_abs="''${target:P}"
        for line in ''${(f)"$(jj -R "$repo" --no-pager --ignore-working-copy workspace list -T 'name ++ "\t" ++ self.root() ++ "\n"')"}; do
          name="''${line%%$'\t'*}"
          root_path="''${line#*$'\t'}"
          [[ -n "$root_path" ]] && root_path="''${root_path:P}"
          if [[ "$target" == "$name" || ( -n "$root_path" && ( "$target_abs" == "$root_path" || "$target_abs" == "$root_path"/* ) ) ]]; then
            ws_name="$name"
            ws_path="$root_path"
            break
          fi
        done

        # Fallback if the workspace was already forgotten in jj but still exists as a git worktree
        if [[ -z "$ws_path" ]]; then
          if [[ "$target" == */* ]]; then
            ws_path="$target_abs"
          else
            ws_path="''${repo:h}/$target"
          fi
          ws_name="''${ws_path:t}"
        fi

        if [[ "$ws_name" == "default" || "$ws_path" == "$repo" ]]; then
          print -u2 "Refusing to remove the primary repository workspace ($repo)."
          return 1
        fi

        # Step out of the workspace if the current shell is inside it
        if [[ "''${PWD:P}" == "$ws_path" || "''${PWD:P}" == "$ws_path"/* ]]; then
          builtin cd "''${repo:h}"
        fi

        jj -R "$repo" --no-pager workspace forget "$ws_name" 2>/dev/null || true
        git -C "$repo" --no-pager worktree remove --force "$ws_path"
      }
    '';
  };
}
