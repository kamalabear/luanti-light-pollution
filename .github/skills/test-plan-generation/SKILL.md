---
name: test-plan-generation
description: "Generate Luanti test plans and test skeletons from a spec. Use when: user asks to create tests, derive tests from requirements, or organize busted/mineunit coverage. Produces unit and integration test plans mapped to spec behavior statements."
---

# Luanti Test Plan Generation Skill

Use this skill to derive a complete test plan from an implementation spec.

## Agent Instructions

### Phase 1: Parse Spec Inputs

Extract from the target spec:

- Success criteria `it` statements
- Functional `describe`/`it` groups
- Structural requirements checklist
- Iteration boundaries (if present)

Flag missing or ambiguous behaviors before generating tests.

---

### Phase 2: Build Test Matrix

Generate a test matrix with:

- Behavior ID
- Requirement statement
- Test type (unit or integration)
- Primary Luanti API surface
- Setup/fixtures needed
- Expected observable outcome

Rules:
- Prefer unit tests for deterministic logic.
- Use integration tests for engine callbacks, world interactions, and multi-system behavior.

---

### Phase 3: Produce Test Structure

Define file layout under `spec/`:

- `spec/unit/*_spec.lua`
- `spec/integration/*_spec.lua`
- `spec/fixtures/*.lua` as needed

For each file, include `describe` groups and `it` test names aligned to the spec.

---

### Phase 4: Fixture and Simulation Plan

For mineunit integration coverage, define:

- world/layout fixtures
- player fixtures
- callback simulation needs (`execute_globalstep`, join/leave, formspec events, etc.)
- mod dependency stubs/mocks

Keep fixture scope minimal and reusable.

---

### Phase 5: Output

Produce one or more markdown outputs:

1. `test-plan.md` (matrix + strategy)
2. `test-file-map.md` (which tests live in which files)
3. Optional starter skeleton snippets for key spec files

Include execution notes for Windows using Docker when mineunit is required.

## Testing Standards

- Framework: busted + mineunit
- Naming: plain-English behavior statements
- Mapping: every core `it` requirement should map to at least one test
- Iterations: each iteration must have completion checkpoint tests
