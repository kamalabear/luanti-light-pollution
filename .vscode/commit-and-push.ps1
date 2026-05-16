param(
  [Parameter(Mandatory = $true)]
  [string]$Message,

  [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is not available in PATH"
}

$insideWorkTree = git -C $workspaceRoot rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $insideWorkTree.Trim() -ne "true") {
  throw "Target workspace is not a git repository: $workspaceRoot"
}

$changes = git -C $workspaceRoot status --porcelain
if ([string]::IsNullOrWhiteSpace($changes)) {
  Write-Host "No changes to commit."
  exit 0
}

git -C $workspaceRoot add .
git -C $workspaceRoot commit -m $Message
git -C $workspaceRoot push origin $Branch

Write-Host "Committed and pushed changes on branch $Branch"
