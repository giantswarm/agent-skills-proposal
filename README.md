# Agent Skills Testing

This repository tries out agent-agnostic instructions and
[agent skills](https://agentskills.io/skill-creation/quickstart) that work in
Claude Code, Codex and Cursor without per-agent copies.

## Layout

```
AGENTS.md                          # instructions for all agents
.agents/skills/<name>/SKILL.md     # skills for all agents
.claude/skills -> ../.agents/skills
```

- `AGENTS.md` lives in the repository root, because that's where all three
  agents look for it. Subdirectories can have their own `AGENTS.md`.
- Skills live in `.agents/skills/`, which Codex and Cursor read.
- Claude Code only reads skills from `.claude/skills/`, so that directory is a
  symlink to `.agents/skills/`. Only the `skills` directory is linked, so
  `.claude/` can still hold Claude-specific files such as `settings.json`.
- There is no `CLAUDE.md`. Claude Code reads `AGENTS.md` directly since
  v2.1.277, but by default only when there is no `CLAUDE.md`,
  `.claude/CLAUDE.md` or `CLAUDE.local.md` in the working directory or above
  it. Adding one of these makes Claude ignore `AGENTS.md`. See
  [Claude Code: AGENTS.md](https://code.claude.com/docs/en/memory#agents-md).

If you need a `CLAUDE.md`, for example for Claude-only instructions, start it
with an `@AGENTS.md` import line. Claude then reads both, and never reads
`AGENTS.md` twice.

## Harness support

What each agent loads from a repository, based on the docs linked below and on
tests with `scripts/probe-harnesses.sh` (Claude Code 2.1.318, Codex CLI
0.166.0, 2026-11-04). Cursor was checked against its docs only.

| | Claude Code | Codex | Cursor |
| :- | :- | :- | :- |
| `AGENTS.md` in the root | ✅ since v2.1.277, unless a `CLAUDE.md` exists | ✅ | ✅ |
| `AGENTS.md` in subdirectories | ✅ | ✅ | ✅ |
| `.agents/AGENTS.md` | ❌ | ❌ | ❌ not documented as a location |
| `AGENTS.override.md` | ❌ | ✅ replaces `AGENTS.md` | ❌ not documented |
| `.agents/skills/` | ❌ | ✅ | ✅ |
| `.claude/skills/` | ✅ | ❌ | ✅ |

Docs:
[Claude Code instructions](https://code.claude.com/docs/en/memory#agents-md),
[Claude Code skills](https://code.claude.com/docs/en/skills),
[Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
[Codex skills](https://developers.openai.com/codex/skills),
[Cursor rules](https://cursor.com/docs/context/rules),
[Cursor skills](https://cursor.com/docs/context/skills).

### `AGENTS.override.md`

`AGENTS.override.md` is a Codex feature. In each directory, Codex reads
`AGENTS.override.md` if it exists and otherwise `AGENTS.md`, so the override
**replaces** that directory's `AGENTS.md` rather than adding to it. Claude Code
documents that it doesn't read the file, and the tests confirm it. Cursor's
docs don't mention it.

So the override can't be used to add repository-specific instructions on top
of a generated, shared `AGENTS.md`: Claude Code and Cursor wouldn't see the
additions, and Codex would no longer see the shared part.

## Try it

1. Launch your agent in this repository.
2. Check that the `roll-dice` skill is available, for example with `/skills`.
3. Prompt "Roll a d6" and give permission when asked.

The result should look like this:

```
🎲 Rolled a 3 on a d6
```

At some point the agent should also write

```
I HAVE READ AGENTS.md !!!
```

In Claude Code, `/memory` lists the instruction files it has loaded.

To check which files and skill directories the installed agents load, run
`scripts/probe-harnesses.sh`. It needs the agents' CLIs (`claude`, `codex`,
`cursor-agent`), signed in.
