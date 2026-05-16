$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$reportsDir = Join-Path $workspaceRoot ".github\session-reports"
$notesFile = Join-Path $reportsDir "session-rolling-notes.md"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$branch = "n/a"
$statusShort = "n/a"

if (Get-Command git -ErrorAction SilentlyContinue) {
  $insideWorkTree = git -C $workspaceRoot rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -eq 0 -and $insideWorkTree.Trim() -eq "true") {
    $branch = git -C $workspaceRoot branch --show-current
    $statusShort = git -C $workspaceRoot status --short
    if ([string]::IsNullOrWhiteSpace($statusShort)) {
      $statusShort = "clean"
    }
  }
}

$entry = @"

## Session Start $timestamp

- Branch: $branch
- Working tree: $statusShort
- Notes:

"@

Add-Content -Path $notesFile -Value $entry
Write-Host "[notes] Session start entry appended to session-rolling-notes.md"
