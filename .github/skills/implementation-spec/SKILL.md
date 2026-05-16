---
name: implementation-spec
description: "Create a detailed implementation spec for a Luanti mod or add-on. Use when: planning a new mod, adding features, or clarifying requirements for an agent to implement. Asks guided questions to gather requirements and produces a comprehensive technical specification."
---

# Luanti Implementation Spec Skill

This skill guides you through creating a detailed implementation specification for a Luanti mod or add-on. The spec will be suitable for an agent to pick up and implement.

## Agent Instructions

When the user invokes this skill:

1. **Gather Responses** — Present the questions below in the indicated phases. Use `vscode_askQuestions` tool to ask questions in structured phases, allowing freeform text answers.

2. **Process Answers** — After collecting responses:
   - Synthesize and clarify any ambiguous answers
   - Identify missing details and ask follow-up questions if needed
   - Flag any open-source/free resource blockers mentioned in Phase 5

3. **Generate Spec** — Create a markdown implementation spec document(s) with these sections in order:
   - **Overview** — 2-3 sentences describing what's being created in plain language
   - **Objectives & Success Criteria** — Purpose and problem solved, followed by success criteria written as `it` statements (plain English, not code): each `it` describes one observable, in-game outcome
   - **Functional Requirements** — Behaviors written in `describe`/`it` style (plain English): group related behaviors under a `describe` subject, each `it` is one testable behavior. Structural/configuration requirements (non-behavioral) go in a separate "Structural Requirements" checklist.
   - **Technical Architecture** — Luanti components involved, data model, API design, performance considerations (prose/structured notes)
   - **Open Source/Free Resources** — List of tools, libraries, textures, models with source links; flag any potential blockers
   - **Implementation Approach** — Detailed step-by-step breakdown in logical order (e.g., "1. Create mod.conf, 2. Register nodes, 3. Add crafting recipes...")
   - **Testing & Validation** — Specific test cases written in busted `describe`/`it` BDD style, organized into unit tests (mocked API via mineunit) and integration tests (simulated engine events via mineunit). The Functional Requirements `describe`/`it` statements map directly to test stubs here.

4. **Writing Quality Rules** — Apply these standards throughout the spec:
   - **No vague language**: Avoid words like "good", "fast", "easy", "nice", or "better" without a concrete definition. Replace with measurable or observable terms.
   - **`describe`/`it` for behaviors**: Functional Requirements and Success Criteria must use `describe`/`it` plain-English style. `describe` names the subject (node, feature, system). `it` names one observable behavior. Example:
     ```
     describe "Lantern node"
       it "emits light level 10 when placed in the world"
       it "can be crafted using 1 glass bottle and 1 torch"
       it "drops itself when dug with any tool"
     ```
   - **Structural requirements as checklist**: Non-behavioral requirements (e.g., "mod must have a mod.conf", "textures must be 16x16 PNG") go in a separate "Structural Requirements" checklist, not in `describe`/`it` blocks.
   - **Composition-first architecture**: Prefer designing features as small, reusable modules with clear interfaces, then compose them into larger systems. Avoid monolithic single-mod designs when natural feature boundaries exist.
   - **Reuse before rebuild**: For each major capability, check for existing open-source Luanti mods/libraries that can be depended on or integrated. If not reused, document why (fit, license, maintenance, or technical mismatch).
   - **Exact Luanti references**: Any technical claim referencing a node, API, callback, or registration must name the specific Luanti API or convention (e.g., `minetest.register_node`, `on_construct`, `minetest.after`).
   - **No unresolved assumptions**: Do not write "TBD", "to be determined", "figure out later", or "maybe". If something is unknown, flag it explicitly as a decision point with options.

5. **Testing Standard** — All specs must follow this testing stack:
   - **Framework**: [busted](https://lunarmodules.github.io/busted/) (test runner) + [mineunit](https://github.com/S-S-X/mineunit) (Luanti API mock + engine simulation)
   - **Test files**: `spec/*_spec.lua` inside the mod directory
   - **Style**: BDD `describe`/`it` blocks with plain-English descriptions, e.g.:
     ```lua
     describe("Lantern node", function()
       it("emits light level 10 when placed in world", function() ... end)
       it("requires 1 glass bottle and 1 torch to craft", function() ... end)
     end)
     ```
   - **Unit tests**: mock the Luanti API using mineunit to test logic in isolation
   - **Integration tests**: use mineunit engine event simulation (`mineunit:execute_globalstep`, `mineunit:execute_on_joinplayer`, etc.) to test in-game behavior
   - **Windows note**: mineunit does not run natively on Windows — tests must be run via Docker (`docker pull mineunit/mineunit`). Flag this in the Open Source/Free Resources section if the project will be developed on Windows.
   - Include busted and mineunit in the Open Source/Free Resources section of the spec with their install commands.

6. **Scope Self-Assessment** — After generating the spec, evaluate it against these heuristics. If **2 or more** are triggered, recommend breaking the spec into iterations using the spec-review skill:
   - Lua system breadth: 3+ independent systems (nodes, entities, ABMs/LBMs, player inventory, formspecs, HUD, etc.)
   - Registration count: 5-7+ new nodes, items, entities, or craftitems
   - Testing surface: 5+ distinct, independent test scenarios
   - Dependency depth: 6+ sequential implementation steps before anything is playable
   - No intermediate testable deliverable: nothing meaningful to verify mid-way through

7. **Output Files** — Create one or more markdown files in the workspace:
   - Primary spec: `<MOD_NAME>-implementation-spec.md` in the workspace root or `docs/` folder
   - Additional files if the spec is large (e.g., separate technical architecture doc, resource inventory)

8. **Documentation Links** — Include relevant [Luanti Documentation](https://docs.luanti.org/for-creators/) links in the Implementation Approach and Technical Architecture sections where applicable.

## Phase 1: Project Scope

First, let's establish the scope of what we're building.

1. **What type of project is this?**
   - New mod from scratch (greenfield)
   - Adding a feature to an existing mod
   - Modifying/extending existing mod functionality

2. **What is the name of the mod or project?** (if adding to existing, provide the existing mod name)

## Phase 2: Objectives & Success Criteria

Now let's define what success looks like.

3. **In plain language, what is the purpose of this mod/feature?** Describe what problem it solves or what experience it creates for players.

4. **What are the key success criteria?** Express each as a plain-English `it` statement — one observable, in-game outcome per line. (e.g., `it "emits light level 10 when placed"` rather than "lighting works".)

5. **Who is the intended audience?** (e.g., specific Luanti community, solo players, servers, creators)

## Phase 3: Functional Requirements

Let's detail what this mod actually needs to do.

6. **What are the core features or behaviors?** For each feature, describe it as a `describe`/`it` group — name the subject with `describe`, then list each observable behavior as an `it` statement. (e.g., `describe "Lantern node" → it "emits light level 10"`).

7. **Are there any game world interactions?** (e.g., nodes, items, crafting, effects on environment, biomes, mobs, players) Again, express behaviors as `it` statements where possible.

8. **Are there configuration or customization options?** (e.g., settings players can modify, difficulty levels, feature toggles) These are typically structural requirements — list them as checklist items rather than `it` statements.

9. **Does this mod interact with or depend on other mods?** If so, which ones and how?

## Phase 4: Technical Architecture

Now for the technical design.

10. **What Luanti components are involved?** Consider:
    - Custom nodes (blocks)
    - Custom items
    - Entities (objects/mobs)
    - Crafting recipes
    - LUA callbacks or effects
    - Particle effects
    - Sound effects
    - Textures/models

11. **What is the data model?** How does the mod track state? (e.g., node metadata, entity properties, mod storage, player-specific data)

12. **Are there any performance considerations?** (e.g., frequent updates, many entities, large data structures)

## Phase 5: Implementation Details

Let's nail down how this will be built.

13. **If modifying an existing mod:** What files will be changed or added? What's the current structure?

14. **What open-source or free resources will you use?** (textures, models, libraries, tools) Identify any potential blockers if open-source/free alternatives don't exist.

15. **Are there any specific Luanti APIs or conventions you want to follow?** (e.g., sameoldsteve's style, specific mod frameworks, node registration patterns)

16. **Which existing mods/libraries should this build on?** For each dependency candidate, note whether you will adopt it, wrap it, or replace it, and why.

17. **How will you split this into reusable pieces?** Define module boundaries (responsibility per module), public interfaces, and how modules compose into the final system.

---

## Output

Once you've answered these questions, I'll generate markdown implementation spec file(s) with detailed sections ready for development. The spec will include:

- **Overview** — What is being created, in plain language
- **Objectives & Success Criteria** — `it` statements for observable outcomes
- **Functional Requirements** — `describe`/`it` blocks for behaviors + structural requirements checklist
- **Modularity & Extensibility Strategy** — Planned module boundaries, public interfaces, composition approach, and dependency/reuse rationale
- **Technical Architecture** — Design decisions, APIs, data structures, Luanti-specific details
- **Open Source/Free Resources** — Tools, libraries, frameworks, and any flagged blockers
- **Implementation Approach** — Step-by-step breakdown ready for an agent to execute
- **Testing & Validation** — How to verify it works

**Luanti Documentation References:**
- [Official Luanti Documentation for Creators](https://docs.luanti.org/for-creators/)
- [Modding Guide](https://docs.luanti.org/modding/)
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

---

Please answer the questions below to get started.
