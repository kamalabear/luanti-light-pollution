---
name: implement-spec-instructions
description: "Use when: user asks to implement a spec, build an iteration, or execute planned requirements for a Luanti project. Strict mode: invoke the implement-spec skill workflow."
applyTo: "**"
---

# Implement Spec Skill Trigger Instructions

## When to Use the Skill

Use the implement-spec skill when the user wants execution, not planning.

Strict mode: when a trigger matches, invoke this skill workflow instead of handling implementation requests ad-hoc.

### Trigger Patterns

Direct:
- "implement this spec"
- "build iteration 1"
- "start coding this"
- "execute the plan"
- "implement these requirements"

Exploratory:
- "can you build this now?"
- "let's start implementing"
- "turn this into code"

Not a trigger:
- "help me create a spec" (use implementation-spec)
- "review my spec" (use spec-review)
- "break this into phases" (use iteration-planning)

## Response Pattern

1. Acknowledge implementation request.
2. Confirm target spec and scope.
3. Invoke implement-spec workflow.
4. Continue within the skill workflow until the request is completed or genuinely blocked.
5. Include tests, validation/certification, test-environment deployment (or blocker path), and final implementation report.
6. End with commit + push for the logical change set unless the user explicitly opts out or a git blocker prevents it.
