<#
.SYNOPSIS
Deploy a Luanti mod to a local Minetest installation.

.DESCRIPTION
Copies a mod directory from the workspace to the Minetest mods folder.
Optionally runs tests before deployment.
Handles mod overwrites with optional backup.

.PARAMETER ModPath
The absolute path to the mod directory to deploy.
Example: C:\Users\navia\workspace\luanti-light-pollution\light_pollution

.PARAMETER MinetestPath
The absolute path to the Minetest installation root.
Example: C:\Users\navia\AppData\Roaming\Minetest
If not provided, reads from MINETEST_PATH environment variable.

.PARAMETER RunTests
If $true, runs the mod's test suite before deployment.
If tests fail, user is prompted to continue or abort.
Default: $false

.PARAMETER BackupExisting
If $true, backs up any existing mod with the same name before overwriting.
Default: $true

.EXAMPLE
.\deploy-mod.ps1 -ModPath "C:\ws\light_pollution\light_pollution" -MinetestPath "C:\Users\navia\AppData\Roaming\Minetest" -RunTests $true

.EXAMPLE
# Use MINETEST_PATH environment variable
.\deploy-mod.ps1 -ModPath "C:\ws\light_pollution\light_pollution" -RunTests $true
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ModPath,

    [Parameter(Mandatory = $false)]
    [string]$MinetestPath,

    [Parameter(Mandatory = $false)]
    [bool]$RunTests = $false,

    [Parameter(Mandatory = $false)]
    [bool]$BackupExisting = $true
)

$ErrorActionPreference = "Stop"

# Resolve Minetest path
if ([string]::IsNullOrWhiteSpace($MinetestPath)) {
    $MinetestPath = $env:MINETEST_PATH
    if ([string]::IsNullOrWhiteSpace($MinetestPath)) {
        Write-Error "MinetestPath not provided and MINETEST_PATH environment variable is not set. Run deployment setup first."
    }
}

# Validate paths
if (-not (Test-Path $MinetestPath -PathType Container)) {
    Write-Error "Minetest installation not found at: $MinetestPath"
}

$modsPath = Join-Path $MinetestPath "mods"
if (-not (Test-Path $modsPath)) {
    Write-Error "Minetest mods folder not found at: $modsPath"
}

# Extract mod name from directory
$modName = Split-Path -Leaf $ModPath
$targetModPath = Join-Path $modsPath $modName

# Start deployment report
$reportLines = @(
    "DEPLOYMENT REPORT",
    "=================="
    "Mod Name:        $modName",
    "Source:          $ModPath",
    "Destination:     $targetModPath",
    ""
)

$startTime = Get-Date

Write-Host $reportLines -join "`n"
Write-Host ""

# Check for existing mod
$existingModFound = Test-Path $targetModPath
if ($existingModFound -and $BackupExisting) {
    $backupPath = "$targetModPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Backing up existing mod to: $backupPath"
    Copy-Item -Path $targetModPath -Destination $backupPath -Recurse -Force
    Write-Host "v Backup created"
    Write-Host ""
}

# Run tests if requested
$testOutcome = "N/A"
$testsRun = "NO"

if ($RunTests) {
    $testsRun = "YES"
    Write-Host "Running test suite for $modName..."
    
    # Look for test script or busted configuration
    $specPath = Join-Path $ModPath "spec"
    $modfolder = Split-Path $ModPath -Parent
    
    if (Test-Path $specPath) {
        Write-Host "Found test directory at: $specPath"
        
        # Try to run busted tests
        try {
            # Check if busted is available
            $bustedCmd = Get-Command busted -ErrorAction SilentlyContinue
            if ($bustedCmd) {
                Write-Host "Running: busted $specPath"
                & busted $specPath
                
                if ($LASTEXITCODE -eq 0) {
                    $testOutcome = "PASS"
                    Write-Host "v Tests passed"
                }
                else {
                    $testOutcome = "FAIL"
                    Write-Host "x Tests failed (exit code: $LASTEXITCODE)"
                    Write-Host ""
                    Write-Host "Test failures detected. You can:"
                    Write-Host "  1. Fix the code and try deploy again"
                    Write-Host "  2. Continue deployment anyway (may have runtime issues)"
                    Write-Host ""
                    $continue = Read-Host "Continue with deployment anyway? (yes/no)"
                    if ($continue -notmatch '^(yes|y)$') {
                        Write-Error "Deployment aborted due to test failures"
                    }
                }
            }
            else {
                Write-Warning "busted not found in PATH. Skipping tests."
                Write-Host "To run tests, install busted: https://github.com/lunarmodules/busted"
                $testOutcome = "SKIPPED"
            }
        }
        catch {
            Write-Warning "Error running tests: $_"
            Write-Host "Continuing with deployment..."
            $testOutcome = "ERROR"
        }
    }
    else {
        Write-Warning "No spec directory found. Skipping tests."
        $testOutcome = "SKIPPED"
    }
    
    Write-Host ""
}

# Deploy the mod
Write-Host "Deploying $modName to Minetest..."

if ($existingModFound) {
    Remove-Item -Path $targetModPath -Recurse -Force
    Write-Host "Removed existing mod"
}

Copy-Item -Path $ModPath -Destination $targetModPath -Recurse -Force

if (Test-Path $targetModPath) {
    Write-Host "v Deployment successful"
    $status = "SUCCESS"
}
else {
    Write-Error "Deployment failed: mod not found at destination"
    $status = "FAIL"
}

# Calculate duration
$endTime = Get-Date
$duration = $endTime - $startTime

# Final report
Write-Host ""
Write-Host "Status:          $status"
Write-Host "Test Suite Run:  $testsRun"
Write-Host "Test Outcome:    $testOutcome"
Write-Host "Deployment Time: $($duration.TotalSeconds)s"
Write-Host ""

if ($status -eq "SUCCESS") {
    Write-Host "Next Steps:"
    Write-Host "  1. Enable the '$modName' mod in your world configuration"
    Write-Host "  2. Launch Minetest and load your world"
    Write-Host "  3. The mod should be active in the game"
    Write-Host ""
    Write-Host "Deployed mod path: $targetModPath"
}

exit 0
