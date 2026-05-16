---
name: pr-review-checklist-instructions
description: "Use when: user asks for code review, merge readiness, or validation of a Luanti change set. Strict mode: invoke the pr-review-checklist prompt workflow."
applyTo: "**"
---

# PR Review Checklist Prompt Trigger Instructions

## When to Use the Prompt

Use this prompt for structured review of proposed changes.

### Trigger Patterns

Direct:
- "review this PR"
- "is this ready to merge"
- "can you do a code review"
- "check this change set"

Exploratory:
- "what risks do you see before merge"
- "did I miss anything important"

Not a trigger:
- "create a new spec" (use implementation-spec)
- "implement this" (use implement-spec)

## Strict Mode Rules

- When a trigger matches, invoke the pr-review-checklist prompt workflow.
- Present findings first, ordered by severity, with concrete file references.
