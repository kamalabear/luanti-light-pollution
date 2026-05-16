# light_pollution — Implementation Spec

> ⚠️ This spec has been broken into iterations. See [light_pollution-overview-spec.md](light_pollution-overview-spec.md) for the full plan.
> - [Iteration 1 — Core Sensing + Sky Tint](light_pollution-iteration-1-spec.md)
> - [Iteration 2 — Full Effects + Extensibility](light_pollution-iteration-2-spec.md)

## Overview

`light_pollution` is a Luanti mod that simulates light pollution from large clusters of light-emitting nodes (lava fields, villages, lamp farms, etc.). It creates a graduated visual atmosphere for players near bright areas: a warm sky glow, reduced star visibility, and degraded night vision. The pollution zone scales with the density and total intensity of nearby light sources, and a public API lets other mods register their own sources or zones.

---

## Objectives & Success Criteria

**Purpose:** Give worlds a sense of lived-in atmosphere at night by making large artificial or natural light clusters visible from a distance as a hazy sky glow, while also subtly penalizing night visibility for players inside the zone. Provides an incentive for players to build away from concentrated light sources if they want clear skies.

**Success Criteria:**

- it "shows an orange/amber sky glow visible to a player standing within the pollution zone at night"
- it "reduces star count and opacity proportionally to pollution intensity"
- it "applies a hazy HUD overlay that tints and dims the player's view inside the zone"
- it "scales the zone radius and intensity as more light-emitting nodes are added to a cluster"
- it "removes the visual effects when a player leaves the pollution zone radius"
- it "transitions effects gradually as a player moves toward or away from the zone center"
- it "allows server admins to configure which node types contribute to pollution via minetest.conf"
- it "allows server admins to configure mob spawning behavior inside pollution zones via minetest.conf"
- it "allows other mods to register custom light sources and manual zones through a Lua API"
- it "works with both Minetest Game (MTG) and MineClone2/VoxeLibre node sets out of the box"

---

## Functional Requirements

### describe "Light source scanner"
- it "detects all light-emitting nodes within a configurable scan radius around a player"
- it "sums the light level contributions of all detected sources to compute a total light score"
- it "excludes node types that are on the admin-configured exclusion list"
- it "includes node types that are on the admin-configured inclusion list (natural, artificial, or both)"
- it "re-scans a region when any tracked light-emitting node is placed or removed in it"
- it "performs a full re-scan on a timer interval when a player is near a chunk boundary"
- it "uses VoxelManip for bulk node reads to avoid per-node API overhead"

### describe "Zone manager"
- it "calculates a pollution zone center as the weighted centroid of detected light sources"
- it "calculates zone radius as a function of total light score: radius = base_radius + (light_score / radius_scale_factor)"
- it "calculates zone intensity as a value between 0.0 and 1.0 proportional to light_score up to a configured max"
- it "caches zone data per mapblock hash to avoid redundant recalculation"
- it "invalidates a cached zone when its region is marked dirty by the event-driven scanner"
- it "invalidates a cached zone after a configurable TTL has elapsed"
- it "merges overlapping zones into a single combined zone rather than stacking independent effects"
- it "returns intensity 0.0 for positions outside all active zones"
- it "exposes a query function returning intensity and zone metadata for any world position"

### describe "Effect engine"
- it "reads each connected player's position on every globalstep"
- it "queries the zone manager for intensity at the player's position"
- it "interpolates current displayed intensity toward target intensity each globalstep at a configurable lerp rate"
- it "sets the player's night sky and horizon color to an orange/amber tint scaled by current intensity using player:set_sky()"
- it "restores the player's original sky color when intensity returns to 0.0"
- it "sets star count and night_opacity proportionally reduced by intensity using player:set_stars()"
- it "restores full stars when intensity returns to 0.0"
- it "adds a fullscreen semi-transparent HUD image overlay when intensity exceeds a configurable threshold"
- it "scales HUD overlay opacity with current intensity up to a configured maximum"
- it "removes the HUD overlay when intensity drops back below the threshold"
- it "applies no visual changes during daytime (minetest.get_timeofday() check)"
- it "tracks per-player state so different players in different zones see different effects simultaneously"

### describe "Mob spawning integration"
- it "when mob_spawning_mode is 'suppress', reactively removes hostile mobs that spawn inside pollution zones via ABM (note: no universal pre-spawn hook exists across MTG and VoxeLibre mob frameworks; ABM removal runs post-spawn)"
- it "when mob_spawning_mode is 'attract', increases hostile mob spawn rate inside pollution zones"
- it "when mob_spawning_mode is 'none', does not alter mob spawning behavior (default)"
- it "applies mob spawning behavior only within the computed zone radius"

### describe "Public API"
- it "allows any mod to register a node name as a pollution source with a custom intensity weight via light_pollution.register_source(node_name, weight)"
- it "allows any mod to unregister a source via light_pollution.unregister_source(node_name)"
- it "allows any mod to programmatically add a manual pollution zone at a position via light_pollution.add_zone(pos, radius, intensity)"
- it "allows any mod to remove a manually added zone via light_pollution.remove_zone(zone_id)"
- it "allows any mod to query pollution intensity at any position via light_pollution.get_intensity(pos)"
- it "fires a registered callback when a player's pollution intensity changes tier via light_pollution.register_on_intensity_change(callback)"

### describe "Configuration"
- it "reads all settings from minetest.conf at startup via minetest.settings:get()"
- it "falls back to safe defaults when a setting is absent"
- it "validates settings at startup and logs a warning for out-of-range values"

---

## Structural Requirements

- [ ] Mod directory name: `light_pollution` (underscore convention)
- [ ] `mod.conf` declares `name = light_pollution`, Luanti min version, and optional dependencies
- [ ] Optional dependencies declared: `default` (MTG), `mcl_core` (MineClone2/VoxeLibre)
- [ ] All configurable values exposed as `minetest.settings` keys under the `light_pollution.*` namespace
- [ ] Settings documented in `settingtypes.txt` (includes all 16 settings from the settings table above)
- [ ] HUD overlay texture: `textures/light_pollution_overlay.png` (16x16 or 1x1 semi-transparent PNG, tileable)
- [ ] No hard-coded node names outside `compat.lua`
- [ ] No global state mutations outside module init paths
- [ ] Public API available at `light_pollution` global table after `init.lua` loads
- [ ] Mod must not crash when optional dependencies are absent

---

## Modularity & Extensibility Strategy

### Module Boundaries

| Module | File | Responsibility | Public Interface |
|---|---|---|---|
| Config | `config.lua` | Load and validate all minetest.conf settings; provide typed getters | `config.get(key)`, `config.get_number(key)`, `config.get_bool(key)` |
| Compat | `compat.lua` | Build default node name lists for MTG and VoxeLibre; detect active game | `compat.default_sources()` → list of `{name, weight}` |
| API | `api.lua` | Expose public `light_pollution.*` table; manage registered sources and manual zones | `register_source`, `unregister_source`, `add_zone`, `remove_zone`, `get_intensity`, `register_on_intensity_change` |
| Scanner | `scanner.lua` | VoxelManip-based region scan; event-driven dirty tracking; timer-based refresh | `scanner.scan_around(pos, radius)` → `light_score`; `scanner.mark_dirty(pos)` |
| Zone Manager | `zone_manager.lua` | Compute, cache, and query pollution zones from scanner data | `zone_manager.get_intensity(pos)` → `{intensity, center, radius}` |
| Effect Engine | `effect_engine.lua` | Per-player effect state; sky/stars/HUD application via player API | `effect_engine.update(player, intensity)` |
| Init | `init.lua` | Wire all modules together; register globalstep, on_placenode, on_dignode | none (entry point) |

### Composition Flow

```
init.lua
  ├── config.lua         (loaded first — no dependencies)
  ├── compat.lua         (depends on config)
  ├── api.lua            (depends on config — exposes global table early)
  ├── scanner.lua        (depends on config, api)
  ├── zone_manager.lua   (depends on config, scanner, api)
  └── effect_engine.lua  (depends on config, zone_manager)
```

### Extensibility Notes

- Other mods may call `light_pollution.register_source()` during their own `init.lua` load. The API table is populated before any dofile chains complete, so load order is safe.
- `add_zone` / `remove_zone` allow worldgen mods or adventure scenarios to programmatically create pollution zones (e.g., a cursed volcano area) without any nodes present.
- The `register_on_intensity_change` callback enables downstream mods to trigger their own effects (sounds, particles, events) on intensity tier transitions.

### Reuse Decision

| Capability | Decision | Rationale |
|---|---|---|
| Sky tinting | **Build** (Luanti player API) | `player:set_sky()` with `sky_color` sub-table natively supports per-channel night sky color; no external library needed |
| Star reduction | **Build** (Luanti player API) | `player:set_stars()` with `night_opacity`/`count` fields is available since Luanti 5.6 |
| HUD overlay | **Build** (Luanti HUD API) | `player:hud_add()` with `type = "image"` and a 1x1 semi-transparent PNG is the standard pattern |
| Bulk node scanning | **Build** (VoxelManip) | `minetest.get_voxel_manip()` is the correct performant approach; no library wraps this better |
| Test framework | **Adopt** busted + mineunit | Standard Luanti community testing stack; Docker path on Windows |

---

## Technical Architecture

### Luanti APIs Used

| Purpose | API |
|---|---|
| Sky color tinting | [`player:set_sky(sky_def)`](https://docs.luanti.org/modding/reference/lua-api/) — `type = "regular"`, `sky_color.night_sky`, `sky_color.night_horizon` |
| Star visibility | `player:set_stars({count, night_opacity, day_opacity})` |
| Night vision HUD | `player:hud_add({type = "image", text = "light_pollution_overlay.png", scale = {x=-1,y=-1}, position={x=0.5,y=0.5}, alignment={x=0,y=0}})` |
| Bulk node scan | `minetest.get_voxel_manip(p1, p2)`, `VoxelManip:get_data()`, `minetest.get_content_id()` |
| Event-driven updates | `minetest.register_on_placenode(func)`, `minetest.register_on_dignode(func)` |
| Timer-based updates | `minetest.register_globalstep(func)` — throttled with elapsed time accumulator |
| Settings | `minetest.settings:get(key)`, `minetest.settings:get_bool(key)` |
| Mob spawning | `minetest.register_abm()` targeting mob nodes when suppress/attract mode is active; ⚠️ `register_on_mobs_spawn` is **not** a Luanti core API — it exists only in `mobs_redo` / `mcl_mobs`. When neither framework is present, mob spawning integration silently skips. |

### Data Model

**Source Registry** (in-memory, populated at load + via API):
```
source_registry = {
  ["default:lava_source"] = { weight = 14 },
  ["default:torch"] = { weight = 12 },
  -- ...
}
```

**Zone Cache** (per mapblock, keyed by hash of mapblock corner):
```
zone_cache = {
  [mapblock_hash] = {
    center      = {x, y, z},
    radius      = number,        -- computed nodes
    intensity   = number,        -- 0.0–1.0
    light_score = number,        -- raw summed weight
    dirty       = bool,
    updated_at  = os.time(),
  }
}
```

**Per-Player Effect State** (keyed by player name):
```
player_state = {
  ["playerA"] = {
    current_intensity = number,  -- 0.0–1.0, current rendered value
    target_intensity  = number,  -- 0.0–1.0, computed from zone
    hud_id            = number or nil,
    sky_saved         = sky_def or nil,  -- player's original sky def
    stars_saved       = stars_def or nil,
  }
}
```

### Detection Strategy: Hybrid

The mod uses a **hybrid approach** balancing performance and correctness:

1. **Event-driven invalidation**: `on_placenode` / `on_dignode` — when a registered light source node is placed or removed, the containing mapblock is marked dirty in `zone_cache`. No scan is triggered immediately.

2. **Player-centered periodic scan**: `globalstep` accumulates elapsed time. Every `scan_interval` seconds (default: 5s), for each connected player: scan the sphere of radius `scan_radius` nodes around the player using VoxelManip, aggregate light scores, compute/update zone data, and apply effects.

3. **Dirty-priority rescan**: If any mapblock in the player's scan radius is dirty, it is recalculated before the next full interval expires (on next globalstep after dirty flag set).

This handles chunk boundaries because scans are player-centered and run on a timer regardless of world state. It avoids per-frame scanning by throttling to `scan_interval`.

### Performance Considerations

- VoxelManip reads a cube of `scan_radius * 2` nodes — at default radius 64 nodes, this is ~128³ = ~2M nodes per scan per player. Scan interval of 5s and scan on dirty only keeps CPU impact low.
- Zone cache reduces redundant calculations: if no dirty mapblocks and player hasn't moved more than `move_threshold` nodes, skip rescan.
- Effect interpolation (`lerp`) runs every globalstep but is a simple arithmetic operation — cheap.
- Mob spawning ABM only registers if mode is not `none`.
- Scan radius and interval are both configurable so server admins can tune for performance.

### Settings (settingtypes.txt)

| Key | Type | Default | Description |
|---|---|---|---|
| `light_pollution.scan_radius` | int | 64 | Node radius to scan around players for light sources |
| `light_pollution.scan_interval` | float | 5.0 | Seconds between full rescans per player |
| `light_pollution.move_threshold` | int | 8 | Nodes a player must move before triggering a rescan between intervals |
| `light_pollution.base_radius` | int | 32 | Minimum zone radius when threshold is met |
| `light_pollution.radius_scale_factor` | float | 10.0 | Divides light_score to determine extra radius |
| `light_pollution.max_intensity` | float | 1.0 | Maximum pollution intensity (0.0–1.0) |
| `light_pollution.lerp_rate` | float | 0.02 | Interpolation rate per globalstep (higher = faster transition) |
| `light_pollution.hud_threshold` | float | 0.2 | Intensity at which HUD overlay begins appearing |
| `light_pollution.hud_max_opacity` | float | 0.5 | Maximum HUD overlay opacity (0.0–1.0) |
| `light_pollution.zone_ttl` | int | 30 | Seconds before cached zone data expires regardless of dirty flag |
| `light_pollution.source_types` | string | "both" | Which sources count: "natural", "artificial", "both" |
| `light_pollution.mob_spawning_mode` | string | "none" | Mob spawning behavior: "none", "suppress", "attract" |
| `light_pollution.suppress_threshold` | float | 0.3 | Minimum intensity at which mob suppression/attraction activates |
| `light_pollution.tier_low` | float | 0.15 | Intensity threshold for low pollution tier (fires intensity_change callback) |
| `light_pollution.tier_medium` | float | 0.45 | Intensity threshold for medium pollution tier |
| `light_pollution.tier_high` | float | 0.75 | Intensity threshold for high pollution tier |

---

## Open Source / Free Resources

| Resource | Source | Usage | Notes |
|---|---|---|---|
| busted | https://lunarmodules.github.io/busted/ | Test runner | `luarocks install busted` |
| mineunit | https://github.com/S-S-X/mineunit | Luanti API mock + engine simulation | `luarocks install mineunit` |
| mineunit Docker | https://hub.docker.com/r/mineunit/mineunit | Windows test execution | ⚠️ **Windows blocker**: mineunit does not run natively on Windows — use `docker pull mineunit/mineunit` and run tests via Docker |
| HUD overlay texture | Hand-authored or CC0 | 1×1 orange semi-transparent PNG | No external asset needed; can be generated with any image editor |
| Luanti Lua API | https://docs.luanti.org/modding/reference/lua-api/ | Core engine API reference | — |

---

## Implementation Approach

### Step 1 — Scaffold mod structure
Create the following files:
```
light_pollution/
  mod.conf
  settingtypes.txt
  init.lua
  config.lua
  compat.lua
  api.lua
  scanner.lua
  zone_manager.lua
  effect_engine.lua
  textures/
    light_pollution_overlay.png
  spec/
    config_spec.lua
    compat_spec.lua
    scanner_spec.lua
    zone_manager_spec.lua
    effect_engine_spec.lua
    api_spec.lua
```
Reference: [Mod structure](https://docs.luanti.org/modding/getting-started/creating-a-mod/)

### Step 2 — Implement `config.lua`
- Use `minetest.settings:get()` / `:get_bool()` / `:get_int()` to load all settings from the table above.
- Validate ranges (e.g., scan_radius > 0, lerp_rate between 0.001 and 1.0).
- Log warnings with `minetest.log("warning", ...)` for out-of-range values.
- Expose `config.get(key)` returning the typed value.
Reference: [Settings API](https://docs.luanti.org/modding/reference/lua-api/)

### Step 3 — Implement `compat.lua`
- Check `minetest.get_modpath("default")` and `minetest.get_modpath("mcl_core")` to detect active game.
- Return default source lists:
  - MTG naturals: `default:lava_source`, `default:lava_flowing` (weight 14); `fire:basic_flame` (weight 13)
  - MTG artificials: `default:torch` (12), `default:meselamp` (15), `default:mese` (15)
  - VoxeLibre naturals: `mcl_core:lava_source`, `mcl_fire:fire` (equivalent weights)
  - VoxeLibre artificials: `mcl_torches:torch`, `mcl_nether:glowstone` (equivalent weights)
- Filter by `config.get("source_types")` setting.

### Step 4 — Implement `api.lua`
- Create `light_pollution = {}` global table.
- Maintain `source_registry` table (node_name → weight).
- Maintain `manual_zones` table (zone_id → {pos, radius, intensity}).
- Maintain `intensity_callbacks` list.
- Implement all 6 public functions as stubs initially; connect to real scanner/zone_manager data in Step 7.
Reference: [Mod namespacing](https://docs.luanti.org/modding/best-practices/)

### Step 5 — Implement `scanner.lua`
- Maintain `dirty_mapblocks` set (mapblock hash → true).
- `scanner.mark_dirty(pos)`: compute mapblock hash for `pos`, set dirty.
- `scanner.scan_around(pos, radius)`:
  - Compute bounding box from `pos ± radius`.
  - Call `minetest.get_voxel_manip(p1, p2)` to load area.
  - Iterate content IDs; for each content ID matching a registered source, accumulate `light_score += weight`.
  - Return `{light_score, source_positions[]}` (source positions used for centroid calculation).
- Register `minetest.register_on_placenode` and `minetest.register_on_dignode`: if placed/dug node is in `source_registry`, call `scanner.mark_dirty(pos)`.
Reference: [VoxelManip](https://docs.luanti.org/modding/reference/voxelmanipulator/), [ABMs and LBMs](https://docs.luanti.org/modding/reference/abms-and-lbms/)

### Step 6 — Implement `zone_manager.lua`
- Maintain `zone_cache` table (mapblock_hash → zone_data).
- `zone_manager.compute_zone(player_pos)`:
  - Check cache: if not dirty and not expired, return cached.
  - Call `scanner.scan_around(player_pos, scan_radius)`.
  - If `light_score == 0`, return `{intensity = 0}`.
  - Compute centroid from source positions.
  - Compute `radius = base_radius + light_score / radius_scale_factor`.
  - Compute `intensity = math.min(light_score / LIGHT_SCORE_MAX, max_intensity)` where `LIGHT_SCORE_MAX = 500` is a named module constant in `zone_manager.lua` (not a setting — changing it would alter zone scaling for all operators; treat as an implementation constant).
  - Update cache, clear dirty flags.
- `zone_manager.get_intensity(pos)`:
  - Find nearest zone from cache whose radius covers `pos`.
  - Compute intensity scaled by distance from center (linear falloff: `1.0 - dist/radius`).
  - Return merged intensity across all overlapping zones (capped at max_intensity).
Reference: [Vector helpers](https://docs.luanti.org/modding/reference/lua-api/)

### Step 7 — Implement `effect_engine.lua`
- Maintain `player_state` table (player_name → state).
- `effect_engine.update(player)`:
  - Get `target_intensity` from `zone_manager.get_intensity(player:get_pos())`.
  - Lerp `current_intensity` toward `target_intensity` by `lerp_rate`.
  - If `current_intensity` changed meaningfully (> 0.001 delta):
    - Compute `night_sky_color` as linear interpolation between default night (`#00007a`) and pollution orange (`#c86400`) by `current_intensity`.
    - Call `player:set_sky({type="regular", sky_color={night_sky=..., night_horizon=...}})`.
    - Call `player:set_stars({night_opacity = math.max(0, 1.0 - current_intensity * 1.5), count = math.floor(1000 * (1 - current_intensity))})`.
    - Update HUD overlay opacity (add if missing, remove if below threshold).
- Save player's original sky/stars on first `update` call; restore on player leave.
- Register `minetest.register_on_leaveplayer` to clean up state.
Reference: [Sky API](https://docs.luanti.org/for-creators/), [HUD API](https://docs.luanti.org/modding/reference/hud/)

### Step 8 — Implement `init.lua`
- `dofile` modules in dependency order: config → compat → api → scanner → zone_manager → effect_engine.
- Seed `source_registry` from `compat.default_sources()` + API-registered sources.
- Register globalstep with elapsed time accumulator:
  ```lua
  local elapsed = 0
  minetest.register_globalstep(function(dtime)
    elapsed = elapsed + dtime
    if elapsed < scan_interval then return end
    elapsed = 0
    for _, player in ipairs(minetest.get_connected_players()) do
      effect_engine.update(player)
    end
  end)
  ```
- Register mob spawning ABM if `mob_spawning_mode ~= "none"` (see Step 9).

### Step 9 — Implement mob spawning integration
- **Limitation**: No universal pre-spawn hook exists across both MTG (`mobs_redo`) and VoxeLibre (`mcl_mobs`) mob frameworks. Mob suppression/attraction is implemented as a reactive ABM that acts on already-spawned mob entities, not a true spawn-prevention hook. This is an acknowledged constraint — document it in a code comment.
- If `mob_spawning_mode == "suppress"`: register ABM targeting hostile mob nodes (resolved via compat layer: `mobs_monster:*` for MTG, `mcl_mobs:*` hostile for VoxeLibre) that removes the entity via `object:remove()` if `zone_manager.get_intensity(pos) > suppress_threshold`. If neither mob framework is detected, log a warning and skip registration.
- If `mob_spawning_mode == "attract"`: register ABM that spawns an additional mob entity of the same type at a random nearby position if `zone_manager.get_intensity(pos) > suppress_threshold`. If neither mob framework is detected, log a warning and skip registration.
- Flag this as game-dependent: the exact ABM target node names differ between MTG and VoxeLibre. Use compat layer to resolve.
Reference: [ABM Reference](https://docs.luanti.org/modding/reference/abms-and-lbms/)

### Step 10 — Wire `api.lua` to live data
- Connect `light_pollution.get_intensity(pos)` to `zone_manager.get_intensity(pos)`.
- Connect `light_pollution.add_zone` / `remove_zone` to inject/remove entries in `zone_manager.zone_cache`.
- Fire `intensity_callbacks` from `effect_engine.update` when intensity crosses a tier boundary. Tiers are defined by settings `tier_low`, `tier_medium`, `tier_high` (defaults: 0.15, 0.45, 0.75). Tier names: `"none"`, `"low"`, `"medium"`, `"high"`. Callback signature: `callback(player_name, old_tier, new_tier)` where both tier values are one of those four strings.

### Step 11 — Create HUD overlay texture
- Create `textures/light_pollution_overlay.png`: a 16×16 RGBA PNG with solid orange-amber (#c86400) at ~40% alpha.
- The HUD element uses `scale = {x=-1, y=-1}` to stretch to full screen.

### Step 12 — Write `settingtypes.txt`
- Document all settings from the table in Technical Architecture using Luanti's `settingtypes.txt` format.
Reference: [settingtypes.txt format](https://docs.luanti.org/for-creators/settings/)

---

## Testing & Validation

**Stack**: [busted](https://lunarmodules.github.io/busted/) + [mineunit](https://github.com/S-S-X/mineunit)
**Test files**: `spec/*_spec.lua`
**Windows**: Run via Docker — `docker run --rm -v $(pwd):/mod mineunit/mineunit`

### Unit Tests

```lua
-- spec/config_spec.lua
describe("config module", function()
  it("returns default scan_radius when setting is absent", function() ... end)
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
end)

-- spec/scanner_spec.lua
describe("scanner module", function()
  it("returns light_score 0 when no registered sources are in range", function() ... end)
  it("accumulates weight for each source node found in the scanned volume", function() ... end)
  it("marks a mapblock dirty when a registered source is placed in it", function() ... end)
  it("marks a mapblock dirty when a registered source is removed from it", function() ... end)
  it("does not mark dirty when an unregistered node is placed", function() ... end)
end)

-- spec/zone_manager_spec.lua
describe("zone_manager module", function()
  it("returns intensity 0.0 when scanner finds no sources", function() ... end)
  it("computes radius larger than base_radius when light_score is above zero", function() ... end)
  it("returns cached zone data on second call when not dirty and not expired", function() ... end)
  it("recomputes zone when dirty flag is set", function() ... end)
  it("recomputes zone when TTL has expired", function() ... end)
  it("returns falloff intensity less than 1.0 at the edge of the zone radius", function() ... end)
  it("returns 0.0 intensity when player position is outside zone radius", function() ... end)
  it("caps intensity at max_intensity even when light_score is very high", function() ... end)
  it("merges two overlapping zones and caps combined intensity at max_intensity", function() ... end)
end)

-- spec/effect_engine_spec.lua
describe("effect engine", function()
  it("does not alter sky when intensity is 0.0", function() ... end)
  it("calls player:set_sky() with orange-tinted night_sky color at intensity 1.0", function() ... end)
  it("calls player:set_stars() with reduced count and opacity proportional to intensity", function() ... end)
  it("adds HUD overlay when intensity exceeds hud_threshold", function() ... end)
  it("removes HUD overlay when intensity drops below hud_threshold", function() ... end)
  it("interpolates current_intensity toward target_intensity at lerp_rate per step", function() ... end)
  it("restores original sky and stars when player leaves", function() ... end)
  it("maintains separate state for two players at different intensities", function() ... end)
end)

-- spec/api_spec.lua
describe("public API", function()
  it("registers a new source node and makes it visible to the scanner", function() ... end)
  it("unregisters a source node so it is no longer counted in scans", function() ... end)
  it("adds a manual zone visible to zone_manager.get_intensity()", function() ... end)
  it("removes a manual zone so it no longer contributes to intensity", function() ... end)
  it("returns the correct intensity at a position inside a manual zone", function() ... end)
  it("fires intensity_change callback when player crosses a tier boundary", function() ... end)
end)
```

### Integration Tests

```lua
-- spec/integration_spec.lua
describe("light pollution integration", function()
  it("player entering a simulated lava cluster sees increasing sky tint over time", function()
    -- Place lava nodes in world, run globalsteps, verify player:set_sky called
  end)
  it("player moving away from zone sees effects fade to zero", function()
    -- Move player beyond radius, run globalsteps, verify sky restored
  end)
  it("two players in different zones see independently computed effects", function()
    -- Two players, two zones, assert distinct set_sky calls
  end)
  it("removing all light nodes from a cluster dissolves the zone", function()
    -- Place nodes, scan, remove nodes, trigger dirty, scan again, assert intensity 0
  end)
  it("third-party mod registering a source via API causes it to contribute to zone score", function()
    -- Call light_pollution.register_source(), place node, scan, assert score > 0
  end)
end)
```

### Certification Gate

| Check | Type | Runnable |
|---|---|---|
| Lua syntax / busted pass | Unit | ✅ via Docker on Windows |
| All describe/it stubs pass | Unit | ✅ via Docker on Windows |
| Integration: lava cluster → sky tint | Integration | ✅ via Docker on Windows |
| In-game visual smoke test | Manual | Requires Luanti install |

---

## Decision Log

**Decision:** Hybrid scanning (event-driven dirty + player-centered timer)
**Alternatives considered:** Pure event-driven only; pure ABM scanning; per-player ABM
**Why chosen:** Pure event-driven misses chunk-load boundary cases where nodes are in already-generated terrain. Pure ABM scanning runs on every active node and is too expensive at scale. Hybrid gives correctness at chunk edges with bounded per-player cost.
**Impact:** Slightly more complex init wiring; scan_interval and scan_radius become key performance knobs.

---

**Decision:** Per-player sky/stars/HUD effects via `player:set_sky()` and `player:set_stars()`
**Alternatives considered:** Unified sky mod (e.g., skydome replacement); shader injection; global sky change
**Why chosen:** Per-player API is the only approach that allows different players in different zones to see different effects simultaneously without interfering with each other or breaking other sky-modifying mods that use `get_sky()` to restore state.
**Impact:** Must save/restore each player's prior sky state. Sky conflicts with other per-player sky mods remain possible if they also overwrite sky each tick.

---

**Decision:** No custom nodes or items in this mod
**Alternatives considered:** Craftable "light pollution meter" item; decorative smog node
**Why chosen:** Keeps mod lightweight and compatible with any game. Effects and mechanics are purely atmospheric/environmental. Items and nodes can be added in a future iteration.
**Impact:** No crafting integration; no inventory presence. Pure environmental mod.

---

**Decision:** VoxelManip for scanning instead of `minetest.find_nodes_in_area`
**Alternatives considered:** `minetest.find_nodes_in_area` (simpler API); iterating `get_node` per position
**Why chosen:** `minetest.find_nodes_in_area` must be given the complete list of node names to search for, which changes dynamically as mods register sources via the API. VoxelManip reads raw content IDs and checks against a pre-built content ID set, which stays current automatically and performs one bulk read vs. N individual calls.
**Impact:** Scanner must maintain a content ID lookup table rebuilt when source_registry changes.

---

## Spec Review Feedback

*Reviewed: 2026-05-15 — All 9 issues resolved and applied.*

### Structure

| Section | Present? | Clear & Specific? | Notes |
|---|---|---|---|
| Overview | ✅ | ✅ | 3 sentences, plain language |
| Objectives & Success Criteria | ✅ | ✅ | 10 `it` statements, observable in-game outcomes |
| Functional Requirements | ✅ | ✅ | `describe`/`it` blocks throughout; structural checklist separate |
| Modularity & Extensibility Strategy | ✅ | ✅ | Module table, composition flow, reuse decisions all present |
| Technical Architecture | ✅ | ✅ | APIs, data model, hybrid strategy, settings table all documented |
| Open Source/Free Resources | ✅ | ✅ | busted, mineunit, Docker warning, texture — all present |
| Implementation Approach | ✅ | ✅ | 12 ordered steps with API references |
| Testing & Validation | ✅ | ✅ | busted/mineunit, `spec/*_spec.lua`, unit + integration + certification gate |
| Decision Log | ✅ | ✅ | 4 decisions with alternatives and rationale |

### Issues Resolved

| # | Issue | Fix Applied |
|---|---|---|
| 1 | `move_threshold` undefined | Added to settings table (default: 8 nodes) |
| 2 | `suppress_threshold` undefined | Added to settings table (default: 0.3) |
| 3 | Tier thresholds and callback signature undefined | Added `tier_low/medium/high` settings; defined `callback(player_name, old_tier, new_tier)` in Step 10 |
| 4 | `max_score` undocumented magic constant | Named `LIGHT_SCORE_MAX = 500` and documented as a module constant in Step 6 |
| 5 | "blurs" not achievable via Luanti HUD API | Changed to "tints and dims" in success criterion |
| 6 | Daytime check used wrong API | Changed to `minetest.get_timeofday()` in effect engine requirement |
| 7 | `player:set_sky()` doc link too broad | Updated to direct Lua API reference URL |
| 8 | `register_on_mobs_spawn` is not a core API | API table updated with warning; noted silent skip when framework absent |
| 9 | ABM suppression is post-spawn, not pre-spawn | Step 9 rewritten to acknowledge limitation; clarified reactive removal vs. spawn prevention |

### Scope Assessment

- **Verdict**: Likely too large for a single iteration
- **Triggered heuristics**: Lua system breadth (6 systems), testing surface (31 scenarios), dependency depth (12 steps)

### Recommended Actions

- See iteration split recommendation below (iteration breakdown pending user decision)
