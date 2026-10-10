---
name: git-worktrees
description: Isolated feature work via git worktrees - create, list, remove, prune, repair when tree is dirty, parallel branches, or urgent fix needed
---

Use a linked worktree for isolation when the tree is dirty, branches must run in parallel, or an urgent fix can't disturb current work. Detect first. Never nest worktrees.

## Detect

```
git worktree list
GIT_DIR=$(git rev-parse --git-dir); GIT_COMMON=$(git rev-parse --git-common-dir)
git rev-parse --show-superproject-working-tree
```

- `GIT_DIR != GIT_COMMON` + superproject empty: already in linked worktree. Skip creation.
- Superproject non-empty: submodule, treat as normal repo.
- `GIT_DIR == GIT_COMMON`: normal checkout, may create.

One branch = one worktree. Same branch checked out twice fails unless `--force`.

## Create

Default path `.worktrees/<branch>` at repo root. Explicit user path wins. Fallback to sibling `../<repo>-<branch>` on sandbox denial. Target dir must be missing or empty.

```
git check-ignore -q .worktrees || { echo ".worktrees/" >> .gitignore; git add .gitignore; git commit -m "ignore worktrees"; }
git worktree add .worktrees/<branch> -b <branch> [<commit-ish>]
```

- Omit `<commit-ish>`: defaults to `HEAD`. Basename becomes branch if `-b` omitted and branch missing; if branch exists it is checked out or the command refuses.
- Existing branch in new worktree: `git worktree add <path> <branch>`
- Throwaway / no branch: `git worktree add -d <path> [<commit-ish>]`
- Remote guess: `--guess-remote` bases `<branch>` on unique remote match, sets upstream.
- If outside cwd and it becomes primary workspace, move session there via `session_move`.

Then run project setup + baseline tests per project `AGENTS.md`. Dirty baseline: report, ask before proceeding.

## Cleanup

```
git worktree list -v
git worktree remove <path>            # clean only
git worktree remove --force <path>    # dirty or has submodules
git worktree prune -n; git worktree prune -v
git worktree repair [<path>...]       # after manual move of main or linked tree
git worktree lock --reason "<why>" <path>; git worktree unlock <path>
git worktree move <path> <new-path>   # no main tree, no submodules
```

- Never `rm` a worktree dir manually; always `remove`. If already deleted manually, `prune` stale admin under `$GIT_DIR/worktrees`.
- Locked = no prune/move/remove (needs double `--force` to override).
- Per-worktree: `HEAD`, index, `refs/worktree/*`, `refs/bisect/*`. Shared: everything under `refs/heads/*`. Use `git rev-parse --git-path <p>` before touching `$GIT_DIR` directly.

## Anti-patterns

- Skipping `list` / detect and nesting a worktree inside a worktree.
- Creating under unignored `.worktrees` (commits whole tree into repo).
- `rm -rf` instead of `remove` + `prune`.
- Reusing a branch already checked out elsewhere without `--force` understanding.
- Skipping baseline tests; later failures become ambiguous.
