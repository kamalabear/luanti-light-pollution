---
name: bug-triage-instructions
description: "Use when: user reports a Luanti bug and needs consistent triage before fixing. Strict mode: invoke the bug-triage prompt workflow."
applyTo: "**"
---

# Bug Triage Prompt Trigger Instructions

## When to Use the Prompt

Use this prompt whenever a bug report needs structured reproduction and scope definition.

### Trigger Patterns

Direct:
- "I found a bug"
- "help me triage this issue"
- "this is broken"
- "can you investigate this defect"

Exploratory:
- "sometimes this behavior fails"
- "not sure if this is a bug or expected"

Not a trigger:
- "implement this planned feature" (use implement-spec)
- "review this spec" (use spec-review)

## Strict Mode Rules

- When a trigger matches, invoke the bug-triage prompt workflow.
- Capture reproducibility and minimal failing behavior before proposing broad fixes.
