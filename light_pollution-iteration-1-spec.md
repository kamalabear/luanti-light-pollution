# light_pollution — Iteration 1 Spec
# Core Sensing + Sky Tint

> Part of: [light_pollution-overview-spec.md](light_pollution-overview-spec.md)
> Iteration 1 of 2

---

## Overview

Iteration 1 implements the minimum viable pipeline: detect light-emitting node clusters near a player and apply a single visual effect — an orange/amber sky tint proportional to pollution intensity. This iteration proves the full sensing → zone computation → per-player rendering pipeline works end-to-end before any additional effects or API surface are added.

By the end of this iteration, a player standing near a large lava field at night will see their sky shift toward orange. Moving away will restore the default sky color with a smooth fade.

---

## Objectives & Success Criteria

**Purpose:** Prove that the core light pollution pipeline — scan → zone → effect — works correctly and performantly for the sky tint effect.

**Success Criteria:**

- it "shows an orange/amber sky glow to a player standing within a pollution zone at night"
- it "scales the zone radius and intensity as more light-emitting nodes are added to a cluster"
- it "removes the sky tint when a player leaves the pollution zone radius"
- it "transitions the sky tint gradually as a player moves toward or away from the zone center"
- it "applies no sky changes during daytime"
- it "works with both Minetest Game (MTG) and MineClone2/VoxeLibre node sets out of the box"
- it "allows server admins to configure which node types contribute via minetest.conf"
- it "does not crash when optional dependencies (default, mcl_core) are absent"

---

## Functional Requirements

### describe "Config module"
- it "loads scan_radius, scan_interval, move_threshold, base_radius, radius_scale_factor, max_intensity, lerp_rate, zone_ttl, and source_types from minetest.conf at startup"
- it "returns a typed default value for each setting when the key is absent from minetest.conf"
- it "logs a warning via minetest.log('warning', ...) when a setting value is out of its valid range"
- it "exposes settings via config.get(key), config.get_number(key), and config.get_bool(key)"

### describe "Compat module"
- it "detects Minetest Game by checking minetest.get_modpath('default') and returns MTG lava/fire/torch node names with their weights"
- it "detects VoxeLibre by checking minetest.get_modpath('mcl_core') and returns equivalent VoxeLibre node names with their weights"
- it "filters returned sources to natural nodes only when source_types is 'natural'"
- it "filters returned sources to artificial nodes only when source_types is 'artificial'"
- it "returns both natural and artificial sources when source_types is 'both'"
- it "returns an empty list without error when neither 'default' nor 'mcl_core' modpath is present"

### describe "Light source scanner"
- it "detects all registered light-emitting nodes within scan_radius nodes of a position using VoxelManip"
- it "sums the weight of each detected source node to produce a total light_score"
- it "marks a mapblock dirty when a registered source node is placed within it"
- it "marks a mapblock dirty when a registered source node is removed from it"
- it "does not mark a mapblock dirty when an unregistered node is placed or removed"
- it "returns a list of source positions alongside the light_score for centroid calculation"

### describe "Zone manager"
- it "computes zone center as the weighted centroid of source positions returned by the scanner"
- it "computes zone radius as base_radius + (light_score / radius_scale_factor)"
- it "computes zone intensity as math.min(light_score / LIGHT_SCORE_MAX, max_intensity) where LIGHT_SCORE_MAX = 500"
- it "caches zone data keyed by mapblock hash to avoid redundant recalculation"
- it "returns cached zone data on a second call when the region is not dirty and TTL has not expired"
- it "recomputes zone data when the region has been marked dirty"
- it "recomputes zone data when zone_ttl seconds have elapsed since last computation"
- it "returns intensity 0.0 when scanner finds no sources in range"
- it "returns intensity 0.0 for a position outside the computed zone radius"
- it "returns a linearly interpolated intensity less than the zone peak for positions at the zone edge (falloff: 1.0 - dist/radius)"
- it "merges two overlapping zones and caps combined intensity at max_intensity"
- it "skips rescan when no dirty mapblocks exist and player has not moved more than move_threshold nodes since last scan"

### describe "Effect engine (sky tint only)"
- it "reads each connected player's position on every globalstep tick that fires (throttled by scan_interval)"
- it "queries zone_manager.get_intensity() for the player's position"
- it "lerps current_intensity toward target_intensity by lerp_rate each globalstep"
- it "calls player:set_sky() with night_sky and night_horizon interpolated between default blue (#00007a) and pollution orange (#c86400) proportional to current_intensity"
- it "applies no sky changes when minetest.get_timeofday() indicates daytime (0.23–0.77)"
- it "restores the player's saved sky definition when current_intensity returns to 0.0"
- it "saves the player's original sky definition on the first update call"
- it "cleans up per-player state and restores sky when the player leaves via minetest.register_on_leaveplayer"
- it "maintains independent current_intensity per player so two players in different zones see different sky colors simultaneously"

### describe "Configuration (Iteration 1 settings)"
- it "reads all Iteration 1 settings from minetest.conf at startup"
- it "falls back to documented defaults when settings are absent"
- it "validates settings at startup and logs a warning for out-of-range values"

---

## Structural Requirements

- [ ] Mod directory name: `light_pollution`
- [ ] `mod.conf` declares `name = light_pollution`, minimum Luanti version ≥ 5.6.0, and optional deps `default`, `mcl_core`
- [ ] Files created this iteration: `mod.conf`, `init.lua`, `config.lua`, `compat.lua`, `scanner.lua`, `zone_manager.lua`, `effect_engine.lua`
- [ ] `api.lua` created as a minimal stub exposing the `light_pollution = {}` global table (no live wiring until Iteration 2)
- [ ] No hard-coded node names outside `compat.lua`
- [ ] No global state mutations outside module init paths
- [ ] Mod does not crash when optional dependencies are absent
- [ ] `spec/` directory created with test file stubs for: `config_spec.lua`, `compat_spec.lua`, `scanner_spec.lua`, `zone_manager_spec.lua`, `effect_engine_spec.lua`
- [ ] All Iteration 1 settings covered in `settingtypes.txt` stub (full documentation deferred to Iteration 2)

---

## Modularity & Extensibility Strategy

### Module Boundaries (Iteration 1)

| Module | File | Responsibility | Public Interface |
|---|---|---|---|
| Config | `config.lua` | Load and validate all minetest.conf settings | `config.get(key)`, `config.get_number(key)`, `config.get_bool(key)` |
| Compat | `compat.lua` | Build default source node lists for MTG and VoxeLibre | `compat.default_sources()` → `[]{name, weight}` |
| API stub | `api.lua` | Expose `light_pollution` global table; source registry (read by scanner) | `light_pollution.source_registry` table |
| Scanner | `scanner.lua` | VoxelManip scan; dirty tracking; placenode/dignode events | `scanner.scan_around(pos, radius)` → `{light_score, positions[]}`; `scanner.mark_dirty(pos)` |
| Zone Manager | `zone_manager.lua` | Zone compute, cache, intensity falloff query | `zone_manager.get_intensity(pos)` → `{intensity, center, radius}` |
| Effect Engine | `effect_engine.lua` | Per-player sky tint; lerp state; save/restore sky | `effect_engine.update(player)` |
| Init | `init.lua` | Wire modules; register globalstep + node events | — |

### Composition Flow

```
init.lua
  ├── config.lua         (no dependencies)
  ├── compat.lua         (config)
  ├── api.lua            (config — stub only this iteration)
  ├── scanner.lua        (config, api.source_registry)
  ├── zone_manager.lua   (config, scanner)
  └── effect_engine.lua  (config, zone_manager)
```

### API Stub Contract

`api.lua` in Iteration 1 only needs to expose:
```lua
light_pollution = {
  source_registry = {},  -- populated by init.lua from compat.default_sources()
}
```
Full `register_source`, `add_zone`, `get_intensity`, etc. are wired in Iteration 2.

---

## Technical Architecture

### Luanti APIs Used (Iteration 1)

| Purpose | API |
|---|---|
| Sky color tinting | [`player:set_sky(sky_def)`](https://docs.luanti.org/modding/reference/lua-api/) — `type = "regular"`, `sky_color.night_sky`, `sky_color.night_horizon` |
| Bulk node scan | `minetest.get_voxel_manip(p1, p2)`, `VoxelManip:get_data()`, `minetest.get_content_id()` |
| Event-driven dirty | `minetest.register_on_placenode(func)`, `minetest.register_on_dignode(func)` |
| Periodic update | `minetest.register_globalstep(func)` — throttled with elapsed time accumulator |
| Time of day | `minetest.get_timeofday()` → float in [0.0, 1.0]; daytime = 0.23–0.77 |
| Game detection | `minetest.get_modpath(name)` |
| Settings | `minetest.settings:get(key)`, `minetest.settings:get_bool(key)`, `minetest.settings:get_int(key)` |
| Player cleanup | `minetest.register_on_leaveplayer(func)` |

### Data Model (Iteration 1)

**Source Registry** (populated at load from compat + api.source_registry):
```lua
source_registry = {
  ["default:lava_source"]  = { weight = 14 },
  ["default:lava_flowing"] = { weight = 14 },
  ["fire:basic_flame"]     = { weight = 13 },
  ["default:torch"]        = { weight = 12 },
  -- VoxeLibre equivalents added when mcl_core detected
}
```

**Content ID Cache** (in scanner, rebuilt when source_registry changes):
```lua
content_id_cache = {
  [content_id_number] = weight,  -- for fast VoxelManip lookup
}
```

**Zone Cache** (in zone_manager):
```lua
zone_cache = {
  [mapblock_hash] = {
    center      = {x, y, z},
    radius      = number,
    intensity   = number,   -- 0.0–1.0
    light_score = number,
    dirty       = bool,
    updated_at  = os.time(),
  }
}
```

**Per-Player Effect State** (in effect_engine):
```lua
player_state = {
  ["playerName"] = {
    current_intensity = number,   -- 0.0–1.0, currently rendered
    target_intensity  = number,   -- 0.0–1.0, from zone_manager
    sky_saved         = sky_def,  -- player's original sky (from player:get_sky())
    last_pos          = vector,   -- for move_threshold check
  }
}
```

### Settings (Iteration 1)

| Key | Type | Default | Description |
|---|---|---|---|
| `light_pollution.scan_radius` | int | 64 | Node radius to scan around players |
| `light_pollution.scan_interval` | float | 5.0 | Seconds between full rescans per player |
| `light_pollution.move_threshold` | int | 8 | Nodes moved before triggering rescan between intervals |
| `light_pollution.base_radius` | int | 32 | Minimum zone radius when threshold is met |
| `light_pollution.radius_scale_factor` | float | 10.0 | Divides light_score to determine extra radius |
| `light_pollution.max_intensity` | float | 1.0 | Maximum pollution intensity (0.0–1.0) |
| `light_pollution.lerp_rate` | float | 0.02 | Interpolation rate per globalstep |
| `light_pollution.zone_ttl` | int | 30 | Seconds before cached zone expires regardless of dirty flag |
| `light_pollution.source_types` | string | "both" | Which sources count: "natural", "artificial", "both" |

### Performance Considerations

- VoxelManip at default radius 64 reads a ~128³ cube (~2M nodes). At 5s interval with dirty-aware skipping, this is bounded.
- `move_threshold` prevents rescans when a player is standing still.
- Content ID cache in scanner avoids per-node string comparisons during VoxelManip iteration.
- Zone cache prevents redundant recalculation across globalsteps.

---

## Open Source / Free Resources

| Resource | Source | Usage | Notes |
|---|---|---|---|
| busted | https://lunarmodules.github.io/busted/ | Test runner | `luarocks install busted` |
| mineunit | https://github.com/S-S-X/mineunit | Luanti API mock | `luarocks install mineunit` |
| mineunit Docker | https://hub.docker.com/r/mineunit/mineunit | Windows test execution | ⚠️ **Windows**: `docker pull mineunit/mineunit` required |
| Luanti Lua API | https://docs.luanti.org/modding/reference/lua-api/ | Engine API reference | — |

---

## Implementation Approach

### Step 1 — Scaffold mod structure
Create all files and directories:
```
light_pollution/
  mod.conf
  settingtypes.txt          (stub — full content in Iteration 2)
  init.lua                  (stub — filled in Step 8)
  config.lua
  compat.lua
  api.lua                   (stub — source_registry only)
  scanner.lua
  zone_manager.lua
  effect_engine.lua
  spec/
    config_spec.lua
    compat_spec.lua
    scanner_spec.lua
    zone_manager_spec.lua
    effect_engine_spec.lua
```
Reference: [Mod structure](https://docs.luanti.org/modding/getting-started/creating-a-mod/)

### Step 2 — Implement `mod.conf`
```
name = light_pollution
description = Simulates light pollution from large light-emitting node clusters
min_minetest_version = 5.6.0
optional_depends = default, mcl_core, fire, mcl_fire, mcl_torches, mcl_nether
```

### Step 3 — Implement `config.lua`
- Load all 9 Iteration 1 settings from `minetest.settings`.
- Validate: `scan_radius > 0`, `scan_interval > 0`, `lerp_rate` in (0.001, 1.0], `max_intensity` in (0.0, 1.0].
- Log warning for invalid values; clamp to nearest valid value.
- Expose `config.get(key)` returning cached typed value.

### Step 4 — Implement `compat.lua`
- Detect game via `minetest.get_modpath("default")` (MTG) and `minetest.get_modpath("mcl_core")` (VoxeLibre).
- Build source list per game:
  - MTG naturals: `default:lava_source` (14), `default:lava_flowing` (14), `fire:basic_flame` (13)
  - MTG artificials: `default:torch` (12), `default:meselamp` (15), `default:mese` (15)
  - VoxeLibre naturals: `mcl_core:lava_source` (14), `mcl_fire:fire` (13)
  - VoxeLibre artificials: `mcl_torches:torch` (12), `mcl_nether:glowstone` (15)
- Filter by `config.get("source_types")`.
- Return filtered list; return `{}` if no game detected (no error).

### Step 5 — Implement `api.lua` (stub)
```lua
light_pollution = {
  source_registry = {},
}
```
This global is populated by `init.lua` after compat loads. Full API functions added in Iteration 2.

### Step 6 — Implement `scanner.lua`
- Maintain `dirty_mapblocks = {}` and `content_id_cache = {}`.
- `scanner.rebuild_content_id_cache()`: iterate `light_pollution.source_registry`, call `minetest.get_content_id(name)` for each, populate `content_id_cache[id] = weight`. Called once at load and whenever source_registry changes.
- `scanner.mark_dirty(pos)`: compute mapblock corner (`math.floor(pos.x/16)*16`, etc.), hash it, set `dirty_mapblocks[hash] = true`.
- `scanner.scan_around(pos, radius)`:
  - Compute `p1 = pos - {radius,radius,radius}`, `p2 = pos + {radius,radius,radius}`.
  - Call `minetest.get_voxel_manip(p1, p2)`.
  - Get content data with `VoxelManip:get_data()` and area with `VoxelManip:get_emerged_area()`.
  - Iterate all positions in area; for each content ID in `content_id_cache`, accumulate `light_score += weight` and append position to `source_positions`.
  - Return `{light_score = n, positions = [...]}`.
- Register `minetest.register_on_placenode` and `minetest.register_on_dignode`: if node name is in `light_pollution.source_registry`, call `scanner.mark_dirty(pos)`.

Reference: [VoxelManip](https://docs.luanti.org/modding/reference/voxelmanipulator/)

### Step 7 — Implement `zone_manager.lua`
- Define `local LIGHT_SCORE_MAX = 500`.
- Maintain `zone_cache = {}`.
- `zone_manager.get_intensity(pos)`:
  - Compute player's mapblock hash.
  - If cached, not dirty, and not expired: return cached intensity scaled by distance falloff.
  - Otherwise: call `scanner.scan_around(pos, scan_radius)`.
  - If `light_score == 0`: cache `{intensity=0}`, return 0.
  - Compute centroid: weighted average of source positions by weight.
  - Compute `radius = base_radius + light_score / radius_scale_factor`.
  - Compute `intensity = math.min(light_score / LIGHT_SCORE_MAX, max_intensity)`.
  - Store in `zone_cache[hash]`; clear dirty flag.
  - Apply distance falloff to queried pos: `local dist = vector.distance(pos, center); if dist >= radius then return 0 end; return intensity * (1.0 - dist/radius)`.
- Zone merge (overlapping zones): sum falloff intensities across all cached zones whose radius covers `pos`; cap at `max_intensity`.

Reference: [Lua API — vector helpers](https://docs.luanti.org/modding/reference/lua-api/)

### Step 8 — Implement `effect_engine.lua` (sky tint only)
- Maintain `player_state = {}`.
- `effect_engine.update(player)`:
  1. Get `pos = player:get_pos()`.
  2. Check move threshold: if `vector.distance(pos, state.last_pos) < move_threshold` and no dirty mapblocks in radius, skip rescan (use existing `target_intensity`).
  3. Set `target_intensity = zone_manager.get_intensity(pos)`.
  4. Check daytime: if `minetest.get_timeofday()` is in (0.23, 0.77), set `target_intensity = 0`.
  5. Lerp: `current_intensity = current_intensity + (target_intensity - current_intensity) * lerp_rate`.
  6. If delta > 0.001:
     - Interpolate `night_sky` color: `r = math.floor(0x00 + (0xc8 - 0x00) * current_intensity)`, same for g (`0x00`→`0x64`) and b (`0x7a`→`0x00`). Format as `"#RRGGBB"`.
     - Call `player:set_sky({type="regular", sky_color={night_sky=color, night_horizon=color}})`.
  7. If `current_intensity < 0.001` and `state.sky_saved`: call `player:set_sky(state.sky_saved)`.
  8. Update `state.last_pos = pos`.
- On first call per player: `state.sky_saved = player:get_sky()`.
- Register `minetest.register_on_leaveplayer`: restore `player:set_sky(state.sky_saved)`, remove `player_state[name]`.

Reference: [Sky API](https://docs.luanti.org/modding/reference/lua-api/), [HUD API](https://docs.luanti.org/modding/reference/hud/)

### Step 9 — Implement `init.lua`
```lua
local modpath = minetest.get_modpath("light_pollution")
dofile(modpath .. "/config.lua")
dofile(modpath .. "/compat.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/scanner.lua")
dofile(modpath .. "/zone_manager.lua")
dofile(modpath .. "/effect_engine.lua")

-- Seed source registry from compat
for _, source in ipairs(compat.default_sources()) do
  light_pollution.source_registry[source.name] = { weight = source.weight }
end
scanner.rebuild_content_id_cache()

-- Globalstep: throttled per-player update
local elapsed = 0
local scan_interval = config.get("scan_interval")
minetest.register_globalstep(function(dtime)
  elapsed = elapsed + dtime
  if elapsed < scan_interval then return end
  elapsed = 0
  for _, player in ipairs(minetest.get_connected_players()) do
    effect_engine.update(player)
  end
end)
```

---

## Testing & Validation

**Stack**: [busted](https://lunarmodules.github.io/busted/) + [mineunit](https://github.com/S-S-X/mineunit)
**Test files**: `spec/*_spec.lua`
**Windows**: `docker run --rm -v %cd%:/mod mineunit/mineunit`

### Unit Tests

```lua
-- spec/config_spec.lua
describe("config module", function()
  it("returns default scan_radius when setting is absent", function() ... end)
  it("returns default scan_interval when setting is absent", function() ... end)
  it("logs a warning when scan_radius is set to 0 or negative", function() ... end)
  it("returns correct typed value for each setting key", function() ... end)
end)

-- spec/compat_spec.lua
describe("compat module", function()
  it("returns MTG node names when only 'default' modpath is present", function() ... end)
  it("returns VoxeLibre node names when only 'mcl_core' modpath is present", function() ... end)
  it("filters to natural sources only when source_types is 'natural'", function() ... end)
  it("filters to artificial sources only when source_types is 'artificial'", function() ... end)
  it("returns both types when source_types is 'both'", function() ... end)
  it("returns empty list without error when no game modpath is detected", function() ... end)
end)

-- spec/scanner_spec.lua
describe("scanner module", function()
  it("returns light_score 0 when no registered sources are in range", function() ... end)
  it("accumulates weight for each source node found in the scanned volume", function() ... end)
  it("marks a mapblock dirty when a registered source is placed in it", function() ... end)
  it("marks a mapblock dirty when a registered source is removed from it", function() ... end)
  it("does not mark dirty when an unregistered node is placed", function() ... end)
  it("rebuilds content_id_cache correctly when source_registry is updated", function() ... end)
end)

-- spec/zone_manager_spec.lua
describe("zone_manager module", function()
  it("returns intensity 0.0 when scanner finds no sources", function() ... end)
  it("computes radius larger than base_radius when light_score is above zero", function() ... end)
  it("returns cached zone data on second call when not dirty and not expired", function() ... end)
  it("recomputes zone when dirty flag is set", function() ... end)
  it("recomputes zone when TTL has expired", function() ... end)
  it("returns falloff intensity less than peak at the zone edge", function() ... end)
  it("returns 0.0 intensity when player position is outside zone radius", function() ... end)
  it("caps intensity at max_intensity even when light_score is very high", function() ... end)
  it("merges two overlapping zones and caps combined intensity at max_intensity", function() ... end)
  it("skips rescan when player has not moved past move_threshold", function() ... end)
end)

-- spec/effect_engine_spec.lua
describe("effect engine (sky tint)", function()
  it("does not alter sky when intensity is 0.0", function() ... end)
  it("calls player:set_sky() with orange-tinted night_sky color at intensity 1.0", function() ... end)
  it("does not apply sky changes when minetest.get_timeofday() indicates daytime", function() ... end)
  it("interpolates current_intensity toward target_intensity at lerp_rate per step", function() ... end)
  it("restores original sky when current_intensity reaches 0.0", function() ... end)
  it("restores original sky when player leaves", function() ... end)
  it("maintains separate sky state for two players at different intensities", function() ... end)
end)
```

### Integration Tests

```lua
-- spec/integration_spec.lua
describe("light pollution integration (Iteration 1)", function()
  it("player near a simulated lava cluster sees orange sky tint after globalstep fires", function()
    -- Place lava nodes via world:set_node, run globalsteps, verify player:set_sky called with orange color
  end)
  it("player moving away from zone sees sky tint fade to zero over time", function()
    -- Move player beyond radius, run globalsteps, verify sky restored to saved value
  end)
  it("two players in different zones see independently tinted skies", function()
    -- Two players, two clusters, assert distinct set_sky calls with different colors
  end)
  it("removing all lava nodes dissolves the zone and sky returns to normal", function()
    -- Place nodes, scan, remove all, trigger dirty, run globalsteps, assert intensity 0
  end)
end)
```

### Iteration 1 Completion Checkpoint

| Check | Type | Status |
|---|---|---|
| All unit spec files pass | Unit (Docker) | Required before Iteration 2 |
| Integration: lava cluster → sky tint | Integration (Docker) | Required before Iteration 2 |
| In-game smoke test: sky orange near lava at night | Manual (Luanti) | Required before Iteration 2 |
| In-game smoke test: sky restores when walking away | Manual (Luanti) | Required before Iteration 2 |
| No crash with no game (empty world) | Manual (Luanti) | Required before Iteration 2 |

---

## Decision Log

**Decision:** API stub only in Iteration 1
**Alternatives considered:** Full API in Iteration 1; no API module until Iteration 2
**Why chosen:** Creating the global `light_pollution` table early lets `init.lua` and `scanner.lua` reference `light_pollution.source_registry` without circular dependencies. Full wiring deferred keeps Iteration 1 scope minimal.
**Impact:** `api.lua` is created but mostly empty. Iteration 2 fills it in without structural changes.
