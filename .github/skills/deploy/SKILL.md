# Deploy Skill for Luanti Mods

## Skill Overview

The **deploy** skill packages a Luanti mod and deploys it to a local Minetest installation, with optional test validation.

This skill:
- Validates the target mod exists
- Optionally runs the mod's test suite before deployment
- Copies the mod directory to the Minetest mods folder
- Reports deployment success or failure

## When to Use This Skill

Use deploy when you want to:
- Package a mod for local testing
- Update a mod in your local Minetest installation
- Validate a mod is deployable before committing changes
- Test a mod in the Minetest game engine after implementation

## Triggering the Skill

Invoke the skill from the implement-spec workflow completion, or manually invoke it by:

```powershell
runSubagent -prompt "Deploy the [mod-name] mod to my local Minetest installation" -agentName "Deploy"
```

Or ask directly:
- "Deploy the light_pollution mod to Minetest"
- "Package and deploy the [mod-name] mod"
- "Deploy this mod to my local Minetest"

## Skill Workflow

### 1. Capture Target Mod
Ask the user which mod to deploy (or infer from context if only one mod is being worked on).

### 2. Pre-Deployment Checks
- Verify mod directory exists in workspace
- Verify `MINETEST_PATH` environment variable is set
- Verify target Minetest installation is accessible

### 3. Optional Test Validation
If the mod has tests:
- Offer to run the test suite before deploying
- If user agrees, execute tests via the test execution convention
- If tests fail, report failures and prompt user to fix or continue anyway
- If tests pass, proceed to deployment

### 4. Deploy the Mod
- Copy the mod directory to `$MINETEST_PATH/mods/[mod-name]`
- Handle overwrites (backup existing if needed)
- Report deployment success with path confirmation

### 5. Post-Deployment Guidance
- Suggest next steps (enable mod in world config, launch game, etc.)
- Provide path to the deployed mod for manual verification

## Output Format

Report deployment outcomes with:

```
DEPLOYMENT REPORT
=================
Mod Name:        [mod-name]
Source:          [workspace path]
Destination:     [MINETEST_PATH/mods/mod-name]
Status:          SUCCESS | PARTIAL | FAIL
Test Suite Run:  YES | NO | SKIPPED
Test Outcome:    PASS | FAIL | N/A
Deployment Time: [duration]
Next Steps:      [recommended actions]
```

## Configuration

### Environment Setup (First Time Only)

Before using the deploy skill, set up the `MINETEST_PATH` environment variable:

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("MINETEST_PATH", "C:\Users\navia\AppData\Roaming\Minetest", "User")
# Restart terminal or PowerShell to pick up the new variable
```

**Windows (Command Prompt):**
```cmd
setx MINETEST_PATH "C:\Users\navia\AppData\Roaming\Minetest"
REM Restart terminal to pick up the new variable
```

Verify the variable is set:
```powershell
$env:MINETEST_PATH
```

## Blockers & Troubleshooting

| Blocker | Solution |
|---------|----------|
| `MINETEST_PATH` not set | Run environment setup command above and restart terminal |
| Minetest installation not found | Verify path is correct: `Test-Path $env:MINETEST_PATH` |
| Permission denied copying mod | Ensure Minetest is not running; check folder permissions |
| Tests fail before deployment | Review test failures; fix code or skip tests and deploy anyway |
| Mod already exists in Minetest | Script backs up existing; deployment overwrites after backup |

## Helper Scripts

The deploy skill uses:
- `deploy-mod.ps1` — Core deployment logic and mod copying
- `run-deployment-setup.ps1` — Initial environment variable configuration

Run setup once per machine:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .github/skills/deploy/run-deployment-setup.ps1
```

## Integration with Implement-Spec

When used as part of implement-spec workflow:
1. After code implementation completes
2. Before final implementation report
3. Optionally prompt: "Would you like to deploy to Minetest for UAT?"
4. If yes, run deploy workflow
5. Include deployment status in final implementation report

## Testing the Skill

To verify deploy skill is working:

```powershell
# Deploy with test validation
$ModPath = "c:\Users\navia\workspace\luanti-light-pollution\light_pollution"
$MinetestPath = $env:MINETEST_PATH
& .github\skills\deploy\deploy-mod.ps1 -ModPath $ModPath -MinetestPath $MinetestPath -RunTests $true
```

## Skill Boundaries

This skill does NOT:
- Modify mod code or configuration before deployment
- Package mods for distribution (no zipping/archiving)
- Handle version management or rollbacks
- Deploy to remote servers or production environments
- Automatically launch Minetest after deployment

## Next Steps

1. Run environment setup (one-time):
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .github/skills/deploy/run-deployment-setup.ps1
   ```

2. Test the skill:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .github/skills/deploy/deploy-mod.ps1 `
     -ModPath "c:\Users\navia\workspace\luanti-light-pollution\light_pollution" `
     -MinetestPath $env:MINETEST_PATH `
     -RunTests $true
   ```

3. For interactive deployment, run via agent:
   ```powershell
   # When you want to deploy, ask:
   # "Deploy the light_pollution mod to Minetest"
   ```
