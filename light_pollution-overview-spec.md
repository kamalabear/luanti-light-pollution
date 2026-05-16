# light_pollution — Overview Spec

> This project has been broken into iterations. See the iteration specs below for implementation details.
> Full original spec (with review feedback): [light_pollution-implementation-spec.md](light_pollution-implementation-spec.md)

---

## Overview

`light_pollution` is a Luanti mod that simulates light pollution from large clusters of light-emitting nodes — lava fields, villages, lamp farms, and more. It creates a graduated visual atmosphere for players near bright areas: a warm orange sky glow, reduced star visibility, and a tinting HUD overlay that dims the view. The pollution zone scales dynamically with the density and total intensity of nearby light sources. A public Lua API lets other mods register their own pollution sources or inject manual zones.

---

## Full Project Vision

When complete, `light_pollution` delivers:

1. **Atmospheric sky glow** — night sky transitions from deep blue to orange/amber as a player approaches a large light cluster, with a smooth intensity gradient that scales with cluster density.
2. **Star degradation** — star count and opacity fall proportionally to pollution intensity; at peak pollution, the night sky is nearly starless.
3. **Night vision penalty** — a semi-transparent orange HUD overlay tints and dims the player's view inside the pollution zone, simulating real-world sky glow washing out the darkness.
4. **Intelligent zone detection** — a hybrid scanner (event-driven dirty invalidation + player-centered periodic VoxelManip scan) detects light clusters at chunk boundaries without per-frame overhead.
5. **Public API** — other mods can register custom sources, inject manual zones, and subscribe to pollution tier change callbacks.
6. **Mob spawning integration** — optional configurable modes suppress or attract hostile mobs inside pollution zones (reactive ABM-based; limitation: post-spawn, not pre-spawn).
7. **Full configurability** — 16 `minetest.conf` settings covering scan radius, intensity thresholds, HUD opacity, mob behavior, tier boundaries, and more.
8. **MTG + VoxeLibre compatibility** — default source node lists auto-detected from active game; no hard-coded names outside `compat.lua`.

---

## Iteration Map

| Iteration | Goal | Key Deliverable | Depends On |
|---|---|---|---|
| [Iteration 1](light_pollution-iteration-1-spec.md) | Core sensing + sky tint | Sky turns orange near a lava cluster | — |
| [Iteration 2](light_pollution-iteration-2-spec.md) | Full effects + extensibility | Stars fade, HUD dims view, public API active, mob spawning configurable | Iteration 1 |

---

## Capability → Iteration Mapping

| Capability | Iteration |
|---|---|
| `config.lua` — settings load + validation | 1 |
| `compat.lua` — MTG + VoxeLibre source node lists | 1 |
| `scanner.lua` — VoxelManip scan + dirty tracking | 1 |
| `zone_manager.lua` — zone compute, cache, intensity query | 1 |
| `effect_engine.lua` — sky tint only | 1 |
| `init.lua` — wired globalstep, placenode/dignode | 1 |
| `effect_engine.lua` — star reduction | 2 |
| `effect_engine.lua` — HUD overlay (tint + dim) | 2 |
| `api.lua` — full public API + tier callbacks | 2 |
| Mob spawning ABM integration | 2 |
| `settingtypes.txt` — all 16 settings documented | 2 |

---

## Module Dependency Graph

```
init.lua
  ├── config.lua         (no dependencies)
  ├── compat.lua         (config)
  ├── api.lua            (config)          ← full wiring in Iteration 2
  ├── scanner.lua        (config, api)
  ├── zone_manager.lua   (config, scanner, api)
  └── effect_engine.lua  (config, zone_manager)
```

All modules introduced in Iteration 1. API module exists as a minimal stub in Iteration 1; fully wired in Iteration 2.

---

## Integration Strategy

- **Iteration 1 completion gate**: `spec/` unit tests pass via Docker; in-game visual smoke test confirms sky tint at night near a lava cluster.
- **Iteration 2 completion gate**: all unit + integration tests pass; manual in-game test confirms stars fade, HUD overlay appears, `light_pollution.register_source()` works from a second test mod.
- **Release**: After Iteration 2 is complete and all gates pass, the mod is ready for initial public release.

---

## Key Design Decisions (summary)

| Decision | Choice | Rationale |
|---|---|---|
| Node detection | VoxelManip (not `find_nodes_in_area`) | Supports dynamic source registry; one bulk read vs. N calls |
| Scan strategy | Hybrid (event-driven dirty + player-centered timer) | Handles chunk boundaries; bounded per-player cost |
| Sky/stars effects | `player:set_sky()` + `player:set_stars()` | Per-player — different zones for different players simultaneously |
| Mob suppression | Reactive ABM (post-spawn removal) | No universal pre-spawn hook across MTG and VoxeLibre mob frameworks |

Full decision log: see [light_pollution-implementation-spec.md → Decision Log](light_pollution-implementation-spec.md#decision-log).

---

## Open Source / Free Resources

| Resource | Source | Notes |
|---|---|---|
| busted | https://lunarmodules.github.io/busted/ | `luarocks install busted` |
| mineunit | https://github.com/S-S-X/mineunit | `luarocks install mineunit` |
| mineunit Docker | https://hub.docker.com/r/mineunit/mineunit | ⚠️ Required on Windows — `docker pull mineunit/mineunit` |
