---
tags: [agent-type, registry]
agent_role: finds candidate issue sites within a scoped directory
agent_model: sonnet
agent_tools: [Read, Grep, Glob]
success_count: 1
used_in:
  - "[[loop-record-example-codebase-audit-2026-06-20]]"
---

# Agent Type: scanner

Role: scan one directory for candidate sites matching the audit's pattern and
return them structured (file:line + why), no fixes.

When it worked well: parallel fan-out over independent directories; "find issues"
audits where each hit is later verified by a separate agent.

When it struggled: over-flagged benign matches (e.g. logging calls) when the
prompt was loose — pair it with an adversarial verifier and tighten the brief.

Model / tools rationale: `sonnet` is enough for bounded pattern-spotting; scoped
to read-only `Read`/`Grep`/`Glob` so it can't mutate anything.
