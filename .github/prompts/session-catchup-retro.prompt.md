---
name: session-catchup-retro
description: "Generate a catch-up retrospective when a previous session ended without a closeout report."
---

# Session Catch-up Retro

Use this prompt when `.github/session-reports/retro-pending.flag` exists or when a prior session ended without a formal retro.

## Inputs

1. What work was completed in the prior session
2. What worked well
3. What did not work well
4. Any blockers or environment issues
5. What should change next session

## Output

Append a `## Session Entry` in:

- `.github/session-reports/session-retro-YYYY-MM-DD.md`

Also include a short `## Catch-up Source` line explaining this was reconstructed after IDE close or abrupt stop.

## Post-Write Action

- Remove `.github/session-reports/retro-pending.flag` if it exists.

## Quality Rules

- Keep entries concise and actionable.
- Tie insights to concrete examples from the prior work.
- End with 1-3 immediate next actions.
