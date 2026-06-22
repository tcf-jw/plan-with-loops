# Contributing

Thanks for taking a look — contributions are genuinely welcome, from typo fixes to whole new loop patterns.

## Ways to help

- **Open an issue** to report a bug, float an idea, or just say "this part confused me." Friction reports are useful signal.
- **Send a PR** for docs, examples, new loop patterns, or the pluggable-memory-backend work.
- **Share a loop record** — a `loop-record-*` note (or a sanitized description of a run) that worked, or instructively failed. Negative lessons are valuable.

## How these skills are structured

Each skill is a folder under `skills/` containing a `SKILL.md` with YAML frontmatter:

```yaml
---
name: <kebab-case-name>      # must match the folder name
description: >               # this is what Claude uses to decide when to trigger
  What it does, when to use it, and the trigger phrases.
---
```

`plan-with-loops` also ships a `reference.md` (the loop-pattern catalog) loaded on demand.

### Guidelines

- **Keep the trigger description sharp.** The `description` field is how Claude decides to invoke the skill — be concrete about *when* it applies and include trigger phrases.
- **`plan-with-loops` stays read-only.** It is a planner; it must never `Edit`/`Write`/mutate. Capture and graduation are the other two skills' jobs.
- **Every loop must terminate.** New patterns in `reference.md` must state a stop condition *and* a circuit breaker (round cap / budget / loop-until-dry). No unbounded swarms.
- **Respect cost discipline.** Default to the simplest thing that works; add agents only when a simpler loop falls short.
- **Test a skill before submitting** by copying it into `~/.claude/skills/` and exercising the trigger in a real Claude Code session.

## Local setup

```bash
git clone https://github.com/tcf-jw/plan-with-loops.git
cd plan-with-loops
./install.sh        # or ./install.ps1 on Windows — sym..copies skills into ~/.claude/skills/
```

Restart Claude Code (or start a new session) so the skills are re-discovered.

## PR checklist

- [ ] `name:` in frontmatter matches the folder name
- [ ] `description:` clearly states when the skill triggers
- [ ] Any new loop pattern names its termination condition + circuit breaker
- [ ] You exercised the skill in a real session
- [ ] Docs updated if behavior changed

By contributing you agree your work is licensed under the repository's [MIT License](LICENSE).
