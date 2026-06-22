---
name: loops-save
description: >
  Capture a completed agent-loop / orchestration run into the InfiniteVoid
  vault so future planning can learn from it. Writes a loop-record note (task,
  roster, topology, outcome, Reflexion lessons) plus an agent-type registry note
  per subagent used. Use AFTER a run the user judges successful (or instructively
  failed). Triggers: /loops-save, "save this loop", "record this run",
  "remember this loop", "log this orchestration".
---

# loops-save

Manual capture step for the loop-memory subsystem. Persists a run to the vault
so `plan-with-loops` can recall it later (Reflexion long-term memory). Companion
to `plan-with-loops` (planner) and `loops-graduate` (promote to a skill).

## What it writes (vault, via `save_to_vault`)

`save_to_vault(filename, content)` saves a markdown note to the vault inbox for
ingestion (eventually queryable — not instant). Each save produces:

1. **One loop-record note** — the run + its outcome + lessons.
2. **One agent-type note per subagent used** — the reusable-agent registry.

## Procedure

1. **Gather the run** from conversation context (the `plan-with-loops` design
   doc and what actually happened) or from the user. Capture: task, task-type
   tags, effort, the agent roster, the loop pattern/topology.
2. **Determine outcome.** If the user hasn't said, ask once: **worked /
   partial / failed**. Save failed runs too — negative lessons are valuable.
3. **Extract Reflexion lessons** (verbal feedback, not scores):
   - what worked · what failed / would change · what is reusable.
4. **Update the agent registry.** For each subagent used: `query_vault(topic:
   "agent type <name>", note_type: "WikiPage")`. If a note exists, carry its
   prior `used_in` + `success_count` forward and increment; else start fresh.
   Save the agent-type note (same filename → ingestion merges).
5. **Save the loop-record note**, linking each agent with `[[agent-type-<name>]]`.
6. **Report** filenames written + a one-line summary.

## Note schemas

### Loop record — filename `loop-record-<task-slug>-<yyyy-mm-dd>`
```markdown
---
type: WikiPage
domain: AI
tags: [ai, loop-record, plan-with-loops]
loop_task_type: <e.g. codebase-audit | research-synthesis | migration>
loop_effort: <low|medium|high>
loop_outcome: <worked|partial|failed>
loop_pattern: <orchestrator-worker | evaluator-optimizer | pipeline | judge-panel | loop-until-dry>
loop_controller: <code-controlled | llm-controlled>
agents_used:
  - "[[agent-type-<name>]]"
date: <yyyy-mm-dd>
---

# Loop Record: <task>  (<outcome>)

## Task
<what the loop was asked to do>

## Roster
| agent | role | model | tools |
|-------|------|-------|-------|

## Loop topology
- Controller / pattern / flow
- Termination + circuit breaker
- State externalized: <...>

## Outcome
<worked|partial|failed> — <what shipped, wall-clock, rough token cost>

## Lessons (Reflexion verbal feedback)
- Worked: <...>
- Failed / would change: <...>
- Reusable: <...>
```

### Agent type — filename `agent-type-<name>`
```markdown
---
type: WikiPage
domain: AI
tags: [ai, agent-type, registry]
agent_role: <one line>
agent_model: <opus|sonnet|haiku>
agent_tools: [Read, Grep, ...]
success_count: <N>
used_in:
  - "[[loop-record-...]]"
---

# Agent Type: <name>

Role: <...>
When it worked well: <task types / conditions>
When it struggled: <failure modes>
Model / tools rationale: <why this model + this tool scope>
```

## Rules
- Always pass the date explicitly (today's date from context) — never invent one.
- Don't fabricate outcomes or lessons; if the run's result is unknown, ask.
- This skill **writes to the vault** (not to code) — it is not read-only, unlike
  `plan-with-loops`.
