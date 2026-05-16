---
name: spec-review
description: "Review a Luanti implementation spec for completeness, clarity, and scope. Use when: user asks to review a spec, check if a spec is ready, validate a spec, or assess if a spec is too large. Flags issues and optionally breaks large specs into iterations."
---

# Luanti Implementation Spec Review Skill

This skill reviews an existing Luanti implementation spec for structure, clarity, and scope. If the spec is too large, it guides you through breaking it into logical iterations with an overview spec and individual iteration specs.

## Agent Instructions

### Phase 1: Locate the Spec

1. Ask the user which spec file to review, or search the workspace for `*-implementation-spec.md` files.
2. Read the full file before proceeding.

---

### Phase 2: Structural Review

Check for the presence and quality of each required section. For each, evaluate:

#### Section Checklist

| Section | Present? | Clear & Specific? | Notes |
|---|---|---|---|
| Overview | | | 2-3 sentences, plain language |
| Objectives & Success Criteria | | | `it` statements for observable in-game outcomes |
| Functional Requirements | | | `describe`/`it` blocks for behaviors; structural requirements in a checklist |
| Modularity & Extensibility Strategy | | | Reuse plan, module boundaries, interfaces, and composition approach |
| Technical Architecture | | | Luanti components, data model, APIs |
| Open Source/Free Resources | | | All resources identified, blockers flagged |
| Implementation Approach | | | Step-by-step, logical order |
| Testing & Validation | | | busted `describe`/`it` style, unit + integration tests, `spec/*_spec.lua` files |

#### Testing Stack Checks

- **Test framework**: Tests must use [busted](https://lunarmodules.github.io/busted/) + [mineunit](https://github.com/S-S-X/mineunit). Flag if the spec references a different framework or has no framework specified.
- **Test file location**: Tests must live in `spec/*_spec.lua` inside the mod directory. Flag if not specified.
- **BDD style**: Tests must use busted `describe`/`it` blocks with plain-English descriptions. Flag if test cases are described as prose steps rather than structured `describe`/`it` statements.
- **Test types**: The Testing & Validation section must include both unit tests (mocked API) and integration tests (simulated engine events). Flag if only one type is present.
- **Windows/Docker**: If the project is developed on Windows, flag that mineunit requires Docker (`docker pull mineunit/mineunit`) since it does not run natively on Windows.
- **Resources listed**: busted and mineunit must appear in the Open Source/Free Resources section. Flag if missing.

#### Clarity Checks

- **`describe`/`it` for behaviors**: Functional Requirements and Success Criteria must use `describe`/`it` plain-English style. Flag any section that uses prose bullet points or narrative paragraphs for behavioral requirements instead. Example of correct style:
  ```
  describe "Lantern node"
    it "emits light level 10 when placed in the world"
    it "can be crafted using 1 glass bottle and 1 torch"
  ```
- **Structural requirements separate**: Non-behavioral requirements ("mod must have a mod.conf", "textures must be 16x16 PNG") should be in a "Structural Requirements" checklist, not in `describe`/`it` blocks. Flag if they are mixed in.
- **Modularity plan present**: Spec must define module boundaries and responsibilities (what each piece owns), plus how pieces compose into higher-level behavior. Flag if architecture is monolithic or unclear.
- **Interface clarity**: Reusable pieces must declare public interfaces (APIs, callbacks, data contracts, or events). Flag if module interactions are implied but not specified.
- **Reuse rationale**: Spec should identify existing open-source mods/libraries considered for reuse and explain adopt/wrap/replace decisions. Flag if no reuse analysis is provided.
- **Vague language**: Flag any goals or requirements that use words like "good", "fast", "easy", "nice", or "better" without defining what that means concretely.
- **Testable success criteria**: Each success criterion must describe an observable, in-game outcome (e.g., "Player can craft item X using recipe Y" not "crafting works").
- **Missing Luanti context**: Flag any technical claims that reference APIs, nodes, or registrations without specifying the exact Luanti API or mod convention to use.
- **Unresolved assumptions**: Flag any phrases like "TBD", "to be determined", "figure out later", or "maybe".

---

### Phase 3: Scope Assessment

Evaluate the spec against these heuristics to determine if it's appropriately scoped for a single iteration:

#### Scope Heuristics (flag if 2+ are true)

1. **Lua system breadth** — Does the spec touch 3 or more independent Lua systems (e.g., node registration, entity behavior, ABM/LBM callbacks, player inventory, formspecs, HUD)?
2. **Registration count** — Does the spec define more than 5-7 new nodes, items, entities, or craftitems?
3. **Testing surface** — Does the Testing & Validation section have more than 5 distinct, independent test scenarios?
4. **Dependency depth** — Do implementation steps form a chain of 6+ steps where nothing is playable or verifiable until late in the sequence?
5. **No intermediate testable deliverable** — Is there no point mid-way through the Implementation Approach where a meaningful, playable result can be loaded and verified?

If **2 or more** heuristics are triggered, the spec is likely too large for a single iteration.

---

### Phase 4: Feedback Report

Generate a structured feedback report **within the spec file** under a new section:

```markdown
---

## Spec Review Feedback

*Reviewed: [DATE]*

### Structure
- ✅ or ❌ [Section name]: [comment]

### Clarity Issues
- [Issue description and suggested fix]

### Scope Assessment
- **Verdict**: Appropriately scoped / Likely too large
- **Triggered heuristics**: [list]

### Recommended Actions
- [Actionable item 1]
- [Actionable item 2]
```

Ask the user: **"Would you like me to apply these suggestions to the spec?"**
- If **yes**: Update the spec in-place, fixing clarity issues and filling missing sections.
- If **no**: Leave feedback in place as-is.

---

### Phase 5: Iteration Breakdown (if scope is too large)

If the scope assessment suggests the spec is too large, ask:

> "This spec looks like it may be too large for a single iteration. I recommend breaking it into smaller, independently testable phases. Would you like help doing that?"

If **yes**, proceed:

#### Step 5a: Establish Priorities

Ask the user:

1. **What is the single most important thing this mod must do?** (core value, must work first)
2. **What features are essential vs. nice-to-have?** Ask them to classify features from the Functional Requirements section.
3. **Are there any hard dependencies?** (e.g., "Feature B can't work without Feature A")

#### Step 5b: Suggest Iteration Breakdown

Based on priority and dependencies, propose a breakdown following these principles:

- **Iteration 1** — Smallest meaningful core: the minimum needed to load the mod and verify the fundamental mechanic works. Should pass at least 1-2 key test scenarios.
- **Iteration 2+** — Progressively adds features in dependency order, with each iteration independently testable.
- **Iteration 2+** — Progressively adds features in dependency order, with each iteration independently testable, while introducing reusable modules before feature-specific glue.
- **Final iteration** — Polish, configuration options, edge cases, performance.

Present the proposed breakdown to the user and ask for confirmation or adjustments.

#### Step 5c: Create Iteration Specs

Once the breakdown is confirmed:

1. **Create an Overview Spec** at `<MOD_NAME>-overview-spec.md`:
   - Full project vision and end state
   - How iterations build on each other (with dependency notes)
   - Table of contents linking to each iteration spec
   - Integration/release strategy (what "done" looks like for each phase)

2. **Create individual Iteration Specs** at `<MOD_NAME>-iteration-<N>-spec.md` for each iteration:
   - Full spec structure (Overview, Objectives, Functional Requirements, Technical Architecture, Open Source Resources, Implementation Approach, Testing & Validation)
   - Scoped only to that iteration's features
   - References the Overview Spec and notes which iteration it is
   - Testing section must include a clear "iteration complete" checkpoint

3. **Update the original spec** to redirect to the Overview Spec:
   - Add a notice at the top: `> This spec has been broken into iterations. See [MOD_NAME-overview-spec.md] for the full plan.`

---

## Scope Heuristics Reference

| Heuristic | Threshold | Why It Matters |
|---|---|---|
| Lua system breadth | 3+ independent systems | Each system adds integration risk |
| Registration count | 5-7+ new registrations | More registrations = more surface area to debug |
| Testing surface | 5+ independent test scenarios | Hard to isolate failures at this scale |
| Dependency depth | 6+ sequential steps before first testable result | Long feedback loops hide design problems early |
| No intermediate deliverable | Nothing testable mid-way | No early signal if the approach needs to shift |

The goal of scoping is to find the **smallest deliverable that gives a meaningful signal** — if the core mechanic doesn't work at the end of iteration 1, you want to know before building everything else on top of it.

---

## Luanti Documentation References

- [Official Luanti Documentation for Creators](https://docs.luanti.org/for-creators/)
- [Lua API Reference](https://docs.luanti.org/modding/reference/lua-api/)
- [Node Definition Reference](https://docs.luanti.org/modding/reference/nodes/)
- [Item Definition Reference](https://docs.luanti.org/modding/reference/items/)
- [Entity Definition Reference](https://docs.luanti.org/modding/reference/entities/)
- [Crafting Recipe Reference](https://docs.luanti.org/modding/reference/crafting-recipes/)
- [ABM/LBM Reference](https://docs.luanti.org/modding/reference/abms-and-lbms/)

**Testing Framework References:**
- [busted — Lua BDD test runner](https://lunarmodules.github.io/busted/)
- [mineunit — Luanti/Minetest unit & integration testing](https://github.com/S-S-X/mineunit)
- [mineunit Docker images](https://hub.docker.com/r/mineunit/mineunit)
