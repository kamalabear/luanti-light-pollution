---
name: session-recovery-gate
description: "Use when: a session starts and `.github/session-reports/retro-pending.flag` exists. Strict mode: require a catch-up retro prompt before normal implementation flow unless user explicitly skips."
applyTo: "**"
---

# Session Recovery Gate

## Trigger

Use this gate when a new session begins and `.github/session-reports/retro-pending.flag` is present.

## Strict Mode Rules

- Before starting major new work, ask whether to run `session-catchup-retro` now.
- If user agrees, run the catch-up retro workflow first.
- If user declines, proceed but note that retro was skipped for this session.

## Prompting Pattern

Use a concise prompt:

"I found a pending session retro flag from a previous session. Do you want me to generate a catch-up retro before we continue?"
