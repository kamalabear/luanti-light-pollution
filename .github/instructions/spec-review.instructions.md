---
name: spec-review-instructions
description: "Use when: user asks to review a spec, check readiness, validate completeness, assess scope, or confirm implementability. Strict mode: invoke the spec-review skill workflow."
applyTo: "**"
---

# Spec Review Skill Trigger Instructions

## When to Use the Skill

Whenever the user's request indicates they want to **review, validate, or assess** an existing Luanti implementation spec, strictly invoke the **spec-review skill**.

### Trigger Patterns

**Direct Requests:**
- "review my spec"
- "can you check this spec"
- "is this spec ready to implement"
- "validate my spec"
- "is my spec well-structured"
- "is this spec too big"
- "should I break this into iterations"
- "does this spec have everything it needs"

**Exploratory Requests (requires judgment):**
- "I wrote a spec, what do you think?" → Offer the skill to formally review it
- "is this ready?" (with spec context) → Use the skill
- "can an agent implement this?" → Use the skill to assess completeness
- "this feels like too much for one go" → Use the skill to assess and suggest iteration breakdown

**NOT a trigger:**
- "implement this spec" (they want implementation, not review)
- "update my spec with this new requirement" (editing, not reviewing)
- "create a spec" (use implementation-spec skill instead)

## How to Respond

When you detect a trigger pattern:

1. **Acknowledge** the user's request
2. **Invoke** the spec-review skill
3. **Proceed with the structured review workflow immediately** rather than ad-hoc review comments

**Example response:**
> "Happy to review that! Let me check the spec for structure, clear requirements, and whether the scope is right-sized for a single implementation cycle."

## Strict Mode Rules

- When a trigger matches, do not provide manual review in place of the skill.
- Use direct help without this skill only in the NOT a trigger cases below.

## Skip the Skill If

- The user wants to implement the spec (help directly)
- The user wants to edit/update the spec with new content (edit directly)
- The user wants to create a new spec (use the implementation-spec skill instead)
