---
name: workflow-onboarding
description: "Route the user's first Luanti request to the correct strict workflow (skill or prompt) with one-step intent classification."
---

# Workflow Onboarding Router

Use this prompt at project start or when request type is unclear.

## Step 1: Classify Intent

Classify the request into exactly one primary intent:

1. Feature idea intake
2. Spec creation
3. Spec review
4. Iteration planning
5. Dependency/reuse analysis
6. Test plan generation
7. Spec implementation
8. Spec-to-taskboard conversion
9. Bug triage
10. PR review

## Step 2: Route to Workflow

Map intent to workflow:

- Feature idea intake -> new-feature-intake prompt
- Spec creation -> implementation-spec skill
- Spec review -> spec-review skill
- Iteration planning -> iteration-planning skill
- Dependency/reuse analysis -> dependency-reuse-fit skill
- Test plan generation -> test-plan-generation skill
- Spec implementation -> implement-spec skill
- Spec-to-taskboard conversion -> spec-to-taskboard skill
- Bug triage -> bug-triage prompt
- PR review -> pr-review-checklist prompt

## Step 3: Strict Routing Rules

- Use the mapped workflow directly.
- If two intents are close, ask one disambiguation question and then route.
- Do not proceed with ad-hoc handling when a mapped workflow exists unless user explicitly opts out.

## Step 4: Response Template

Return:

1. Selected intent
2. Selected workflow
3. One-line reason
4. Immediate next action
