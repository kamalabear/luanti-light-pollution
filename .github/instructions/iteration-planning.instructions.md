---
name: iteration-planning-instructions
description: "Use when: user asks to break a large Luanti project into phases, iterations, or smallest testable slices. Strict mode: invoke the iteration-planning skill workflow."
applyTo: "**"
---

# Iteration Planning Skill Trigger Instructions

## When to Use the Skill

Use iteration-planning to split large scope into independently testable increments.

Strict mode: when a trigger matches, invoke this skill workflow instead of giving unstructured phase suggestions.

### Trigger Patterns

Direct:
- "break this into iterations"
- "plan phases"
- "this feels too big for one cycle"
- "split this into milestones"

Exploratory:
- "how should we sequence this"
- "what should iteration 1 include"

Not a trigger:
- "review this existing spec" (use spec-review)
- "implement this now" (use implement-spec)

## Response Pattern

1. Ask for priorities and hard dependencies.
2. Propose iteration map.
3. Produce overview spec + per-iteration specs.
4. Keep iteration outputs in the skill-defined structure unless user explicitly asks for a different format.
