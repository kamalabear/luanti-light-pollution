# Changelog

This file tracks logical, user-relevant changes over time.

## 2026-05-15 20:28 - Enable changelog discipline

- Why: Establish a concise record of logical updates
- Impact: Future logical changes now have a single human-readable summary stream
- Follow-up: Use this helper before each logical commit

## 2026-05-16 17:31 - Improve debug HUD readability and instant apply

- Why: Nighttime debugging was hard to read, and verifying sky application required waiting through intensity lerping
- Impact: The HUD now renders in white, shows whether instant mode is active, and `/lp_debug_instant` can force current intensity to snap to the target value for debugging
- Follow-up: Use the instant mode result to isolate whether lava detection or sky application is the remaining issue
