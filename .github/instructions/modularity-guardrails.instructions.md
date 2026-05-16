---
name: luanti-modularity-guardrails
description: "Use when: designing or implementing Luanti features. Strict mode: enforce reusable module boundaries, explicit interfaces, and reuse-first dependency decisions."
applyTo: "**"
---

# Modularity Guardrails

Apply these defaults for all non-trivial feature work.

## Required Design Guardrails

- Decompose features into small modules with single responsibilities.
- Define explicit public interfaces between modules.
- Keep composition orchestration separate from module internals.
- Avoid circular dependencies.

## Reuse-First Guardrails

- Evaluate existing open-source/free mods or libraries before building new internals.
- For major capabilities, record adopt/wrap/replace decision and rationale.
- Prefer adapter wrappers around third-party dependencies to reduce lock-in.

## Implementation Guardrails

- Introduce reusable modules before feature-specific glue.
- Keep module contracts stable across iterations.
- Add tests at interface boundaries, not only inside implementations.

## Enforcement

- If architecture is monolithic or interfaces are implicit, flag this as a quality issue and propose refactoring boundaries.
