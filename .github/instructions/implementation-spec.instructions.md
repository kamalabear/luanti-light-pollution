---
name: implementation-spec-instructions
description: "Use when: user asks to plan a mod, create a spec, design a feature, build a new mod, or clarify requirements for a Luanti/Minetest project. Strict mode: invoke the implementation-spec skill workflow."
applyTo: "**"
---

# Implementation Spec Skill Trigger Instructions

## When to Use the Skill

Whenever the user's request indicates they want to **plan, design, or specify** a Luanti mod or add-on, strictly invoke the **implementation-spec skill**.

### Trigger Patterns

Look for any of these patterns:

**Direct Requests:**
- "help me plan a mod"
- "I want to create a Luanti mod"
- "I need a spec for..."
- "help me design a feature"
- "I'm building a Minetest mod"
- "build me a specification"
- "outline what I should build"

**Exploratory Requests (requires judgment):**
- "I have an idea for a mod" → Offer the skill to flesh it out
- "what would it take to build..." → Offer the skill to help plan it
- "how would I implement..." → Offer the skill if it's early-stage planning
- "I want to add a feature to..." (existing mod) → Use the skill

**NOT a trigger:**
- "implement this spec" (they already have a spec; skip to implementation)
- "fix this bug" (debugging, not planning)
- "how do I use this API" (answering technical questions, not spec-building)

## How to Respond

When you detect a trigger pattern:

1. **Acknowledge** the user's request
2. **Invoke** `/implementation-spec` or use the skill to start guided questioning
3. **Proceed with the skill workflow immediately** rather than handling planning ad-hoc

**Example response:**
> "I'd like to help you plan this out! The Implementation Spec Skill will guide you through all the details. Let me ask some structured questions to build a comprehensive spec you can implement from."

## Strict Mode Rules

- When a trigger matches, do not skip to a manual planning response.
- Use direct help without this skill only in the NOT a trigger cases below.

## Skip the Skill If

- The user already has a detailed spec and just wants to implement it
- The request is about debugging/fixing existing code, not planning
- The user is asking for quick technical answers (API docs, code review, etc.)

In those cases, help directly without the skill.
