---
name: loops-graduate
description: >
  Promote a proven agent-loop from the loop store (~/.claude/loops/) into a
  reusable global skill. Reads the relevant loop-record note(s), verifies the
  loop has actually succeeded, then scaffolds a new ~/.claude/skills/<name>/
  SKILL.md that encodes the proven loop as a concrete Claude Code Workflow
  procedure. Triggers: /loops-graduate, "promote this loop to a skill",
  "graduate this loop", "make a skill from this loop", "turn this loop into a
  skill".
---

# loops-graduate

Graduation step for the loop-memory subsystem. Turns a loop that has proven
itself (captured by `loops-save`) into a first-class reusable skill. The user is
the gatekeeper — promotion is always manual, one record at a time.

## Procedure

1. **Find the record(s).** From `$ARGUMENTS` (a task-type, loop name, or record
   slug), search the loop store: `Glob ~/.claude/loops/loop-record-*.md` then
   `Grep`/`Read` for matches. Pull the matching `loop-record-*.md` and the linked
   `agent-type-*.md` notes. (Optional: also `query_vault` if that backend is used.)
2. **Verify it's proven.** Require `loop_outcome: worked` (ignore records still
   marked `TODO` — those haven't been judged via `/loops-save` yet). Prefer
   **repeated** success — multiple worked records of the same `loop_task_type`,
   or agent `success_count > 1`. If only a single success exists, **warn** and
   ask the user to confirm before graduating a one-off.
3. **Confirm naming + scope.** Propose a kebab-case skill name; default scope is
   global (`~/.claude/skills/<name>/`). Confirm with the user.
4. **Scaffold the skill.** Write `~/.claude/skills/<name>/SKILL.md` encoding the
   proven loop (see template). Pull roster, pattern, termination, and lessons
   straight from the record — bake the lessons in as guidance.
5. **Optionally scaffold agents.** Offer to write `.claude/agents/<name>.md` for
   each reused agent type (role, tools, model from its registry note). Skip if
   the user prefers the loop to spawn them inline via the Workflow tool.
6. **Report** the files created and how to invoke the new skill.

## Generated SKILL.md template
```markdown
---
name: <skill-name>
description: >
  <what the proven loop does, when to use, trigger phrases>. Graduated from
  loop-record <record-slug> (<N> successful runs).
---

# <skill-name>

<one-line purpose — the proven loop>

## Procedure (proven loop)
1. <phase 1 from the record's topology>
2. ...

## Workflow sketch
    phase('...')
    const x = await agent('...', {schema, model: '<from roster>'})
    const results = await pipeline(items, stageA, stageB)
    // parallel([...]) only where a barrier is genuinely needed

## Roster
| agent | role | model | tools |  (from the record)

## Termination & circuit breaker
<stop condition + cap from the record>

## Baked-in lessons
- <reusable lessons carried from the loop record>
```

## Rules
- **This skill writes a new skill file** — the one intended write in the loop
  system. Confirm the target path before writing; never overwrite an existing
  skill without asking.
- Don't graduate `partial`/`failed` records. If the user insists on an unproven
  loop, say it's unproven and proceed only on explicit confirmation.
- Carry the record's lessons into the generated skill so the proven knowledge
  isn't lost.
