$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$reportsDir = Join-Path $workspaceRoot ".github\session-reports"
$pendingFlag = Join-Path $reportsDir "retro-pending.flag"
$today = Get-Date -Format "yyyy-MM-dd"
$todayReport = Join-Path $reportsDir "session-retro-$today.md"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$hasTodayReport = Test-Path $todayReport
$hasRecentCommit = $false
$hasDirty = $false

if (Get-Command git -ErrorAction SilentlyContinue) {
  $insideWorkTree = git -C $workspaceRoot rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -eq 0 -and $insideWorkTree.Trim() -eq "true") {
    $recentCommit = git -C $workspaceRoot log --since="24 hours ago" --oneline -1
    if (-not [string]::IsNullOrWhiteSpace($recentCommit)) {
      $hasRecentCommit = $true
    }

    $dirty = git -C $workspaceRoot status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($dirty)) {
      $hasDirty = $true
    }
  }
}

if (-not $hasTodayReport -and ($hasRecentCommit -or $hasDirty)) {
  $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Set-Content -Path $pendingFlag -Value "pending_since=$stamp"
  Write-Warning "Session retro is missing for today. Consider running a catch-up retro before new work."
  Write-Host "Suggested prompt: session closeout"
  exit 0
}

if ($hasTodayReport -and (Test-Path $pendingFlag)) {
  Remove-Item -Path $pendingFlag -Force
}

Write-Host "[retro-check] Session retro state is up to date."
