---
name: back-to-main
description: Switch back to main branch, pull latest, and delete the previous branch. Use when the user wants to return to main, clean up after a PR, or reset to the main branch. Triggers on phrases like "go back to main", "switch to main", "clean up branch", "back to main".
---

# Back to Main

Switch to the main branch, pull the latest changes, and delete the branch you were on.

## Steps

1. Get the current branch name using `git branch --show-current`
2. If already on main, just pull latest and inform the user
3. If on a different branch:
   - Store the branch name
   - Run `git checkout main`
   - Run `git pull`
   - Delete the previous branch with `git branch -D <branch-name>`
4. Report what was done

## Important

- Never delete the main branch
- Use `git branch -D` (force delete) since the branch may not be fully merged
- If there are uncommitted changes, warn the user and stop — do not force checkout
- Always confirm the branch deletion in the output message
