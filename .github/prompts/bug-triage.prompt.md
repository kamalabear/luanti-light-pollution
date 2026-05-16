---
name: bug-triage
description: "Structured Luanti bug triage workflow for reproduction, impact assessment, root-cause hypotheses, and fix planning."
---

# Bug Triage

Use this prompt to triage a bug consistently before coding fixes.

## Inputs to Collect

1. Observed behavior
2. Expected behavior
3. Reproduction steps
4. Environment details (engine version, mod set, platform)
5. Severity and impact
6. First known occurrence
7. Candidate components/modules affected

## Triage Outputs

1. Reproduction status (confirmed or not confirmed)
2. Minimal failing behavior statement in describe/it style
3. Likely root-cause hypotheses ranked by confidence
4. Recommended fix scope (smallest testable fix)
5. Regression test plan (unit, integration, or both)
6. Follow-up actions and owner suggestion
