# plan-with-loops — reference

Loop-design catalog. Drawn from the vault research run
`agent-frameworks-cc-2026-06-20` and `agent-frameworks-loop-design`. Read this
before Phase 3 (loop design).

## The canonical agent loop
Every framework reduces to: assemble context → call model → receive text/tool-use
→ run tools → append results → repeat until termination. The loop closes on
**context assembly**, not model invocation. Differences between frameworks = (a)
*who controls the loop*, (b) *what lives in state*, (c) *how sub-loops delegate*.

## Who controls the loop (central axis)
| Mode | Controller | Flexibility | Debuggability | Use when |
|------|-----------|-------------|---------------|----------|
| LLM-controlled | model picks next step | high | low | adaptive, open-ended tasks; subagent auto-dispatch |
| Code-controlled | script picks, model executes subtasks | low | high | **default for Claude Code Workflow** — deterministic fan-out/loops |
| Graph-controlled | state machine routes nodes | medium | high | inspectable branching (LangGraph-style); not native here |

For Claude Code native work, **code-controlled** (a Workflow script that *is* the
orchestrator) is the default. The script holds the loop, branching, and
intermediate results; each subagent's context only sees its own sub-task.

## Anthropic's 5 canonical patterns → Claude Code
| Pattern | What | Claude Code impl |
|---------|------|------------------|
| Prompt chaining | sequential steps + programmatic gates | `pipeline()` stages, or sequential `agent()` calls |
| Routing | classify input → dispatch specialist | description-matching subagent, or a router `agent()` returning a tag |
| Parallelization | fan out independent subtasks / voting | `parallel()` barrier, or `pipeline()` without a barrier |
| Orchestrator-workers | central LLM splits + delegates + synthesizes | the **backbone**: Workflow script delegates to `agent()` workers, then merges |
| Evaluator-optimizer | generator + critic in a loop | writer `agent()` paired with a reviewer `agent()`, looped until pass |

Foundational discipline: **"Start with simple prompts, optimize with evaluation,
add complexity only when simpler solutions fall short."**

## Single-agent loop patterns
- **ReAct** (Reason+Act): Thought → Action → Observation, linearized in the
  prompt. Weakness: **no native backtracking** — only reasons forward from errors.
- **Reflexion**: adds a meta-layer across attempts. Three roles — **Actor**
  (ReAct + memory), **Evaluator** (scores trajectory), **Self-Reflection**
  (turns score into verbal feedback stored in long-term memory). Dual memory:
  short-term (current trajectory) + long-term (verbal lessons). Maps to
  expensive-orchestrator (reflection) / cheap-executor (actor).

## Quality / verification loops (high effort)
- **Adversarial verify** — spawn N independent skeptic agents per finding, each
  prompted to *refute*. Kill if a majority refute. Defaults to refuted on doubt.
- **Diverse-lens verify** — N verifiers, each a distinct lens (correctness,
  security, performance, does-it-reproduce). Catches failure modes redundancy can't.
- **Judge panel** — generate N attempts from different angles, score in parallel,
  synthesize from the winner while grafting best ideas from runners-up.
- **Loop-until-dry** — keep spawning finders until K consecutive rounds return
  nothing new. Dedup against a `seen` set, not against confirmed results.
- **Completeness critic** — a final agent asking "what's missing?"; its output
  becomes the next round of work.

## Effort → loop complexity mapping
Scale orchestration to the request. Mirrors the "add complexity only when needed"
discipline.

| Effort | Plan depth | Agents | Loop | Verification |
|--------|-----------|--------|------|--------------|
| **low** | a few coarse steps | **single agent** (prefer; say so) | none / linear | none |
| **medium** | fine steps, key files | orchestrator + parallel workers | orchestrator-worker fan-out | one verify pass |
| **high** | full steps + trade-offs | orchestrator + diverse workers | full loop: evaluator-optimizer + adversarial/judge + loop-until-dry | N-skeptic / diverse-lens, externalized state |

## Claude Code Workflow primitives (the wiring target)
The Workflow tool runs a JS script that orchestrates subagents deterministically.

- `agent(prompt, opts?)` — spawn a subagent; returns its final text. With
  `{schema}` it must return a validated object (auto-retry on mismatch). Opts:
  `label`, `phase`, `model` (`opus`/`sonnet`/`haiku`), `effort`, `agentType`,
  `isolation: 'worktree'` (only when agents mutate files in parallel).
- `pipeline(items, stage1, stage2, ...)` — each item flows through all stages
  independently, **no barrier**. **Default choice** for multi-stage work.
- `parallel(thunks)` — **barrier**: awaits all; failed thunks resolve to `null`
  (`.filter(Boolean)`). Use only when a stage genuinely needs all prior results
  (dedup/merge, early-exit on zero, cross-item comparison).
- `phase(title)` / `log(msg)` — progress grouping + narrator lines.
- `budget` — `{total, spent(), remaining()}` for budget-scaled loops.

Concurrency cap ≈ `min(16, cores-2)` per workflow; lifetime cap 1000 agents.
Non-determinism (`Date.now()`/`Math.random()`) is disabled — stamp after the run.

## Subagent files (the other wiring target)
`.claude/agents/<name>.md` — YAML frontmatter (`name`, `description`, `tools`,
`model`) + body (~30 lines). Scope `tools` to the minimum. Put domain context in
CLAUDE.md (agents inherit it), not the agent body. Use `haiku` aggressively for
high-frequency mechanical agents; reserve `opus` for the orchestrator and hardest
reasoning.

## Termination & circuit breakers (mandatory)
Never ship an unbounded loop. Every loop design states a stop condition **and** a
cap:
- `max_turns` / round limit (Agent SDK defaults to **unlimited** — set it).
- `max_iter` / `max_execution_time` (CrewAI-style) for runaway ReAct.
- budget ceiling (`budget.remaining()`), or loop-until-dry's K-empty-rounds.
- Workflow `parallel`/`pipeline` accept ≤4096 items per call.

## Cost discipline
Multi-agent runs cost **several× a single serial agent** — each subagent re-pays
for its own context. Parallelism buys wall-clock, not tokens. Managed Agents
(cloud) caps: ≤20 agents, ≤25 concurrent threads, **one delegation level deep**.
Claude Code local subagents nest deeper but each level multiplies spend.

## State management between iterations
- **Externalize state** to a file or the Workflow script scope so the loop
  survives the context window (don't keep full history in context).
- Compaction summarizes old turns to free budget for fresh results.
- Long-term memory = Reflexion's verbal-feedback buffer (cross-session learning
  without retraining).
