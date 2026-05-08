# Agent Skills Testing

This repository exists to try out agent-agnostic [agent skills](https://agentskills.io/skill-creation/quickstart) and how to make them work for Claude Code.

## What it does

- Define `.agents` folder with `AGENTS.md` file and `skills` folder
- Define symlink `.claude` --> `.agents`
- Define symlink `CLAUDE.md` --> `AGENTS.md`

## Try it

1. Launch your agent
2. Call `/skills` and check if the `roll-dice` skill is available
3. Prompt "Roll a d6"
4. When asked, give permission

Your result should be something like this:

```
🎲 Rolled a 3 on a d6
```

At some point, your agent should also write

```
I HAVE READ AGENTS.md !!!
```

The more accurate way to verify what't been read in Claude Code would be a [hook](https://code.claude.com/docs/en/hooks).
