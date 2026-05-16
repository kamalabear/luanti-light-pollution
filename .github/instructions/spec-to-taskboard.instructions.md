---
name: spec-to-taskboard-instructions
description: "Use when: user asks to convert a Luanti spec into tasks, backlog items, or execution checklists. Strict mode: invoke the spec-to-taskboard skill workflow."
applyTo: "**"
---

# Spec to Taskboard Skill Trigger Instructions

## When to Use the Skill

Use spec-to-taskboard when a specification must be converted into actionable work items.

Strict mode: when a trigger matches, invoke this skill workflow instead of producing ad-hoc task lists.

### Trigger Patterns

Direct:
- "turn this spec into tasks"
- "create a backlog"
- "make an implementation checklist"
- "plan the work items"

Exploratory:
- "what should we implement first"
- "how do we organize this work"

Not a trigger:
- "create a new spec" (use implementation-spec)
- "review spec quality" (use spec-review)

## Response Pattern

1. Parse requirements and constraints.
2. Generate dependency-aware tasks with acceptance criteria.
3. Map tasks to iteration and tests.
4. Keep acceptance criteria behavior-based and traceable to requirement statements.
