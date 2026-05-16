---
name: changelog-discipline
description: "Use when: completing a logical change set. Strict mode: add or update a concise changelog entry before commit and push."
applyTo: "**"
---

# Changelog Discipline

Maintain a lightweight human-readable changelog in each workspace.

## Default Behavior

- Keep a top-level `CHANGELOG.md` file.
- For each logical change set, add one concise entry before commit/push.
- Entries should summarize user-visible/logical outcomes, not line-by-line diffs.

## Entry Template

Use this structure:

- Date/Time
- Change title
- Why it changed
- Impact
- Follow-up actions (optional)

## Helper Command

Use the local helper when available:

`powershell -NoProfile -ExecutionPolicy Bypass -File .vscode/add-changelog-entry.ps1 -Title "<change title>" -Why "<reason>" -Impact "<impact>" -FollowUp "<optional>"`

## Enforcement

- Do not mark a logical change set complete without changelog coverage unless user explicitly opts out.
- If a changelog update is skipped, state the reason in the final report.
