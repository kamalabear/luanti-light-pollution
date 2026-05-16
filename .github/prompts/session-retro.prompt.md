---
name: session-retro
description: "Generate an end-of-session collaboration report that captures what worked, what did not, and concrete adjustments for next time."
---

# Session Retrospective Report

Use this prompt when a session is ending and the user wants to improve collaboration quality over time.

## Objectives

1. Preserve a concise record of the session.
2. Identify what worked well.
3. Identify friction and what did not work well.
4. Define practical adjustments for the next session.

## Report Output

Create or update a markdown report file in:

- `.github/session-reports/`

Filename pattern:

- `session-retro-YYYY-MM-DD.md`

If the file already exists for the same date, append a new `## Session Entry` section instead of creating a duplicate file.

## Report Structure

Use this structure for each entry:

### Session Entry

- Date/Time
- High-level objective(s)
- Outcomes delivered
- Key files changed
- Tests/validation run (and results)

### What Worked Well

- Collaboration patterns that were effective
- Prompt styles that produced better outcomes
- Workflow choices that improved speed/quality

### What Did Not Work Well

- Miscommunications or unclear requests
- Process friction
- Tooling/environment blockers

### Improvements for Next Session

- Keep doing
- Start doing
- Stop doing

### Next Session Starting Point

- Recommended first prompt
- Open questions
- Immediate next tasks

## Constraints

- Keep the report actionable and concise.
- Do not include secrets or sensitive tokens.
- Prefer factual outcomes over vague commentary.
