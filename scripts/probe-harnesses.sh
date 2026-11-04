#!/usr/bin/env bash
# Shows which instruction files and skill directories each installed agent
# harness loads. Every candidate file carries a unique canary token; each
# harness is asked, without using tools, which tokens and skills it was given.
#
# Usage: scripts/probe-harnesses.sh [claude|codex|cursor-agent ...]

set -euo pipefail

harnesses=("$@")
[ ${#harnesses[@]} -eq 0 ] && harnesses=(claude codex cursor-agent)

# A CLAUDE.md in any parent directory would stop Claude Code from reading
# AGENTS.md, so the fixture lives in a fresh temporary directory.
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

canary() { mkdir -p "$(dirname "$fixture/$1")"; printf '# Instructions\n\nCanary token: %s\n' "$2" > "$fixture/$1"; }
canary AGENTS.md              CANARY-ROOT-AGENTS
canary AGENTS.override.md     CANARY-ROOT-OVERRIDE
canary .agents/AGENTS.md      CANARY-DOTAGENTS-AGENTS
canary sub/AGENTS.md          CANARY-SUB-AGENTS
canary sub/AGENTS.override.md CANARY-SUB-OVERRIDE

for dir in .agents/skills .claude/skills; do
  name="canary-$(echo "$dir" | tr -dc 'a-z')"
  mkdir -p "$fixture/$dir/$name"
  cat > "$fixture/$dir/$name/SKILL.md" <<EOF
---
name: $name
description: Canary skill for testing skill discovery from $dir.
---
Reply with CANARY-SKILL-BODY.
EOF
done

git -C "$fixture" init -q
git -C "$fixture" add -A
git -C "$fixture" -c user.name=probe -c user.email=probe@example.com commit -qm fixture

prompt='Do not use any tools and do not read any files. Look only at the instructions and context you were given at startup. List every token of the form CANARY-... that appears in them, one per line. Then list the names of all skills available to you whose name starts with "canary", one per line. If there are none of either, say NONE.'

run() {
  case "$1" in
    claude)       claude -p "$prompt" ;;
    codex)        codex exec --skip-git-repo-check -s read-only "$prompt" ;;
    cursor-agent) cursor-agent -p --output-format text "$prompt" ;;
  esac
}

for h in "${harnesses[@]}"; do
  if ! command -v "$h" >/dev/null; then
    echo "== $h: not installed"; continue
  fi
  for cwd in . sub; do
    echo "== $h ($("$h" --version 2>/dev/null | head -1)), started in $cwd"
    (cd "$fixture/$cwd" && run "$h" 2>&1) | grep -Eio 'canary-[a-z]+(-[a-z]+)*' | grep -v -x -i 'canary-skill-body' | sort -uf || echo "(no canaries)"
  done
done
