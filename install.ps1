# Install the plan-with-loops skills into ~/.claude/skills/
$ErrorActionPreference = 'Stop'

$src  = Join-Path $PSScriptRoot 'skills'
$dest = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $HOME '.claude\skills' }

New-Item -ItemType Directory -Force -Path $dest | Out-Null
foreach ($skill in 'plan-with-loops', 'loops-save', 'loops-graduate') {
    Write-Host "Installing $skill -> $dest\$skill"
    $target = Join-Path $dest $skill
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse (Join-Path $src $skill) $target
}

Write-Host ""
Write-Host "Done. Restart Claude Code (or start a new session) to pick up the skills:"
Write-Host "  /plan-with-loops   /loops-save   /loops-graduate"
