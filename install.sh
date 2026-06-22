#!/usr/bin/env bash
# Install the plan-with-loops skills into ~/.claude/skills/
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/skills" && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$DEST"
for skill in plan-with-loops loops-save loops-graduate; do
  echo "Installing $skill -> $DEST/$skill"
  rm -rf "${DEST:?}/$skill"
  cp -r "$SRC/$skill" "$DEST/$skill"
done

echo
echo "Done. Restart Claude Code (or start a new session) to pick up the skills:"
echo "  /plan-with-loops   /loops-save   /loops-graduate"
