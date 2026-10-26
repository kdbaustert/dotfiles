#!/usr/bin/env bash
#
# Checks the memory bank wiring (see Memory in .claude/CLAUDE.md and its
# reasons in .claude/REFERENCE.md). Not an installer step; it deploys and
# writes nothing outside a temp directory it removes.
#
# WHY. The six file names live in four places: the global instructions, the
# global git ignore, the sync agent and this script. A name changed in one and
# not the others fails quietly: the agent skips a file, or a note ends up
# staged in a work repo. The ignore is the other risk. Widening it to a
# CLAUDE-*.md glob would hide tracked files such as cnc-claims'
# CLAUDE-REFERENCE.md, so that file is checked to stay visible.
#
# Usage:
#   setup/check-memory-bank.sh          name and ignore checks; free, under a second
#   setup/check-memory-bank.sh --eval   also asks Claude Code (haiku, paid) and,
#                                       when installed, Codex for a project's
#                                       current goal, which only the memory bank holds
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
instructions="$root/.claude/CLAUDE.md"
ignore="$root/.config/git/ignore"
agent="$root/.claude/agents/memory-bank-synchronizer.md"
cmdfile="$root/.claude/commands/update-memory-bank.md"
names=(
  CLAUDE-activeContext.md
  CLAUDE-patterns.md
  CLAUDE-decisions.md
  CLAUDE-troubleshooting.md
  CLAUDE-config-variables.md
  CLAUDE-temp.md
)
failures=0

pass() { echo "ok:   $1"; }
fail() { echo "FAIL: $1" >&2; failures=$((failures + 1)); }
skip() { echo "skip: $1"; }

# Without rg, every name check below would report the name missing from every
# file, which reads like broken wiring rather than a missing tool.
if ! command -v rg >/dev/null 2>&1; then
  echo "FAIL: rg not found; it's in homebrew/Brewfile" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for f in "$instructions" "$ignore" "$agent" "$cmdfile"; do
  if [ -f "$f" ]; then
    pass "${f#"$root"/} exists"
  else
    fail "${f#"$root"/} is missing"
  fi
done

for name in "${names[@]}"; do
  missing=()
  rg -q --fixed-strings "\`$name\`" "$instructions" 2>/dev/null || missing+=(".claude/CLAUDE.md")
  rg -q --fixed-strings "\`$name\`" "$agent" 2>/dev/null || missing+=("the agent")
  rg -q --fixed-strings --line-regexp "$name" "$ignore" 2>/dev/null || missing+=(".config/git/ignore")
  if [ "${#missing[@]}" -eq 0 ]; then
    pass "$name is named everywhere"
  else
    fail "$name is missing from: ${missing[*]}"
  fi
done

for ref in /update-memory-bank memory-bank-synchronizer; do
  if rg -q --fixed-strings "$ref" "$instructions" 2>/dev/null; then
    pass ".claude/CLAUDE.md points at $ref"
  else
    fail ".claude/CLAUDE.md never mentions $ref, so nothing tells an agent it exists"
  fi
done

# -c core.excludesFile tests the file in this checkout rather than whatever the
# machine has deployed, and a throwaway repo keeps this repo's own .gitignore
# out of the answer. check-ignore doesn't need the paths to exist. It exits 0
# for ignored, 1 for not ignored and 128 when git itself fails, so anything
# but 0 or 1 is a failure in both directions; otherwise a broken git would
# pass every "still sees" check.
git -C "$tmp" init -q
check() {
  git -C "$tmp" -c core.excludesFile="$ignore" check-ignore -q "$1"
}
for name in "${names[@]}" "sub/dir/CLAUDE-activeContext.md"; do
  check "$name"
  case $? in
    0) pass "git ignores $name" ;;
    1) fail "git does not ignore $name" ;;
    *) fail "git check-ignore errored on $name" ;;
  esac
done
for name in CLAUDE.md AGENTS.md CLAUDE-REFERENCE.md CLAUDE.local.md; do
  check "$name"
  case $? in
    0) fail "git ignores $name, which projects track; the memory bank ignore is too wide" ;;
    1) pass "git still sees $name" ;;
    *) fail "git check-ignore errored on $name" ;;
  esac
done

if [ "${1:-}" = "--eval" ]; then
  # A goal no model could guess, in the one file the global instructions say
  # to read at the start of a task. Only the Read tool is offered, so the model
  # can't list the directory: it finds the file by name from the instructions
  # or not at all. It runs from a temp repo outside $HOME, so no project
  # CLAUDE.md or AGENTS.md is in play, only the global one.
  project="$tmp/project"
  mkdir -p "$project"
  git -C "$project" init -q
  printf '# Active context\n\n2026-10-26: Goal: migrate the PELICAN-7 importer to the v2 queue. Left: the retry path.\n' \
    >"$project/CLAUDE-activeContext.md"

  # Claude Code puts git status in its context, and an untracked file shows up
  # there by name, so the model would find the goal without ever being told
  # where to look. A control run proved it: the goal stored as CLAUDE-context.md
  # was found while untracked and missed once excluded. The deployed global
  # ignore hides the file only on a machine that has run the installer, so the
  # repo excludes it itself.
  echo CLAUDE-activeContext.md >>"$project/.git/info/exclude"
  question='What goal is currently in flight for this project? One sentence.'

  # Both facts must come back. The code name alone could appear in "I couldn't
  # find PELICAN-7", but the queue appears only in the file.
  found() {
    case "$1" in
      *PELICAN-7*) case "$1" in *[Vv]2\ queue*) return 0 ;; esac ;;
    esac
    return 1
  }

  # --tools is variadic, so another flag follows it to end the list.
  if command -v claude >/dev/null 2>&1; then
    answer=$(cd "$project" && claude -p --tools Read --model haiku "$question" 2>&1)
    if found "$answer"; then
      pass "Claude Code reads CLAUDE-activeContext.md"
    else
      fail "Claude Code did not find the goal. It said: $answer"
    fi
  else
    skip "claude not installed"
  fi

  # Not run on a machine with Codex installed since this check was written.
  # Codex has a shell and can ls the directory, so a pass shows the file is
  # reachable, not that ~/.codex/AGENTS.override.md sent it there.
  if command -v codex >/dev/null 2>&1; then
    answer=$(cd "$project" && codex exec "$question" 2>&1)
    if found "$answer"; then
      pass "Codex reaches CLAUDE-activeContext.md (it can ls, so this is weaker than the Claude check)"
    else
      fail "Codex did not find the goal. Last lines: $(printf '%s\n' "$answer" | tail -5)"
    fi
  else
    skip "codex not installed"
  fi
fi

if [ "$failures" -gt 0 ]; then
  exit 1
fi
