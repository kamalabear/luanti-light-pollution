---
name: luanti-workspace-naming-conventions
description: "Use when: creating specs, iteration docs, taskboards, and test-plan artifacts. Strict mode: enforce consistent file naming to prevent documentation sprawl."
applyTo: "**"
---

# Naming Conventions

Use these file naming conventions for planning and execution artifacts.

## Spec Files

- Overview spec: <mod-name>-overview-spec.md
- Full implementation spec: <mod-name>-implementation-spec.md
- Iteration spec: <mod-name>-iteration-<n>-spec.md

## Planning and Execution Files

- Taskboard: <mod-name>-taskboard.md
- Taskboard by iteration: <mod-name>-taskboard-by-iteration.md
- Test plan: <mod-name>-test-plan.md
- Test file map: <mod-name>-test-file-map.md
- Dependency analysis: <mod-name>-dependency-reuse-analysis.md

## Naming Rules

- Use lowercase kebab-case for mod-name.
- Use numeric iteration values starting at 1.
- Avoid ad-hoc suffixes like final, v2, draft2 unless user explicitly requests them.

## Enforcement

- When creating new artifacts, follow this convention unless user provides an explicit override.
