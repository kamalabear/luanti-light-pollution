<#
.SYNOPSIS
Configure deployment environment for Luanti mods.

.DESCRIPTION
Guides the user through setting up the MINETEST_PATH environment variable
and validates the Minetest installation.

This script should be run once per machine before using the deploy skill.

.EXAMPLE
.\run-deployment-setup.ps1
#>

param()

Write-Host "=== Luanti Deploy Skill Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if MINETEST_PATH is already set
$existingPath = $env:MINETEST_PATH
if ($existingPath) {
    Write-Host "Current MINETEST_PATH: $existingPath"
    
    if (Test-Path $existingPath) {
        Write-Host "✓ Minetest installation found" -ForegroundColor Green
        $skipSetup = Read-Host "Path is already configured. Skip setup? (yes/no)"
        if ($skipSetup -match '^(yes|y)$') {
            Write-Host "Setup complete."
            exit 0
        }
    }
    else {
        Write-Host "✗ Minetest installation NOT found at this path" -ForegroundColor Red
        $useExisting = Read-Host "Update the path? (yes/no)"
        if ($useExisting -notmatch '^(yes|y)$') {
            exit 1
        }
    }
}

Write-Host ""
Write-Host "Please provide your Minetest installation path."
Write-Host "This is typically: C:\Users\<YourUsername>\AppData\Roaming\Minetest"
Write-Host ""

# Try to auto-detect
$autoDetectPath = "$env:APPDATA\Minetest"
if (Test-Path $autoDetectPath) {
    Write-Host "Auto-detected Minetest at: $autoDetectPath"
    $useAuto = Read-Host "Use this path? (yes/no)"
    if ($useAuto -match '^(yes|y)$') {
        $minestestPath = $autoDetectPath
    }
    else {
        $minestestPath = Read-Host "Enter Minetest path"
    }
}
else {
    Write-Host "Could not auto-detect Minetest installation."
    $minestestPath = Read-Host "Enter your Minetest installation path"
}

# Validate path
if (-not (Test-Path $minestestPath -PathType Container)) {
    Write-Host "✗ Path not found: $minestestPath" -ForegroundColor Red
    exit 1
}

# Check for mods directory
$modsPath = Join-Path $minestestPath "mods"
if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "✗ Minetest mods directory not found at: $modsPath" -ForegroundColor Red
    $createMods = Read-Host "Create mods directory? (yes/no)"
    if ($createMods -match '^(yes|y)$') {
        New-Item -ItemType Directory -Path $modsPath -Force | Out-Null
        Write-Host "✓ Created: $modsPath" -ForegroundColor Green
    }
    else {
        exit 1
    }
}
else {
    Write-Host "✓ Minetest installation validated" -ForegroundColor Green
}

# Set environment variable
Write-Host ""
Write-Host "Setting MINETEST_PATH environment variable..."

try {
    [System.Environment]::SetEnvironmentVariable("MINETEST_PATH", $minestestPath, "User")
    Write-Host "✓ Environment variable set for current user" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to set environment variable: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Fallback: Set manually in PowerShell profile or system environment variables."
    exit 1
}

# Verify
$env:MINETEST_PATH = $minestestPath
Write-Host "✓ Verified in current session: $env:MINETEST_PATH"

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "MINETEST_PATH is now set to: $minestestPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart any open terminals/PowerShell windows to pick up the new variable"
Write-Host "  2. You can now use the deploy skill:"
Write-Host "     Deploy the mod-name mod to Minetest"
Write-Host ""
