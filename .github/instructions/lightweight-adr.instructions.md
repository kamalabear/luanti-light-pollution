---
name: luanti-lightweight-decision-pattern
description: "Use when: specs include significant architecture or dependency decisions. Strict mode: require a lightweight decision block in the Decision Log section for traceability."
applyTo: "**"
---

# Lightweight Decision Pattern

For significant decisions, add entries to the spec Decision Log section using this exact block.

## Decision Block Template

Decision: <short statement>
Alternatives considered: <option A, option B, option C>
Why chosen: <reason tied to requirements and constraints>
Impact: <tradeoffs, migration implications, testing implications>

## What Counts as Significant

- Dependency adopt/wrap/replace choices
- Module boundary definitions
- Data model shape changes
- Engine callback strategy changes
- Test strategy changes affecting coverage confidence

## Enforcement

- Do not leave major design changes undocumented.
- Keep entries concise and requirement-linked.
