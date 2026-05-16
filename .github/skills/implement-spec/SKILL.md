---
name: implement-spec
description: "Implement an approved Luanti spec end-to-end. Use when: user asks to implement a spec, build a specific iteration, or execute planned requirements. Produces code changes, tests, and validation results aligned to the spec."
---

# Luanti Spec Implementation Skill

Use this skill to implement an existing Luanti specification (single spec or iteration spec) into working code.

## Agent Instructions

### Phase 1: Intake and Scope Lock

1. Identify the target spec file.
2. Confirm implementation scope:
   - Full spec
   - A specific iteration
   - A subset of requirements
3. Extract:
   - `describe`/`it` functional requirements
   - Structural requirements checklist
   - Modularity and extensibility constraints
   - Testing requirements (busted + mineunit)

If scope is ambiguous, ask targeted follow-up questions before coding.

---

### Phase 2: Implementation Plan

Create a short execution plan in this order:

1. Reusable module boundaries first
2. Core behavior implementation
3. Integration glue code
4. Tests (unit then integration)
5. Validation and certification gate check
6. Deploy to user-facing test environment
7. Implementation report

Favor smallest testable slices and avoid large, monolithic changes.

---

### Phase 3: Implement

Apply code changes directly in the workspace.

Requirements:
- Follow Luanti APIs and conventions.
- Prefer extending/reusing existing modules over duplicate logic.
- Keep public interfaces explicit between modules.
- Keep each step verifiable (playable or testable checkpoint).

---

### Phase 4: Testing and Validation

1. Implement or update tests in `spec/*_spec.lua`.
2. Ensure test names map to spec `describe`/`it` statements.
3. Run lint/static checks if configured, then run unit and integration tests.
4. Evaluate a certification gate (pass/fail) using:
   - Spec alignment check
   - Unit test outcomes
   - Integration test outcomes
   - Regression risk review
5. Report:
   - Implemented requirements
   - Deferred requirements (with reason)
   - Failing tests and likely causes
   - Certification gate result and rationale

If mineunit execution is needed on Windows, note Docker requirement.

---

### Phase 5: Deploy to Test Environment (UAT Checkout)

1. Deploy current implementation to an accessible test environment when possible.
2. Provide the user with exact run/deploy steps and interaction instructions.
3. Identify what the user should verify during acceptance checkout (mapped to key `describe`/`it` behaviors).

If deployment cannot be performed in the current environment, report the exact blocker and provide the nearest runnable alternative.

---

### Phase 6: Completion Check and Implementation Report

Before finishing, verify:

- All in-scope requirements are implemented or explicitly deferred.
- Structural requirements are satisfied.
- Modularity/extensibility constraints are respected.
- Test coverage exists for major behaviors.

Generate a final implementation report including:

- Scope implemented
- Test commands used and outcomes
- Certification gate decision
- Deployment/UAT status and checkout instructions
- Issues encountered and recommended next actions

Provide a concise implementation summary with changed files and next steps.

## Luanti References

- https://docs.luanti.org/for-creators/
- https://docs.luanti.org/modding/reference/lua-api/
- https://docs.luanti.org/modding/reference/nodes/
- https://docs.luanti.org/modding/reference/items/
- https://docs.luanti.org/modding/reference/entities/

## Testing References

- https://lunarmodules.github.io/busted/
- https://github.com/S-S-X/mineunit
- https://hub.docker.com/r/mineunit/mineunit
