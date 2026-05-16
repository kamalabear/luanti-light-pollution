---
name: luanti-delivery-discipline
description: "Use when: applying workspace-wide Luanti delivery defaults. Strict mode: enforce modularity, reuse-first design, smallest testable slices, and busted+mineunit alignment."
applyTo: "**"
---

# Luanti Delivery Discipline

Apply these defaults unless the user explicitly overrides them.

## Skill Routing Mode

- Use strict routing by default: when a request matches a skill trigger, invoke that skill workflow.
- Do not handle matched requests ad-hoc when a defined skill exists for that request type.
- If multiple skills appear to match, choose the most specific intent in this priority order:
	1. implement-spec
	2. spec-review
	3. implementation-spec
	4. iteration-planning
	5. test-plan-generation
	6. dependency-reuse-fit
	7. spec-to-taskboard
- If two skills remain ambiguous after applying priority, ask one targeted disambiguation question, then invoke exactly one skill.

## Default Lifecycle

Follow this standard workflow unless the user explicitly overrides it:

1. Build specification artifacts first (implementation-spec, and iteration-planning/spec-review when needed).
2. Implement iteration 1 via implement-spec workflow.
3. Include corresponding test creation and updates.
4. Run validation/certification checks (lint/static when configured, unit tests, integration tests where applicable).
5. Deploy to a user-interactive test environment for acceptance checkout when possible.
6. Produce a final implementation report including test outcomes, certification status, deployment status, and encountered issues.
7. Add or update a changelog entry for the logical change set.
8. Commit and push the logical change set so the remote stays current.

If environment constraints prevent steps 4 or 5, report exact blockers and provide the nearest runnable manual path.
If git remote sync is not possible, report the exact blocker and leave a ready-to-run commit/push command path.

## Architecture Defaults

- Prefer composition over monolithic feature blocks.
- Define and maintain clear module boundaries.
- Prefer reuse of open-source dependencies before rebuilding.
- Document adopt/wrap/replace rationale for major capabilities.

## Execution Defaults

- Build the smallest meaningful testable slice first.
- Ensure each implementation checkpoint is runnable or verifiable.
- Add or update tests with behavior changes.
- Add or update a concise changelog entry per logical update.
- Treat each completed logical change set as a git checkpoint: commit it with a meaningful message and push it unless the user explicitly says not to.

## Testing Defaults

- Use busted + mineunit for Lua/Luanti tests.
- Keep tests in `spec/*_spec.lua` (or `spec/unit` and `spec/integration` splits).
- Keep behavior naming aligned with `describe`/`it` requirement statements.

## Quality Defaults

- Keep requirements and acceptance criteria observable and testable.
- Separate structural/configuration requirements from behavior statements.
- Flag blockers where open-source/free options are unavailable.
