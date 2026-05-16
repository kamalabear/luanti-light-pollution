# Deploy Skill — Quick Start

## What This Skill Does

The **deploy** skill packages your Luanti mod and installs it to your local Minetest installation.

- Validates your mod and Minetest installation
- Optionally runs tests before deploying
- Copies the mod to your Minetest mods folder
- Backs up any existing version before overwriting

## Quick Setup (One-Time)

### Step 1: Set Environment Variable

Run this PowerShell command to configure your Minetest path:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\deploy\run-deployment-setup.ps1
```

This will:
- Auto-detect your Minetest installation (usually `C:\Users\[You]\AppData\Roaming\Minetest`)
- Set the `MINETEST_PATH` environment variable
- Validate the setup

**Important:** Restart your terminal after setup so it picks up the new environment variable.

### Step 2: Verify Setup

```powershell
$env:MINETEST_PATH
```

You should see your Minetest path. If blank, restart your terminal.

## Using the Deploy Skill

### Option 1: Deploy via Copilot Chat

When you're ready to deploy your mod, just ask:

```
Deploy the light_pollution mod to Minetest
```

or

```
Deploy [mod-name] to Minetest with tests
```

### Option 2: Manual Command-Line Deployment

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\deploy\deploy-mod.ps1 `
  -ModPath "C:\path\to\mod\light_pollution" `
  -RunTests $true
```

### Option 3: Integrated with Implement-Spec

When implementing a mod spec, after completion you'll be offered:
- "Would you like to deploy to Minetest for testing?"
- If yes, the deploy skill runs automatically

## What Gets Deployed

- The entire mod directory (everything in `light_pollution/` for example)
- All Lua files, textures, sounds, etc.
- Test files are included but won't affect runtime

## Testing Before Deploy

If you choose to run tests:
- The skill looks for test files in `spec/`
- Runs them using `busted` (requires `busted` installed)
- Reports pass/fail
- Prompts you to continue or cancel if tests fail

To install busted on Windows:
```powershell
luarocks install busted
```

## After Deployment

Once deployed:

1. **Enable the mod** in your world config
   - Open Minetest
   - Go to your world settings
   - Find "light_pollution" in the mod list
   - Enable it (check the box)

2. **Test in-game**
   - Load the world
   - Check for expected behavior
   - Monitor console for errors

3. **View the deployed mod**
   - Deployed location: `$MINETEST_PATH\mods\[mod-name]`
   - Example: `C:\Users\navia\AppData\Roaming\Minetest\mods\light_pollution`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "MINETEST_PATH not set" | Run setup again: `.github\skills\deploy\run-deployment-setup.ps1` |
| "Minetest not found" | Verify your Minetest installation is at the path shown |
| "Permission denied" | Ensure Minetest is not running; check folder permissions |
| Tests fail | Review the test output; fix your code and try again |
| Mod doesn't appear in Minetest | Check that mod was deployed to: `$MINETEST_PATH\mods\[mod-name]` |

## File Structure

```
.github/skills/deploy/
├── SKILL.md                       # Skill documentation
├── deploy-mod.ps1                 # Core deployment script
├── run-deployment-setup.ps1       # Environment setup script
└── README.md                       # This file
```

## For Multiple Machines

Since the deploy skill uses the `MINETEST_PATH` environment variable, you can:
1. Commit all skill files to git
2. On a new machine, just run the setup script
3. Set your machine-specific `MINETEST_PATH`
4. The skill works the same way

## Next Steps

1. ✓ Run setup: `.github\skills\deploy\run-deployment-setup.ps1`
2. ✓ Restart terminal
3. ✓ Deploy your first mod: ask Copilot or run the command
4. ✓ Test in Minetest

Questions? Refer to [SKILL.md](SKILL.md) for detailed workflow documentation.
