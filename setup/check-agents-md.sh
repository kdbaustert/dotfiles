#!/usr/bin/env bash
#
# Checks the repo's agent instructions: AGENTS.md is the real file and
# CLAUDE.md is a relative symlink to it. Not an installer step. Nothing here
# deploys or writes anything, and SETUP_SCRIPTS has no reason to name it.
#
# WHY A CHECK AND NOT TRUST. The link breaks without a sound. GNU `sed -i` (and
# `perl -i`, and any editor that saves by rename) replaces CLAUDE.md with a
# regular file holding a copy of the text (measured). Claude Code
# keeps loading that copy, Codex keeps loading AGENTS.md, and the two drift
# from the next edit on. Git reports it only as `typechange: CLAUDE.md`, which
# is easy to commit past. Claude Code's own Edit tool is safe: it refuses to
# write through a symlink and names the target instead.
#
# The size cap is Codex's default project_doc_max_bytes, 32 KiB. Codex cuts a
# project doc off at that limit without warning, so the rules at the bottom of
# the file are the ones lost. ~/.codex/config.toml may raise the limit, but
# that file is untracked and set by hand, so this repo shouldn't depend on it.
#
# Usage:
#   setup/check-agents-md.sh          link and size checks; free, under a second
#   setup/check-agents-md.sh --eval   also asks Claude Code (haiku, paid) and,
#                                     when it is installed, Codex whether each
#                                     actually loads the file from the repo root
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
limit=32768
failures=0

pass() { echo "ok:   $1"; }
fail() { echo "FAIL: $1" >&2; failures=$((failures + 1)); }
skip() { echo "skip: $1"; }

if [ -f "$root/AGENTS.md" ] && [ ! -L "$root/AGENTS.md" ]; then
  pass "AGENTS.md is a regular file"
else
  fail "AGENTS.md is missing or is itself a link; it should hold the text"
fi

# readlink with no flags prints the stored target, so an absolute target that
# happens to resolve to the same file still fails. It has to be relative to
# work on every machine this repo is cloned to.
if [ -L "$root/CLAUDE.md" ] && [ "$(readlink "$root/CLAUDE.md")" = "AGENTS.md" ]; then
  pass "CLAUDE.md -> AGENTS.md"
else
  fail "CLAUDE.md is not a relative symlink to AGENTS.md. Copy any edits made to it into AGENTS.md, then run: ln -sf AGENTS.md \"$root/CLAUDE.md\""
fi

if [ -f "$root/AGENTS.md" ]; then
  size=$(wc -c <"$root/AGENTS.md" | tr -d ' ')
  if [ "$size" -le "$limit" ]; then
    pass "AGENTS.md is $size bytes (limit $limit)"
  else
    fail "AGENTS.md is $size bytes, over Codex's default project_doc_max_bytes ($limit); move detail to setup/REFERENCE.md"
  fi
fi

if [ "${1:-}" = "--eval" ]; then
  # The question can only be answered from AGENTS.md: link_dotfiles appears in
  # neither the global CLAUDE.md nor the rules files, and with --tools "" the
  # model can't go and read setup/lib.sh to find it.
  question='According to your project instructions, which shell function in setup/lib.sh holds every symlink? Reply with the function name only.'

  # --tools is variadic and would swallow the question as a tool name if it
  # came last, so another flag has to follow it to end the list.
  if command -v claude >/dev/null 2>&1; then
    answer=$(cd "$root" && claude -p --tools "" --model haiku "$question" 2>&1)
    case "$answer" in
      *link_dotfiles*) pass "Claude Code loads AGENTS.md through CLAUDE.md" ;;
      *) fail "Claude Code did not answer from AGENTS.md. It said: $answer" ;;
    esac
  else
    skip "claude not installed"
  fi

  # `codex debug prompt-input` prints what the model would be sent; it is
  # how setup/REFERENCE.md measures the byte limit (codex-cli 0.164).
  # Untested with Codex installed.
  if command -v codex >/dev/null 2>&1; then
    if prompt=$(cd "$root" && codex debug prompt-input 2>&1) && [[ "$prompt" == *"link_dotfiles"* ]]; then
      pass "Codex loads AGENTS.md"
    else
      fail "Codex prompt input does not contain AGENTS.md. Last lines: $(printf '%s\n' "$prompt" | tail -5)"
    fi
  else
    skip "codex not installed"
  fi
fi

if [ "$failures" -gt 0 ]; then
  exit 1
fi
