---
name: pr-review-checklist
description: "Structured Luanti pull request review checklist focusing on behavior correctness, modularity, test coverage, and spec alignment."
---

# PR Review Checklist

Use this prompt to review changes with consistent acceptance criteria.

## Review Checklist

1. Scope alignment
   - Change matches intended spec/iteration scope
   - No hidden scope expansion

2. Behavior correctness
   - describe/it requirements implemented as expected
   - No obvious regressions in adjacent behavior

3. Modularity and reuse
   - Module boundaries remain clear
   - Interfaces are explicit and stable
   - Reuse/adopt/wrap decisions are reasonable

4. Testing quality
   - Unit and integration tests updated as needed
   - Test names map to behavior statements
   - Failing scenarios are covered

5. Validation and risk
   - Verification evidence provided
   - Remaining risks and blockers documented

## Review Output

Return:

1. Findings by severity
2. Required changes before merge
3. Optional improvements
4. Merge readiness verdict
