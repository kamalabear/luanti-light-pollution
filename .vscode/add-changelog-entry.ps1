param(
  [Parameter(Mandatory = $true)]
  [string]$Title,

  [Parameter(Mandatory = $true)]
  [string]$Why,

  [Parameter(Mandatory = $true)]
  [string]$Impact,

  [string]$FollowUp = "none"
)

$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$changelogPath = Join-Path $workspaceRoot "CHANGELOG.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

if (-not (Test-Path $changelogPath)) {
  $header = @"
# Changelog

This file tracks logical, user-relevant changes over time.
"@
  Set-Content -Path $changelogPath -Value $header
}

$entry = @"

## $timestamp - $Title

- Why: $Why
- Impact: $Impact
- Follow-up: $FollowUp
"@

Add-Content -Path $changelogPath -Value $entry
Write-Host "Appended changelog entry to $changelogPath"
