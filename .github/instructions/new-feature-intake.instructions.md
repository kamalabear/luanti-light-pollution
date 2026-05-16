---
name: new-feature-intake-instructions
description: "Use when: user shares a new Luanti feature idea and needs structured intake before spec creation. Strict mode: invoke the new-feature-intake prompt workflow."
applyTo: "**"
---

# New Feature Intake Prompt Trigger Instructions

## When to Use the Prompt

Use this prompt when the user is at idea or requirement-gathering stage for a new feature.

### Trigger Patterns

Direct:
- "I have a feature idea"
- "help me define this feature"
- "let's scope a new feature"
- "what should this feature include"

Exploratory:
- "I want to add something but not sure of scope"
- "can you help me think through requirements"

Not a trigger:
- "create the full spec" (use implementation-spec)
- "review this spec" (use spec-review)
- "implement this now" (use implement-spec)

## Strict Mode Rules

- When a trigger matches, invoke the new-feature-intake prompt workflow.
- Do not skip directly to implementation planning before intake is complete unless user explicitly requests to bypass intake.
