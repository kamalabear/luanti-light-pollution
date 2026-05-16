---
name: iteration-planning
description: "Plan large Luanti features into iterations. Use when: user asks to break work into phases, sequence a large spec, or define smallest testable slices. Produces overview and per-iteration implementation specs with dependency-aware ordering."
---

# Luanti Iteration Planning Skill

Use this skill to split a large Luanti initiative into small, testable iterations.

## Agent Instructions

### Phase 1: Scope and Priority Intake

Ask for:

1. Core value (must work first)
2. Essential vs nice-to-have features
3. Hard dependencies
4. Preferred risk posture (conservative or aggressive)

---

### Phase 2: Slice Strategy

Construct slices using these rules:

- Iteration 1 = smallest meaningful playable/testable outcome
- Each later iteration adds one coherent capability cluster
- Reusable modules before feature glue
- Each iteration has explicit completion tests

---

### Phase 3: Draft Iteration Map

Produce:

- Iteration list with goals
- Capability-to-iteration mapping
- Dependency graph notes
- Risk and feedback checkpoints

---

### Phase 4: Generate Specs

Create:

1. `<MOD_NAME>-overview-spec.md`
2. `<MOD_NAME>-iteration-1-spec.md`
3. `<MOD_NAME>-iteration-2-spec.md` ... as needed

Requirements for each iteration spec:

- Full section structure used by implementation-spec skill
- `describe`/`it` behavior statements
- Structural requirements checklist
- Testing and validation checkpoint

---

### Phase 5: Validation

Check each iteration for:

- independent testability
- clear handoff to implementation agent
- minimal but meaningful scope

If an iteration is still too large, split again before finalizing.
