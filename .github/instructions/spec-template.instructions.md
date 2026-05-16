---
name: luanti-spec-template-enforcement
description: "Use when: creating or updating Luanti overview, implementation, or iteration specs. Strict mode: enforce canonical section order and heading names."
applyTo: "**"
---

# Canonical Spec Template

When creating or editing any Luanti spec in this workspace, use this exact section order and heading names.

## Required Section Order

1. Overview
2. Objectives & Success Criteria
3. Functional Requirements
4. Structural Requirements
5. Modularity & Extensibility Strategy
6. Technical Architecture
7. Open Source/Free Resources
8. Implementation Approach
9. Testing & Validation
10. Decision Log

## Section Rules

- Objectives and behavioral requirements must use plain-English describe/it style statements.
- Structural Requirements is checklist-only for non-behavioral requirements.
- Modularity & Extensibility Strategy must include module boundaries and public interfaces.
- Open Source/Free Resources must include blockers when no open-source/free option exists.
- Testing & Validation must include busted + mineunit strategy and test checkpoints.
- Decision Log must use the lightweight decision block defined in workspace ADR instruction.

## Scope Variants

- Overview specs: include all sections at high level and link iteration specs.
- Iteration specs: include all sections scoped only to that iteration.
- Single implementation specs: include all sections for full scope.

## Enforcement

- Do not reorder or rename headings unless user explicitly requests a deviation.
- If a section cannot be completed, keep the heading and mark unresolved items clearly.
