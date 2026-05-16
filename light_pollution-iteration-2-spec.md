# light_pollution — Iteration 2 Spec
# Full Effects + Extensibility

> Part of: [light_pollution-overview-spec.md](light_pollution-overview-spec.md)
> Iteration 2 of 2 — depends on Iteration 1 being complete and all Iteration 1 gates passed

---

## Overview

Iteration 2 completes the mod by adding the remaining visual effects (star reduction, HUD tint overlay), the full public Lua API for extensibility, configurable mob spawning integration, and complete `settingtypes.txt` documentation. It builds directly on the working pipeline from Iteration 1 — no structural changes to existing modules, only additions.

By the end of this iteration the mod is feature-complete: players see stars fade and their view tint orange inside pollution zones; other mods can register custom sources and react to intensity changes; server admins can tune all 16 settings.

---

## Objectives & Success Criteria

**Purpose:** Deliver the full visual experience and extensibility surface on top of the proven Iteration 1 pipeline.

**Success Criteria:**

- it "reduces star count and night opacity proportionally to pollution intensity"
- it "restores full stars when intensity returns to 0.0"
- it "applies a fullscreen semi-transparent orange HUD overlay when intensity exceeds hud_threshold"
- it "scales HUD overlay opacity with current_intensity up to hud_max_opacity"
- it "removes the HUD overlay when intensity drops below hud_threshold"
- it "allows any mod to register a custom source node via light_pollution.register_source(name, weight)"
- it "allows any mod to unregister a source via light_pollution.unregister_source(name)"
- it "allows any mod to inject a manual pollution zone via light_pollution.add_zone(pos, radius, intensity)"
- it "allows any mod to remove a manual zone via light_pollution.remove_zone(zone_id)"
- it "allows any mod to query intensity at any position via light_pollution.get_intensity(pos)"
- it "fires registered callbacks with (player_name, old_tier, new_tier) when a player crosses a pollution tier boundary"
- it "suppresses (reactively removes) hostile mobs inside pollution zones when mob_spawning_mode is 'suppress'"
- it "attracts hostile mobs to pollution zones when mob_spawning_mode is 'attract'"
- it "silently skips mob spawning integration when neither mobs_redo nor mcl_mobs framework is detected"
- it "documents all 16 settings in settingtypes.txt"

---

## Functional Requirements

### describe "Effect engine (star reduction)"
- it "calls player:set_stars() with night_opacity = math.max(0, 1.0 - current_intensity * 1.5) each update cycle"
- it "calls player:set_stars() with count = math.floor(1000 * (1.0 - current_intensity)) each update cycle"
- it "saves the player's original stars definition on first update call via player:get_stars()"
- it "restores original stars definition when current_intensity returns to 0.0"
- it "restores original stars when the player leaves via on_leaveplayer"

### describe "Effect engine (HUD overlay)"
- it "adds a fullscreen HUD image element (type='image', text='light_pollution_overlay.png', scale={x=-1,y=-1}) when intensity first exceeds hud_threshold"
- it "updates hud_change() to set the overlay's opacity proportional to current_intensity up to hud_max_opacity"
- it "removes the HUD element via player:hud_remove() when intensity drops below hud_threshold"
- it "does not add duplicate HUD elements if the element already exists"
- it "removes the HUD element when the player leaves"

### describe "Public API"
- it "registers a node name as a pollution source with a custom weight via light_pollution.register_source(name, weight), adding it to source_registry and triggering scanner.rebuild_content_id_cache()"
- it "unregisters a source node via light_pollution.unregister_source(name), removing it from source_registry and triggering scanner.rebuild_content_id_cache()"
- it "adds a manual zone via light_pollution.add_zone(pos, radius, intensity), returning a unique zone_id; the zone is queryable by zone_manager.get_intensity()"
- it "removes a manual zone by zone_id via light_pollution.remove_zone(zone_id); the zone no longer contributes to intensity queries"
- it "returns current intensity at any position via light_pollution.get_intensity(pos), delegating to zone_manager.get_intensity(pos)"
- it "registers a callback via light_pollution.register_on_intensity_change(fn); fn receives (player_name, old_tier, new_tier) when a player's tier changes"
- it "fires all registered intensity_change callbacks from effect_engine.update() when current_intensity crosses a tier boundary"

### describe "Pollution tiers"
- it "assigns tier 'none' when current_intensity < tier_low"
- it "assigns tier 'low' when current_intensity >= tier_low and < tier_medium"
- it "assigns tier 'medium' when current_intensity >= tier_medium and < tier_high"
- it "assigns tier 'high' when current_intensity >= tier_high"
- it "only fires intensity_change callbacks when the tier actually changes (not on every lerp step)"

### describe "Mob spawning integration"
- it "registers an ABM targeting hostile mob nodes when mob_spawning_mode is 'suppress' and a supported mob framework is detected"
- it "removes a hostile mob entity via object:remove() when it is found inside a pollution zone with intensity > suppress_threshold"
- it "registers an ABM that spawns an additional hostile mob of the same type at a nearby position when mob_spawning_mode is 'attract' and intensity > suppress_threshold"
- it "uses compat layer to resolve hostile mob node names for both MTG (mobs_monster) and VoxeLibre (mcl_mobs)"
- it "logs a warning and skips ABM registration when mob_spawning_mode is not 'none' but no mob framework is detected"
- it "does not register any mob ABM when mob_spawning_mode is 'none'"

### describe "Configuration (Iteration 2 additions)"
- it "reads hud_threshold, hud_max_opacity, mob_spawning_mode, suppress_threshold, tier_low, tier_medium, tier_high from minetest.conf"
- it "falls back to documented defaults when Iteration 2 settings are absent"
- it "validates all Iteration 2 settings at startup with appropriate range checks"

---

## Structural Requirements

- [ ] `textures/light_pollution_overlay.png` created: 16×16 RGBA PNG, solid orange-amber (#c86400) at ~40% alpha
- [ ] `api.lua` fully implemented (all 6 public functions live-wired)
- [ ] `effect_engine.lua` updated to include star reduction and HUD overlay on top of Iteration 1 sky tint
- [ ] `settingtypes.txt` documents all 16 settings using Luanti's `settingtypes.txt` format
- [ ] `spec/api_spec.lua` created with unit tests for all 6 API functions
- [ ] `spec/integration_spec.lua` updated with Iteration 2 integration tests
- [ ] Mob ABM only registers when `mob_spawning_mode != "none"` AND a supported framework is detected
- [ ] All prior Iteration 1 tests continue to pass after Iteration 2 changes
- [ ] No global state mutations outside module init paths
- [ ] Mod does not crash when optional mob frameworks are absent

---

## Modularity & Extensibility Strategy

### Changes to Existing Modules (Iteration 2)

| Module | Change |
|---|---|
| `config.lua` | Add loading + validation for 7 new Iteration 2 settings |
| `compat.lua` | Add hostile mob node name lists for MTG and VoxeLibre; add mob framework detection |
| `api.lua` | Replace stub with full implementation of all 6 public functions |
| `effect_engine.lua` | Add star reduction and HUD overlay alongside existing sky tint; add tier tracking + callback firing |
| `init.lua` | Register mob ABM if configured; no structural changes |

### New Additions

| Addition | Notes |
|---|---|
| `textures/light_pollution_overlay.png` | 16×16 RGBA PNG; HUD uses `scale={x=-1,y=-1}` for fullscreen stretch |
| `spec/api_spec.lua` | Unit tests for all 6 public API functions |

### Public Interface (complete after Iteration 2)

```lua
-- Register a custom node as a pollution source
light_pollution.register_source(node_name, weight)

-- Unregister a node from pollution sources
light_pollution.unregister_source(node_name)

-- Inject a manual zone; returns zone_id (string)
light_pollution.add_zone(pos, radius, intensity) -> zone_id

-- Remove a manual zone by ID
light_pollution.remove_zone(zone_id)

-- Query pollution intensity at any world position
light_pollution.get_intensity(pos) -> number (0.0–1.0)

-- Subscribe to tier change events
-- callback: function(player_name, old_tier, new_tier)
-- tiers: "none", "low", "medium", "high"
light_pollution.register_on_intensity_change(callback)
```

---

## Technical Architecture

### Additional Luanti APIs Used (Iteration 2)

| Purpose | API |
|---|---|
| Star reduction | `player:set_stars({count, night_opacity, day_opacity})`; `player:get_stars()` for save |
| HUD overlay | `player:hud_add({type="image", text="light_pollution_overlay.png", scale={x=-1,y=-1}, position={x=0.5,y=0.5}, alignment={x=0,y=0}})` |
| HUD update (opacity) | `player:hud_change(hud_id, "text", ...)` — note: opacity is not a native HUD field; use an alpha-channel PNG texture swap or a set of pre-baked opacity textures: `light_pollution_overlay_10.png` … `light_pollution_overlay_100.png` at 10% steps, selected by `math.floor(opacity * 10) * 10` |
| HUD removal | `player:hud_remove(hud_id)` |
| Mob ABM | `minetest.register_abm({nodenames, neighbors, interval, chance, action})` |
| Entity removal | `object:remove()` inside ABM action |

### HUD Opacity Strategy

Luanti's `hud_add` image type does not support runtime alpha changes via `hud_change`. The recommended approach is to pre-bake a set of overlay textures at discrete opacity levels and swap the texture string:

- Generate 10 textures: `light_pollution_overlay_10.png` (10% alpha) through `light_pollution_overlay_100.png` (100% alpha), each 16×16 RGBA PNG with solid #c86400.
- In `effect_engine.update`, compute `local step = math.max(1, math.floor(current_intensity / hud_max_opacity * 10))` and call `player:hud_change(hud_id, "text", "light_pollution_overlay_" .. (step * 10) .. ".png")`.

### Additional Settings (Iteration 2)

| Key | Type | Default | Description |
|---|---|---|---|
| `light_pollution.hud_threshold` | float | 0.2 | Intensity at which HUD overlay begins appearing |
| `light_pollution.hud_max_opacity` | float | 0.5 | Maximum HUD overlay opacity (0.0–1.0) |
| `light_pollution.mob_spawning_mode` | string | "none" | Mob behavior: "none", "suppress", "attract" |
| `light_pollution.suppress_threshold` | float | 0.3 | Minimum intensity for mob suppression/attraction to activate |
| `light_pollution.tier_low` | float | 0.15 | Intensity threshold for "low" tier |
| `light_pollution.tier_medium` | float | 0.45 | Intensity threshold for "medium" tier |
| `light_pollution.tier_high` | float | 0.75 | Intensity threshold for "high" tier |

### Tier Computation

```lua
local function compute_tier(intensity)
  if intensity >= tier_high   then return "high"
  elseif intensity >= tier_medium then return "medium"
  elseif intensity >= tier_low    then return "low"
  else                             return "none"
  end
end
```

Tier is computed each update. If tier differs from `state.last_tier`, fire all `intensity_callbacks` and update `state.last_tier`.

---

## Open Source / Free Resources

| Resource | Source | Usage | Notes |
|---|---|---|---|
| busted | https://lunarmodules.github.io/busted/ | Test runner | Already installed in Iteration 1 |
| mineunit | https://github.com/S-S-X/mineunit | Luanti API mock | Already installed in Iteration 1 |
| mineunit Docker | https://hub.docker.com/r/mineunit/mineunit | Windows test execution | ⚠️ Required on Windows |
| HUD overlay textures | Hand-authored or CC0 | 10 opacity-step PNG files | Generate with any image editor or script; all 16×16 RGBA |

---

## Implementation Approach

### Step 1 — Extend `config.lua`
Add loading and validation for the 7 Iteration 2 settings. Validate: `hud_threshold` and `hud_max_opacity` in [0.0, 1.0]; `suppress_threshold` in [0.0, 1.0]; tier thresholds in ascending order (`tier_low < tier_medium < tier_high`). Log warning if tier values are out of order and apply defaults.

### Step 2 — Extend `compat.lua`
Add `compat.hostile_mob_nodes()` function:
- MTG (mobs_redo): return `{"mobs_monster:stone_monster", "mobs_monster:sand_monster"}` (and other mobs_redo hostile types).
- VoxeLibre (mcl_mobs): return `{"mcl_mobs:zombie", "mcl_mobs:skeleton", "mcl_mobs:creeper"}` (and other mcl hostile types).
- Detect mob framework: `minetest.get_modpath("mobs_monster")` for MTG, `minetest.get_modpath("mcl_mobs")` for VoxeLibre.
- Return `nil` with a warning log if no framework is detected.

### Step 3 — Create HUD overlay textures
Create 10 PNG files in `textures/`:
- `light_pollution_overlay_10.png` through `light_pollution_overlay_100.png`
- Each: 16×16 RGBA, solid #c86400 at alpha = 10% … 100% in 10% steps.
- Can be generated with ImageMagick: `magick -size 16x16 xc:"rgba(200,100,0,0.N)" light_pollution_overlay_NN.png`

### Step 4 — Extend `effect_engine.lua` — star reduction
In `effect_engine.update(player)`, after existing sky tint logic, add:
- On first call: `state.stars_saved = player:get_stars()`.
- Each update (when delta > 0.001):
  - `player:set_stars({night_opacity = math.max(0, 1.0 - current_intensity * 1.5), count = math.floor(1000 * (1.0 - current_intensity))})`.
- When `current_intensity < 0.001` and `state.stars_saved`: restore with `player:set_stars(state.stars_saved)`.
- In `on_leaveplayer`: restore stars alongside sky.

### Step 5 — Extend `effect_engine.lua` — HUD overlay
In `effect_engine.update(player)`, after star logic:
- If `current_intensity >= hud_threshold` and `state.hud_id == nil`:
  - `state.hud_id = player:hud_add({type="image", text="light_pollution_overlay_10.png", scale={x=-1,y=-1}, position={x=0.5,y=0.5}, alignment={x=0,y=0}})`.
- If `current_intensity >= hud_threshold` and `state.hud_id ~= nil`:
  - Compute step and call `player:hud_change(state.hud_id, "text", "light_pollution_overlay_" .. step .. ".png")`.
- If `current_intensity < hud_threshold` and `state.hud_id ~= nil`:
  - `player:hud_remove(state.hud_id); state.hud_id = nil`.
- In `on_leaveplayer`: if `state.hud_id`, call `player:hud_remove(state.hud_id)`.

### Step 6 — Extend `effect_engine.lua` — tier tracking and callbacks
Add to player_state: `last_tier = "none"`.
After lerp in each update:
```lua
local new_tier = compute_tier(current_intensity)
if new_tier ~= state.last_tier then
  for _, cb in ipairs(light_pollution._intensity_callbacks) do
    cb(player:get_player_name(), state.last_tier, new_tier)
  end
  state.last_tier = new_tier
end
```

### Step 7 — Implement full `api.lua`
Replace stub with full implementation:
```lua
light_pollution = {
  source_registry     = {},   -- populated by init.lua
  _manual_zones       = {},   -- zone_id -> {pos, radius, intensity}
  _intensity_callbacks = {},
  _next_zone_id       = 1,
}

function light_pollution.register_source(name, weight)
  light_pollution.source_registry[name] = { weight = weight }
  scanner.rebuild_content_id_cache()
end

function light_pollution.unregister_source(name)
  light_pollution.source_registry[name] = nil
  scanner.rebuild_content_id_cache()
end

function light_pollution.add_zone(pos, radius, intensity)
  local id = "manual_" .. light_pollution._next_zone_id
  light_pollution._next_zone_id = light_pollution._next_zone_id + 1
  light_pollution._manual_zones[id] = {pos=pos, radius=radius, intensity=intensity}
  return id
end

function light_pollution.remove_zone(zone_id)
  light_pollution._manual_zones[zone_id] = nil
end

function light_pollution.get_intensity(pos)
  return zone_manager.get_intensity(pos)
end

function light_pollution.register_on_intensity_change(fn)
  table.insert(light_pollution._intensity_callbacks, fn)
end
```

Update `zone_manager.get_intensity(pos)` to also check `light_pollution._manual_zones` and merge manual zone intensity with node-derived intensity (same linear falloff: `intensity * (1 - dist/radius)`).

### Step 8 — Implement mob spawning ABM in `init.lua`
After existing globalstep registration:
```lua
if config.get("mob_spawning_mode") ~= "none" then
  local mob_nodes = compat.hostile_mob_nodes()
  if mob_nodes then
    local mode = config.get("mob_spawning_mode")
    local threshold = config.get("suppress_threshold")
    minetest.register_abm({
      label = "light_pollution mob spawning",
      nodenames = mob_nodes,
      interval = 5,
      chance = 1,
      action = function(pos, node, active_object_count, active_object_count_wider)
        local intensity = zone_manager.get_intensity(pos)
        if intensity <= threshold then return end
        if mode == "suppress" then
          for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
            if obj:get_luaentity() then obj:remove() end
          end
        elseif mode == "attract" then
          -- spawn additional entity of same type at nearby position
          local spawn_pos = vector.add(pos, {x=math.random(-3,3), y=0, z=math.random(-3,3)})
          minetest.add_entity(spawn_pos, node.name)
        end
      end,
    })
  else
    minetest.log("warning", "[light_pollution] mob_spawning_mode is '" ..
      config.get("mob_spawning_mode") .. "' but no supported mob framework detected. Skipping.")
  end
end
```

### Step 9 — Write complete `settingtypes.txt`
Document all 16 settings in Luanti's format:
```
light_pollution.scan_radius (int) 64
    Node radius to scan around players for light sources.
    Min: 16, Max: 256

light_pollution.scan_interval (float) 5.0
    Seconds between full rescans per player.
    ...
```
Reference: [settingtypes.txt format](https://docs.luanti.org/for-creators/settings/)

---

## Testing & Validation

**Stack**: busted + mineunit
**Windows**: `docker run --rm -v %cd%:/mod mineunit/mineunit`

### Unit Tests (Iteration 2 additions)

```lua
-- spec/effect_engine_spec.lua (additions)
describe("effect engine (stars)", function()
  it("calls player:set_stars() with reduced count and opacity proportional to intensity", function() ... end)
  it("restores original stars when intensity returns to 0.0", function() ... end)
  it("restores original stars when player leaves", function() ... end)
end)

describe("effect engine (HUD overlay)", function()
  it("adds HUD image element when intensity exceeds hud_threshold", function() ... end)
  it("updates HUD texture to higher-opacity variant as intensity increases", function() ... end)
  it("removes HUD element when intensity drops below hud_threshold", function() ... end)
  it("does not add duplicate HUD elements on repeated calls", function() ... end)
  it("removes HUD element when player leaves", function() ... end)
end)

describe("effect engine (tier callbacks)", function()
  it("fires registered callback with old and new tier when intensity crosses tier_low", function() ... end)
  it("fires registered callback when intensity crosses tier_medium", function() ... end)
  it("fires registered callback when intensity crosses tier_high", function() ... end)
  it("does not fire callback when tier has not changed between updates", function() ... end)
end)

-- spec/api_spec.lua
describe("public API", function()
  it("register_source adds node to source_registry and triggers cache rebuild", function() ... end)
  it("unregister_source removes node from source_registry and triggers cache rebuild", function() ... end)
  it("add_zone returns a unique zone_id and zone is queryable via get_intensity()", function() ... end)
  it("remove_zone removes the zone so it no longer contributes to intensity", function() ... end)
  it("get_intensity delegates to zone_manager.get_intensity()", function() ... end)
  it("register_on_intensity_change fires callback with correct tier values on tier change", function() ... end)
  it("manual zone intensity falls off linearly with distance from zone center", function() ... end)
end)
```

### Integration Tests (Iteration 2 additions)

```lua
-- spec/integration_spec.lua (additions)
describe("light pollution integration (Iteration 2)", function()
  it("player near lava cluster sees stars fade in addition to sky tint after globalsteps", function()
    -- Verify both set_sky and set_stars called with reduced values
  end)
  it("player near lava cluster sees HUD overlay appear when intensity exceeds hud_threshold", function()
    -- Verify hud_add called with overlay texture
  end)
  it("third-party mod registering a source via API causes it to count toward zone intensity", function()
    -- Call light_pollution.register_source(), place node, run globalstep, assert intensity > 0
  end)
  it("manual zone injected via add_zone contributes intensity at its position", function()
    -- Call add_zone, query get_intensity inside radius, assert > 0
  end)
  it("intensity_change callback fires when player moves from none tier to low tier", function()
    -- Place enough lights to cross tier_low, run globalsteps, assert callback fired
  end)
end)
```

### Iteration 2 Completion Checkpoint

| Check | Type | Status |
|---|---|---|
| All Iteration 1 tests still pass | Unit (Docker) | Required |
| All Iteration 2 unit tests pass | Unit (Docker) | Required |
| Integration: stars fade near cluster | Integration (Docker) | Required |
| Integration: HUD overlay appears | Integration (Docker) | Required |
| Integration: register_source API works | Integration (Docker) | Required |
| Integration: tier callback fires | Integration (Docker) | Required |
| In-game: stars fade + HUD overlay visible near lava | Manual | Required |
| In-game: register_source from test mod works | Manual | Required |
| In-game: mob suppression removes mobs (if mobs_redo present) | Manual | Conditional |
| settingtypes.txt: all 16 settings appear in Luanti Settings UI | Manual | Required |

---

## Decision Log

**Decision:** Pre-baked opacity textures for HUD overlay (10 PNG files)
**Alternatives considered:** Single texture with runtime alpha change via `hud_change`; shader-based approach
**Why chosen:** `hud_change` does not support alpha modification on image HUD elements in Luanti's API. Runtime alpha requires swapping the texture filename. 10 discrete steps (10%–100%) produce visually smooth transitions at low implementation cost.
**Impact:** 10 small texture files added to the mod. No additional API calls needed beyond `hud_change(..., "text", filename)`.

---

**Decision:** Mob spawning uses reactive ABM (post-spawn entity removal) not pre-spawn hook
**Alternatives considered:** `register_on_mobs_spawn` (mobs_redo-specific); modifying spawn table `chance`
**Why chosen:** No universal pre-spawn hook exists across both MTG (`mobs_redo`) and VoxeLibre (`mcl_mobs`). ABM-based reactive removal works on both frameworks via the standard engine `minetest.register_abm` API, requires no direct mob framework dependency, and fails gracefully when no framework is present.
**Impact:** Mobs may briefly appear before being removed in suppress mode. Document this as a known limitation. Suppress mode is opt-in and off by default.
