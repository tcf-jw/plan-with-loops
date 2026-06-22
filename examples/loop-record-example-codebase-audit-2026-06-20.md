---
tags: [loop-record, plan-with-loops]
loop_task_type: codebase-audit
loop_effort: high
loop_outcome: worked
loop_pattern: orchestrator-worker + adversarial-verify
loop_controller: code-controlled
agents_used:
  - "[[agent-type-scanner]]"
  - "[[agent-type-verifier]]"
date: 2026-06-20
---

# Loop Record: audit codebase for silent failures  (worked)

> Illustrative example of a captured run. Drop your own under `~/.claude/loops/`.
> The factual sections (Task, Roster, Loop topology) are auto-written by the
> loop's `capture` phase; Outcome + Lessons are stamped on later by `/loops-save`.

## Task
Find swallowed exceptions, empty catch blocks, and inappropriate fallbacks
across the service, then propose fixes.

## Roster
| agent | role | model | tools |
|-------|------|-------|-------|
| orchestrator | splits dirs, merges findings | opus | Read, Task |
| scanner | finds candidate sites per dir | sonnet | Read, Grep, Glob |
| verifier | adversarially refutes each finding | sonnet | Read |

## Loop topology
- Controller: code-controlled Workflow
- Pattern: orchestrator fans out scanners by directory → each finding verified by
  3 skeptic `verifier` agents (kill if ≥2 refute)
- Termination: all candidates verified | Circuit breaker: ≤ 12 scanners, 3 verify votes
- State externalized: candidate list + `seen` set in script scope

## Outcome
worked — 14 real silent failures confirmed (31 candidates, 17 refuted as
false positives). ~5 min wall-clock, ~4× a single serial agent in tokens.

## Lessons (Reflexion verbal feedback)
- Worked: adversarial verify killed most false positives; diverse dirs parallelised cleanly.
- Failed / would change: scanner over-flagged logging calls — tighten its prompt.
- Reusable: the scanner→3-skeptic-verify shape generalises to any "find issues" audit.
