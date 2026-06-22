---
name: loops-save
description: >
  Capture a completed agent-loop / orchestration run to the loop store
  (~/.claude/loops/) so future planning can learn from it. Stamps outcome +
  Reflexion lessons onto the factual record the loop auto-wrote (or creates one
  from context), plus an agent-type registry note per subagent used. Use AFTER a
  run the user judges successful (or instructively failed). Triggers: /loops-save,
  "save this loop", "record this run", "remember this loop", "log this
  orchestration".
---

# loops-save

Capture step for the loop-memory subsystem. Persists a run to the **loop store**
(`~/.claude/loops/`) so `plan-with-loops` can recall it later (Reflexion
long-term memory). Companion to `plan-with-loops` (planner) and `loops-graduate`
(promote to a skill).

Most runs are **half-captured already**: a Workflow built by `plan-with-loops`
auto-writes a factual `loop-record-*.md` in its final `capture` phase (task,
roster, topology, results, cost) with `loop_outcome` + Lessons left as `TODO`.
This skill's main job is to **stamp the human judgment** — outcome + Reflexion
lessons — onto that record while the evaluation is fresh. If no auto-record
exists (e.g. the loop wasn't run via a generated Workflow), create one from
conversation context.

## Where it writes (plain markdown — `Write` tool)

Files land in `~/.claude/loops/` (create the dir if missing):

1. **One loop-record** — `loop-record-<slug>-<date>.md` (run + outcome + lessons).
2. **One agent-type note per subagent** — `agent-type-<name>.md` (the reusable-
   agent registry).

No external service required. **Optional vault mirror:** if the `save_to_vault`
MCP tool is present, also save copies there.

## Procedure

1. **Find the auto-record.** `Glob ~/.claude/loops/loop-record-*.md` for this run
   (newest, or matching the task slug). If found, the facts are already there —
   you only need to fill `loop_outcome` + the Lessons section. If absent, gather
   the run from conversation context (the `plan-with-loops` design doc and what
   actually happened): task, task-type tags, effort, roster, pattern/topology.
2. **Determine outcome.** If the user hasn't said, ask once: **worked /
   partial / failed**. Save failed runs too — negative lessons are valuable.
3. **Extract Reflexion lessons** (verbal feedback, not scores):
   - what worked · what failed / would change · what is reusable.
4. **Update the agent registry.** For each subagent used: `Read
   ~/.claude/loops/agent-type-<name>.md` if it exists; carry its prior `used_in`
   + `success_count` forward and increment; else start fresh. `Write` the note
   (same filename overwrites).
5. **Write the loop-record**, linking each agent with `[[agent-type-<name>]]`.
   Fill `loop_outcome` and the Lessons section; keep the auto-written facts intact.
6. **Report** filenames written + a one-line summary.

## Note schemas

### Loop record — `~/.claude/loops/loop-record-<task-slug>-<yyyy-mm-dd>.md`
```markdown
---
tags: [loop-record, plan-with-loops]
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

### Agent type — `~/.claude/loops/agent-type-<name>.md`
```markdown
---
tags: [agent-type, registry]
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
- This skill **writes markdown files** to `~/.claude/loops/` (not read-only,
  unlike `plan-with-loops`). Create the dir if it doesn't exist; never touch
  project code.
