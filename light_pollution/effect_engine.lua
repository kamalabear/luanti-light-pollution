-- effect_engine.lua
-- Manages per-player sky tint effects based on light pollution intensity.
-- Public interface: effect_engine.update(player)

local player_state = {}

local function apply_tint(player, saved_sky, intensity, state_ref)
    -- visual intensity uses a sqrt curve so effect is perceptible at modest raw intensity
    local vis = math.sqrt(math.max(0, intensity))
    local h, z, ss = sky_compat.apply_tint(player, saved_sky, vis)
    if state_ref then
        state_ref.last_horizon = h
        state_ref.last_zenith = z
        state_ref.last_star_scale = ss
    end
end
effect_engine = {}

function effect_engine.update(player)
    local name = player:get_player_name()
    local pos  = player:get_pos()

    -- Initialise per-player state on first call.
    if not player_state[name] then
        player_state[name] = {
            current_intensity = 0,
            target_intensity  = 0,
            sky_saved         = sky_compat.capture(player),
            last_pos          = nil,
            sky_applied       = false,
            zone_debug        = { score = 0, radius = 0 },
            last_horizon      = nil,
            last_zenith       = nil,
            last_star_scale   = nil,
        }
    end

    local state        = player_state[name]
    local lerp_rate    = config.get("lerp_rate")
    local move_thresh  = config.get("move_threshold")
    local scan_radius  = config.get("scan_radius")

    state.debug_instant = debug_hud and debug_hud.instant_enabled(name) or false

    -- Decide whether to rescan.
    local needs_scan
    if state.last_pos == nil then
        needs_scan = true
    else
        local moved    = math.sqrt(
            (pos.x - state.last_pos.x)^2 +
            (pos.y - state.last_pos.y)^2 +
            (pos.z - state.last_pos.z)^2)
        local is_dirty = scanner.has_dirty_near(pos, scan_radius)
        needs_scan     = (moved >= move_thresh or is_dirty)
    end

    if needs_scan then
        -- When the player moves, mark the current position dirty so zone_manager
        -- bypasses its TTL cache and performs a fresh VoxelManip scan.
        -- Without this, zone_manager may return a stale zero-intensity result
        -- for the player's mapblock even though they've walked into lava territory.
        if state.last_pos then
            scanner.mark_dirty(pos)
        end
        state.target_intensity, state.zone_debug = zone_manager.get_intensity(pos)
        state.last_pos         = {x = pos.x, y = pos.y, z = pos.z}
    end

    -- Suppress pollution effect during daytime (0.23–0.77).
    local tod = minetest.get_timeofday()
    if tod > 0.23 and tod < 0.77 then
        state.target_intensity = 0
    end

    -- Lerp current_intensity toward target_intensity.
    local prev = state.current_intensity
    if state.debug_instant then
        state.current_intensity = state.target_intensity
    else
        state.current_intensity = prev + (state.target_intensity - prev) * lerp_rate
    end

    -- Apply or restore sky when the intensity changes meaningfully.
    if state.current_intensity < 0.001 then
        if state.sky_applied then
            sky_compat.restore(player, state.sky_saved)
            state.sky_applied = false
        end
    elseif math.abs(state.current_intensity - prev) > 0.001 or not state.sky_applied then
        apply_tint(player, state.sky_saved, state.current_intensity, state)
        state.sky_applied = true
    end

    -- Optional debug HUD update (debug_hud is loaded optionally).
    if debug_hud then
        debug_hud.update(player, state, {
            zone_score    = state.zone_debug and state.zone_debug.score  or 0,
            zone_radius   = state.zone_debug and state.zone_debug.radius or 0,
            horizon_color = state.last_horizon,
            zenith_color  = state.last_zenith,
            star_scale    = state.last_star_scale,
        })
    end
end

minetest.register_on_leaveplayer(function(player)
    local name  = player:get_player_name()
    local state = player_state[name]
    if state and state.sky_saved then
        sky_compat.restore(player, state.sky_saved)
    end
    player_state[name] = nil
end)
