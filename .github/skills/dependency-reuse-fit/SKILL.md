---
name: dependency-reuse-fit
description: "Evaluate Luanti dependency and reuse options. Use when: user asks what to build on, whether to adopt/wrap/replace an existing mod/library, or how to maximize extensibility. Produces a structured reuse decision with licensing and maintenance checks."
---

# Luanti Dependency and Reuse Fit Skill

Use this skill to evaluate whether to adopt, wrap, or replace existing mods/libraries.

## Agent Instructions

### Phase 1: Capability Decomposition

Break the target feature into capabilities (small functional units).

For each capability, identify:
- Required behavior
- Interface needs
- Data boundaries
- Performance sensitivity

---

### Phase 2: Candidate Inventory

For each capability, gather candidate dependencies:

- Existing Luanti mods
- Lua libraries
- Small utility modules already in workspace

If no candidate exists, mark as potential blocker and plan internal implementation.

---

### Phase 3: Fit Assessment

Score each candidate on:

1. Functional fit
2. API compatibility
3. License compatibility (open-source and free requirement)
4. Maintenance/activity
5. Extensibility and composability
6. Migration risk

Then assign recommendation:
- Adopt directly
- Wrap behind adapter interface
- Replace/build in-house

---

### Phase 4: Interface Strategy

Define stable internal interfaces so dependency choices can evolve.

For each adopted/wrapped dependency, specify:
- Adapter/API surface
- Error/fallback behavior
- Upgrade impact boundary

---

### Phase 5: Output

Produce markdown decision output:

- `dependency-reuse-analysis.md`
- `reuse-decision-table.md` (optional split)

Include a clear adopt/wrap/replace decision for each capability and unresolved blockers.
