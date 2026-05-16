---
name: luanti-ci-expectations
description: "Use when: implementing or reviewing changes in Luanti projects. Strict mode: enforce expected checks per change before formal CI is fully established."
applyTo: "**"
---

# CI Expectations

Apply these expected checks to each meaningful change.

## Required Checks by Change Type

- Feature changes:
  - Spec alignment check
  - Unit tests for core logic
  - Integration tests for behavior changes
- Refactor changes:
  - Existing test suite pass
  - No requirement behavior regression
- Bug fixes:
  - Reproduction test added when possible
  - Regression validation included

## Minimum Verification Bundle

1. Lint and static checks if configured
2. Unit test execution
3. Integration test execution when callbacks/world behavior are affected

## Certification Gate

- Treat the Minimum Verification Bundle as the baseline certification gate for implementation readiness.
- Mark certification as PASS only when required checks for the change type pass, or as PARTIAL/FAIL with explicit rationale.
- If checks are skipped, certification cannot be reported as fully passed.

## Reporting

Summarize which expected checks ran, which were skipped, and why.

## Enforcement

- If checks are not runnable in environment, state exact limitation and next runnable path.
- Do not present changes as fully validated when required checks were skipped.
