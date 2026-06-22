---
name: plan-with-loops
description: >
  Plan a task like Plan mode, then design the agent loop that executes it.
  Produces a read-only 4-part design doc: (1) standard step plan, (2) agent
  roster, (3) loop topology, (4) implementation plan wired to the Claude Code
  Workflow tool + subagents. Loop complexity scales with effort level
  (low/medium/high). Decides the roster and loop autonomously, then presents
  for approval. Writes no files. Use when the user wants to plan multi-agent,
  looped, or orchestrated work, asks to "design an agent loop", "plan with
  loops", "orchestrate this", or invokes /plan-with-loops.
---

# plan-with-loops

Read-only planner. Like the default **Plan** skill, but the output also designs
*how a loop of agents will execute the plan* — agent roster, loop pattern,
termination, and concrete wiring to the Claude Code **Workflow** tool and
subagents.

## Hard rules

- **Read-only. Write nothing.** Use only `Read`, `Grep`, `Glob`, `WebFetch`,
  the `Explore` agent, and `query_vault` (recall only). Never
  `Edit`/`Write`/`Bash`-mutate. This is a planner; output is a design doc, not
  an implementation. (Capture/graduation is done by the `loops-save` /
  `loops-graduate` companion skills, not here.)
- **Autonomous, then approve.** Decide the agent roster and loop yourself from
  the effort level. Do **not** interview the user mid-run with a stream of
  questions. Present the finished design once, then ask for approval/edits.
- **Native binding.** Target the Claude Code Workflow tool (`agent()`,
  `parallel()`, `pipeline()`, `phase()`, `log()`) + `.claude/agents/*.md`
  subagents. Describe the loop in those terms, not LangGraph/CrewAI.
- **Always read `reference.md`** (same directory) before Phase 3 — it holds the
  loop-pattern catalog, Workflow primitive cheat-sheet, and effort mapping.

## Inputs

- **Effort**: parse `$ARGUMENTS` for `low` | `medium` | `high`. Default
  **medium** if absent. Effort scales loop complexity (see `reference.md`).
- **Task**: the rest of `$ARGUMENTS` and/or the current conversation context is
  the thing to plan. If the task is genuinely ambiguous (not just
  underspecified), ask one clarifying question before starting — otherwise
  proceed.

## Procedure

### Phase 1 — Standard plan (scaled by effort)
Explore the task and codebase read-only (use the `Explore` agent for broad
sweeps). Produce a step-by-step breakdown of the work, same as default Plan.
Depth scales with effort: `low` = a few coarse steps; `high` = fine-grained
steps with critical files and trade-offs called out.

### Phase 1.5 — Recall (read-only history)
Before designing, query the vault for prior experience (Reflexion long-term
memory): `query_vault(topic: "<task-type> loop record agent type", note_type:
"WikiPage")`. Pull any `loop-record-*` and `agent-type-*` notes for similar
tasks. Use them to **bias the design**:
- prefer agent types / patterns with a `worked` outcome and high `success_count`;
- avoid roster/pattern choices recorded as `partial`/`failed`;
- carry forward each record's reusable lessons.
Cite which records informed the design. If the vault is unavailable or empty,
note "no prior loops found" and proceed from first principles.

### Phase 2 — Agent decomposition (autonomous)
From the Phase 1 steps (and Phase 1.5 recall), decide the agent roster:
- Which subtasks become their own agent/role? (isolate expensive or noisy work)
- Which run in **parallel** (independent) vs **sequential/pipeline** (dependent)?
- **Model per role**: orchestrator → `opus`; bounded reasoning workers →
  `sonnet`; cheap mechanical steps → `haiku`. (Expensive/cheap split.)
- **Tools per role**: scope tightly to the minimum each needs.
- **Verification**: does any output need an adversarial/critic pass?

Produce a roster table: `agent | role | model | tools | parallel?`.

### Phase 3 — Loop design
Read `reference.md`, then choose:
- **Controller** — default **code-controlled** (a Workflow script *is* the
  orchestrator) for Claude Code native work. Note when LLM-controlled
  (subagent auto-dispatch) fits better.
- **Pattern(s)** by effort (see mapping in `reference.md`):
  orchestrator-worker, evaluator-optimizer, pipeline-vs-parallel, and at high
  effort the quality loops (adversarial-verify, judge-panel, loop-until-dry).
- **Termination + circuit breakers** — mandatory. State the stop condition and
  the cap (`max_turns`/round limit/budget). Never leave a loop unbounded.
- **State** — what gets externalized (to a file / Workflow script scope) vs
  held in context, so the loop survives the context window.

### Phase 4 — Implementation plan (output)
Emit the design doc in the template below. Then **stop and ask**:
"Approve, or want edits to the roster / loop / effort?" Since output is
design-doc-only, do not write any files. On approval, hand off — note that the
design can be run via the Workflow tool or fed to another session.

## Output template

```
# Loop Plan: <task>  (effort: <low|medium|high>)

## 1. Plan
<numbered step breakdown from Phase 1>

## 2. Agent roster
| Agent | Role | Model | Tools | Parallel? |
|-------|------|-------|-------|-----------|
...

## 3. Loop topology
- Controller: <code-controlled Workflow | LLM-controlled dispatch>
- Pattern(s): <orchestrator-worker | evaluator-optimizer | pipeline | ...>
- Flow: <orchestrator → fan-out workers → verify → synthesize, etc>
- Termination: <stop condition> | Circuit breaker: <cap>
- State: <what is externalized>
- Est. cost note: <multi-agent ≈ N× single-agent tokens>

## 4. Implementation (Claude Code native)
- Mechanism: Workflow script / subagents
- Sketch:
    phase('...')
    const x = await agent('...', {schema, model})
    const results = await pipeline(items, stageA, stageB)
    // or parallel([...]) when a barrier is genuinely needed
- Subagent files to create: .claude/agents/<name>.md (role, tools, model)
- Verification stage: <adversarial/critic agents, if any>
```

## Companion skills (loop-memory subsystem)
- After a run the user judges successful (or instructively failed):
  **`/loops-save`** captures it to the vault (loop record + agent-type registry
  + Reflexion lessons).
- To promote a proven loop into its own reusable skill: **`/loops-graduate`**.
- This skill (`plan-with-loops`) is the read side — it recalls those records in
  Phase 1.5 to improve each new plan.

## Cost discipline
Always surface the token cost: multi-agent runs cost several× a single serial
agent because each subagent re-pays for its own context. At `low` effort, prefer
a single agent and say so — "start simple, add complexity only when simpler
solutions fall short."
