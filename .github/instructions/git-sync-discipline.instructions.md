---
name: git-sync-discipline
description: "Use when: completing a logical change set in this workspace. Strict mode: commit and push each logical update unless the user explicitly opts out or a git blocker prevents it."
applyTo: "**"
---

# Git Sync Discipline

Keep the remote repository current with logical checkpoints.

## Default Behavior

- Before commit/push, add or update one concise changelog entry for the logical update.
- After a meaningful set of file changes is validated, commit it with a clear message and push it to the current remote.
- Prefer one commit per logical update, not one commit per tiny edit.
- If a task spans multiple logical milestones, commit and push each completed milestone.

## Commit Guidance

- Use concise, descriptive commit messages.
- Match the message to the implemented slice, for example:
  - `Add iteration planning skill`
  - `Enforce certification gate in implementation workflow`
  - `Add workflow sync bootstrap tooling`

## Helper Command

Use these helpers when appropriate:

`powershell -NoProfile -ExecutionPolicy Bypass -File .vscode/add-changelog-entry.ps1 -Title "<logical update title>" -Why "<why>" -Impact "<impact>" -FollowUp "<optional>"`

`powershell -NoProfile -ExecutionPolicy Bypass -File .vscode/commit-and-push.ps1 -Message "<logical update message>"`

## Blockers

If commit or push cannot be completed:

- Report the exact blocker.
- Leave the workspace in a clean, understandable state.
- Provide the next git command path needed to complete sync.
