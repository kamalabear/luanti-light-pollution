---
name: luanti-testing-execution-convention
description: "Use when: running or planning tests for Luanti projects. Strict mode: enforce standardized execution paths and reporting, including Docker-based mineunit execution on Windows."
applyTo: "**"
---

# Testing Execution Convention

Use these conventions whenever test execution is discussed or performed.

## Framework Default

- Unit and integration tests use busted + mineunit.
- Test files live under spec/*_spec.lua (optionally split into spec/unit and spec/integration).

## Execution Paths

- Preferred local path: run tests directly when environment supports busted + mineunit.
- Windows path: run mineunit using Docker image mineunit/mineunit.

## Windows Docker Notes

- If running on Windows and mineunit is required, call out Docker requirement early.
- If Docker is unavailable, mark test execution as blocked and provide exact next step.

## Result Summary Format

Always summarize test execution with:

1. Command path used (local or Docker)
2. Scope executed (unit, integration, both)
3. Outcome counts (passed, failed, skipped if known)
4. Key failing behaviors mapped to describe/it statements
5. Recommended immediate fix order

When applicable, also include:

6. UAT checkout focus areas (what the user should interact with in test environment)
7. Certification gate status (PASS/PARTIAL/FAIL) linked to executed checks

## Enforcement

- Do not report testing as complete without a summary in this format.
