---
name: implementation-completion-checklist
description: "Use when: implementing Luanti specs or iteration plans. Strict mode: require a final completion checklist before concluding implementation work."
applyTo: "**"
---

# Implementation Completion Checklist

Before concluding any implementation task, produce this checklist and mark each item complete or incomplete.

## Required Completion Checks

- Requirement coverage: all in-scope describe/it requirements implemented or explicitly deferred.
- Structural requirements: all in-scope checklist items addressed.
- Tests updated: unit and integration tests added or updated for changed behavior.
- Validation run: test execution attempted and summarized.
- Certification gate: minimum verification bundle evaluated and outcome recorded.
- Test environment deploy: user acceptance checkout environment prepared, or blocker documented.
- Implementation report: final report includes outcomes and encountered issues.
- Changelog updated: a logical update entry was added or revised.
- Git sync: logical change set committed locally and pushed to remote, or blocker documented.
- Scope changes: any spec deviations documented with reason.
- Open blockers: unresolved blockers listed with recommended next action.

## Reporting Format

Use concise status lines:

- PASS: [check name] - [evidence]
- PARTIAL: [check name] - [what is missing]
- FAIL: [check name] - [blocker]

## Enforcement

- Do not end implementation responses without this checklist.
- If execution environment prevents test run, mark Validation run as PARTIAL and state exact limitation.
- If deployment to test environment is not possible, mark Test environment deploy as PARTIAL and provide exact manual steps the user can run.
- If commit/push is not possible, mark Git sync as PARTIAL and state the exact blocker and next command path.
