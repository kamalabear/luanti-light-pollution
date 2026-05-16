$ErrorActionPreference = "Stop"

$scriptsRoot = $PSScriptRoot

Write-Host "[open-guard] Running workflow pack sync"
try {
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptsRoot "sync-workflow-pack.ps1")
} catch {
  Write-Warning "Sync failed: $($_.Exception.Message)"
}

Write-Host "[open-guard] Checking retro status"
try {
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptsRoot "check-session-retro.ps1")
} catch {
  Write-Warning "Retro check failed: $($_.Exception.Message)"
}

Write-Host "[open-guard] Capturing rolling session note"
try {
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptsRoot "start-session-note.ps1")
} catch {
  Write-Warning "Rolling notes capture failed: $($_.Exception.Message)"
}
