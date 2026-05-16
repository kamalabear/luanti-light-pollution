---
name: dependency-reuse-fit-instructions
description: "Use when: user asks what existing mods/libraries to build on, whether to adopt or wrap dependencies, or how to maximize reuse and extensibility in Luanti projects. Strict mode: invoke the dependency-reuse-fit skill workflow."
applyTo: "**"
---

# Dependency Reuse Fit Skill Trigger Instructions

## When to Use the Skill

Use dependency-reuse-fit when selecting external mods/libraries or defining reuse strategy.

Strict mode: when a trigger matches, invoke this skill workflow instead of ad-hoc dependency recommendations.

### Trigger Patterns

Direct:
- "what should we build on"
- "should we use an existing mod"
- "adopt or build ourselves"
- "evaluate dependency options"

Exploratory:
- "how can we keep this extensible"
- "is there a reusable library for this"

Not a trigger:
- "write the full spec" (use implementation-spec)
- "implement this spec" (use implement-spec)

## Response Pattern

1. Decompose capabilities.
2. Evaluate candidates and licenses.
3. Return adopt/wrap/replace decisions.
4. Do not skip the structured fit assessment unless the user explicitly requests a quick informal opinion.
