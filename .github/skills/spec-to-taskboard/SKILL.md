---
name: spec-to-taskboard
description: "Convert Luanti specs into implementation taskboards. Use when: user asks to turn a spec into tasks, backlog items, or execution checklists. Produces prioritized tasks with acceptance criteria mapped to behavior statements and tests."
---

# Luanti Spec to Taskboard Skill

Use this skill to transform a spec into an implementation-ready backlog.

## Agent Instructions

### Phase 1: Parse Spec Structure

Extract:

- Functional `describe`/`it` behaviors
- Structural checklist requirements
- Technical architecture constraints
- Modularity/reuse requirements
- Iteration boundaries

---

### Phase 2: Build Work Breakdown

Create task groups:

1. Foundation/module boundaries
2. Core feature implementation
3. Integration and composition
4. Tests and validation
5. Documentation/config updates

Keep tasks small and independently completable.

---

### Phase 3: Define Task Fields

For each task, include:

- Task ID
- Title
- Iteration
- Description
- Dependencies
- Acceptance criteria
- Related `describe`/`it` statements
- Test impact (unit, integration, both)

---

### Phase 4: Prioritize and Sequence

Order tasks by:

1. dependency constraints
2. risk reduction
3. earliest testable feedback

Flag blocked tasks and prerequisites explicitly.

---

### Phase 5: Output

Generate markdown outputs:

1. `taskboard.md` (primary backlog)
2. `taskboard-by-iteration.md` (optional split)

Acceptance criteria must remain behavior-based and testable.
