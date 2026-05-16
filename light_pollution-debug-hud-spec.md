# light_pollution — Debug HUD Overlay Spec

> Part of: [light_pollution-overview-spec.md](light_pollution-overview-spec.md)
> Standalone diagnostic feature — not tied to a numbered iteration.

---

## 1. Overview

Add a per-player HUD text overlay that displays live light pollution diagnostic
information. The overlay is toggled on/off with the `/lp_debug` chat command and
is invisible by default. It is intended to help developers and power users verify
that the scanner, zone manager, and sky effect pipeline are all working correctly
at runtime without reloading the game or reading log files.

---

## 2. Objectives & Success Criteria

- it shows no overlay at all until a player runs `/lp_debug`
- it displays live, per-player diagnostic data updated every effect engine tick
- it shows the raw zone score, zone radius, raw intensity, visual intensity,
  current sky colours, star scale, active/inactive state, and time-of-day
- it correctly reports when effects are suppressed (daytime gate)
- it is toggled off again by a second `/lp_debug` invocation
- it is automatically removed when the player disconnects
- it does not affect any game state or sky effect behaviour
- it compiles and loads without error on Luanti 5.x

---

## 3. Functional Requirements

- it registers a `/lp_debug` chat command available to any connected player
- it adds a HUD text element for the invoking player when toggled on
- it removes the HUD text element for the invoking player when toggled off
- it updates HUD text every effect engine tick (same rate as sky effects)
- it exposes the following diagnostic values:

  | Field | Source | Notes |
  |-------|--------|-------|
  | `tod` | `minetest.get_timeofday()` | 3 decimal places |
  | `active` | `tod` outside 0.23–0.77 | YES / NO (daytime suppressed) |
  | `zone_score` | `debug_state.zone_score` set by zone_manager | 0 if no sources found |
  | `zone_radius` | `debug_state.zone_radius` | 0 if no zone |
  | `intensity_raw` | `state.current_intensity` | 3 decimal places |
  | `intensity_vis` | `sqrt(current_intensity)` | 3 decimal places |
  | `sky_applied` | `state.sky_applied` | true / false |
  | `horizon` | computed hex colour | shown when sky_applied = true |
  | `zenith` | computed hex colour | shown when sky_applied = true |
  | `star_scale` | computed star scale | shown when sky_applied = true |

- when `sky_applied` is false, the last three fields show `---` instead of values
- it does not log to the Minetest log file; all output is HUD only

---

## 4. Structural Requirements

- [ ] New file: `light_pollution/debug_hud.lua`
- [ ] `debug_hud` is a global table with two public functions:
      `debug_hud.toggle(player)` and `debug_hud.update(player, state, debug_state)`
- [ ] `debug_hud.lua` is loaded in `init.lua` after `sky_compat.lua`
      and before `effect_engine.lua`
- [ ] The `/lp_debug` command is registered inside `debug_hud.lua`
- [ ] `effect_engine.lua` is updated to call `debug_hud.update(...)` at the end
      of each tick, passing the per-player state table and a new `debug_state`
      table (see section 6)
- [ ] `zone_manager.lua` is updated to return a `debug_state` table alongside
      intensity from `zone_manager.get_intensity(pos)` — or the engine reads
      from a shared table written by the zone manager
- [ ] HUD element uses `type = "text"`, anchored top-left, position `{x=0.01, y=0.1}`,
      `alignment = {x=1, y=1}`, fixed-width font via leading spaces for alignment
- [ ] No persistent state is stored between sessions (player disconnect clears HUD)

---

## 5. Modularity & Extensibility Strategy

**Module boundary:** `debug_hud` is entirely self-contained. Effect engine and
zone manager expose diagnostic data via a `debug_state` table passed at call
time — neither module depends on `debug_hud` existing. If `debug_hud` is not
loaded, the only change needed is to remove the `debug_hud.update(...)` call
from `effect_engine.lua`.

**Public interface of `debug_hud`:**

```lua
-- Toggles the HUD overlay on/off for the given player.
debug_hud.toggle(player)

-- Updates HUD text for the given player if their overlay is active.
-- state:       the per-player table from player_state in effect_engine
-- debug_state: { zone_score, zone_radius, horizon_color, zenith_color, star_scale }
debug_hud.update(player, state, debug_state)
```

**`debug_state` table** (constructed in `effect_engine.update` each tick):

```lua
{
    zone_score    = number,   -- raw light score from zone_manager
    zone_radius   = number,   -- radius of nearest contributing zone
    horizon_color = string,   -- hex string e.g. "#562015", or nil if not applied
    zenith_color  = string,   -- hex string, or nil if not applied
    star_scale    = number,   -- 0.0–1.0, or nil if not applied
}
```

**How to populate `debug_state`:** zone_manager currently returns only a number
from `get_intensity`. Change the return signature to return two values:

```lua
return math.min(total, max_i), last_zone_debug
-- where last_zone_debug = { score = ..., radius = ... } from the most-recently
-- written zone_cache entry for this player's mapblock key.
```

`sky_compat.apply_tint` should also return the colours and star scale it
computed, so `effect_engine` can forward them to `debug_hud.update`.

---

## 6. Technical Architecture

### New file: `debug_hud.lua`

```
debug_hud.lua
├── local hud_ids = {}          -- map: player_name -> hud element id
├── local active = {}           -- map: player_name -> bool
├── debug_hud.toggle(player)    -- add or remove HUD element, flip active flag
├── debug_hud.update(player, state, debug_state)
│       if not active[name] then return end
│       build text string from all fields
│       player:hud_change(hud_ids[name], "text", built_string)
└── /lp_debug command           -- calls debug_hud.toggle(player)
```

### Changes to `zone_manager.lua`

`zone_manager.get_intensity(pos)` currently returns one number. Change to
return a second value: the zone debug table for the mapblock key:

```lua
local last_debug = { score = 0, radius = 0 }
-- ... existing logic ...
local entry = zone_cache[key]
if entry then
    last_debug = { score = entry.light_score, radius = entry.radius }
end
return math.min(total, max_i), last_debug
```

Update the single call site in `effect_engine.update`:

```lua
state.target_intensity, state.zone_debug = zone_manager.get_intensity(pos)
```

Add `zone_debug = { score = 0, radius = 0 }` to the initial player_state table.

### Changes to `sky_compat.apply_tint`

Add return values at the end of the modern path so effect_engine can read
what was actually applied:

```lua
return horizon_color, zenith_color, star_scale
```

In `effect_engine.apply_tint`, capture and store these on `state`:

```lua
local function apply_tint(player, saved_sky, intensity)
    local vis = math.sqrt(math.max(0, intensity))
    local h, z, ss = sky_compat.apply_tint(player, saved_sky, vis)
    state_ref.last_horizon = h
    state_ref.last_zenith  = z
    state_ref.last_star_scale = ss
end
```

Note: `apply_tint` is a local function; pass `state` in via upvalue or
restructure slightly so the returned values reach the state table.

### Changes to `effect_engine.update`

At the very end of each tick, after the apply/restore branch:

```lua
if debug_hud then
    debug_hud.update(player, state, {
        zone_score    = state.zone_debug and state.zone_debug.score  or 0,
        zone_radius   = state.zone_debug and state.zone_debug.radius or 0,
        horizon_color = state.last_horizon,
        zenith_color  = state.last_zenith,
        star_scale    = state.last_star_scale,
    })
end
```

The `if debug_hud then` guard means the feature degrades gracefully if the
module is not loaded.

### HUD text format

```
[light_pollution debug]
tod:        0.021   active: YES
raw:        0.041   vis: 0.202
sky_on:     true
score:      312     radius: 119
horizon:    #562015
zenith:     #0f0602
stars:      0.42
```

When inactive (daytime or no sources):
```
[light_pollution debug]
tod:        0.520   active: NO (day)
raw:        0.000   vis: 0.000
sky_on:     false
score:      0       radius: 0
horizon:    ---
zenith:     ---
stars:      ---
```

---

## 7. Open Source/Free Resources

No external dependencies. All required APIs (`hud_add`, `hud_change`,
`register_chatcommand`, `register_on_leaveplayer`) are part of the
Luanti/Minetest core mod API.

---

## 8. Implementation Approach

1. Update `zone_manager.get_intensity` to return a second debug value.
2. Update `effect_engine.update` to capture zone_debug on state.
3. Update `sky_compat.apply_tint` to return horizon, zenith, star_scale.
4. Update `effect_engine.apply_tint` to capture returned colours on state.
5. Create `debug_hud.lua` with toggle, update, and command registration.
6. Add `debug_hud.update(...)` call at the end of `effect_engine.update`.
7. Add `dofile(..."/debug_hud.lua")` to `init.lua`.
8. Deploy and test with `/lp_debug` at night near a lava pool.

---

## 9. Testing & Validation

### Manual test cases

- it shows no HUD when player first joins
- it shows HUD after `/lp_debug` with all fields populated
- it shows `active: NO (day)` during daytime (tod 0.23–0.77)
- it shows `active: YES` at night (tod < 0.23 or > 0.77)
- it shows non-zero `score` when standing within scan_radius of lava
- it shows `sky_on: true` when `current_intensity > 0.001` at night
- it shows correct hex colours that match what the eye sees
- it disappears after a second `/lp_debug`
- it is absent after player reconnects (no stale HUD element)
- no runtime error in any of the above cases

### Test environment

Manual testing only (no mineunit tests required for this feature).
Place 20+ lava source blocks in a flat area. Stand 0–160 nodes away at
different times of day and verify each field changes as expected.

---

## 10. Decision Log

Decision: Return debug values from zone_manager and sky_compat rather than
  using a shared global debug table.
Alternatives considered: global `lp_debug_state` table; event callbacks;
  separate debug scanner call.
Why chosen: Minimises coupling. Callers already have the data; returning it
  avoids a second data path and keeps debug_hud as a pure consumer.
Impact: Two function signatures change (zone_manager.get_intensity,
  sky_compat.apply_tint). The changes are backward-compatible — callers
  that ignore the extra return values are unaffected.

Decision: Guard `debug_hud.update` call with `if debug_hud then`.
Alternatives considered: Always require debug_hud; use a no-op stub.
Why chosen: Keeps debug_hud fully optional. The mod works identically whether
  debug_hud.lua is loaded or not.
Impact: Zero — no behaviour change when debug_hud is absent.
