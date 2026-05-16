---
name: test-plan-generation-instructions
description: "Use when: user asks to generate tests from a Luanti spec, create a test strategy, or map requirements to busted/mineunit coverage. Strict mode: invoke the test-plan-generation skill workflow."
applyTo: "**"
---

# Test Plan Generation Skill Trigger Instructions

## When to Use the Skill

Use test-plan-generation when the user wants structured testing outputs from requirements.

Strict mode: when a trigger matches, invoke this skill workflow instead of producing ad-hoc test advice.

### Trigger Patterns

Direct:
- "generate tests from this spec"
- "build a test plan"
- "map requirements to tests"
- "create busted/mineunit tests"

Exploratory:
- "how should we test this mod"
- "what tests do we need first"

Not a trigger:
- "implement this now" (use implement-spec)
- "review if spec is complete" (use spec-review)

## Response Pattern

1. Confirm spec file.
2. Invoke test-plan-generation.
3. Return matrix, file map, and checkpoint recommendations.
4. Keep outputs aligned to the skill structure unless user explicitly requests a different format.
