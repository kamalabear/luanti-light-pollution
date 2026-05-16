$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$workspaceGithub = Join-Path $workspaceRoot ".github"
$workspaceParent = Split-Path -Parent $workspaceRoot
$packRepo = Join-Path $workspaceParent "luanti-modding-workspace"
$packGithub = Join-Path $packRepo ".github"

$syncFolders = @("instructions", "skills", "prompts")

function Test-RobocopyExitCode {
  param([int]$ExitCode)
  if ($ExitCode -gt 7) {
    throw "robocopy failed with exit code $ExitCode"
  }
}

if (-not (Test-Path $packRepo)) {
  Write-Warning "Workflow pack repo not found at: $packRepo"
  exit 0
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Warning "git is not available in PATH. Skipping workflow pack sync."
  exit 0
}

Write-Host "[sync] Pulling latest workflow pack from $packRepo"
git -C $packRepo pull --ff-only

if (-not (Test-Path $packGithub)) {
  Write-Warning "Workflow pack .github folder not found at: $packGithub"
  exit 0
}

foreach ($folder in $syncFolders) {
  $src = Join-Path $packGithub $folder
  $dst = Join-Path $workspaceGithub $folder

  if (-not (Test-Path $src)) {
    Write-Host "[sync] Skipping missing source folder: $src"
    continue
  }

  New-Item -ItemType Directory -Path $dst -Force | Out-Null

  Write-Host "[sync] Mirroring $folder"
  robocopy $src $dst /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  Test-RobocopyExitCode -ExitCode $LASTEXITCODE
}

Write-Host "[sync] Workflow pack sync complete."
