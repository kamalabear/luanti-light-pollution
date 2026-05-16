---
name: session-retro-instructions
description: "Use when: user indicates they are ending a session or asks for a wrap-up report. Strict mode: invoke the session-retro prompt workflow."
applyTo: "**"
---

# Session Retro Prompt Trigger Instructions

## When to Use the Prompt

Use this prompt when the user wants an end-of-session summary and improvement notes.

### Trigger Patterns

Direct:
- "end session report"
- "wrap up this session"
- "create a retrospective"
- "summarize what worked and what did not"
- "generate a session report"
- "session closeout"
- "goodnight report"
- "end-of-day wrap-up"

Exploratory:
- "before we finish, can you summarize this"
- "what should we improve next time"
- "what went well today"
- "before we stop, what should we change next time"

Not a trigger:
- "summarize this spec" (use spec-review or implementation-spec context)
- "write an implementation report" (use implement-spec/implementation-completion workflow)

## Strict Mode Rules

- When a trigger matches, invoke the session-retro prompt workflow.
- The workflow must write or append a report under `.github/session-reports/`.
- Keep findings practical and improvement-oriented.
