#!/usr/bin/env bash
#==============================================================================
#  Claude Code Notification hook — a macOS banner when Claude is blocked on me
#==============================================================================
# Wired from ~/.claude/settings.json:
#
#   "Notification": [{ "hooks": [{ "type": "command",
#     "command": "$HOME/.claude/hooks/notify.sh" }] }]
#
# settings.json itself is not tracked in this repo — it is mostly state Claude
# writes for itself (model, enabledPlugins, the atuin hooks) and would fight a
# symlink. Only this script is deployed; the four lines above are the manual
# step on a new machine, and they are repeated in CLAUDE.md and README.MD.
#
# ONLY the `Notification` event is hooked. That event fires when Claude is
# actually waiting on me — a permission prompt, or an idle question. Stop and
# PostToolUse were considered and rejected: a banner per turn is noise, and
# noise is what teaches you to leave Do Not Disturb on.
#
# The payload arrives as JSON on stdin — `.message` is why Claude is waiting,
# `.cwd` is the project. stdin can only be drained once, so it is read into a
# variable before jq is pointed at it twice.
#
# No `set -e`: a hook that exits non-zero is reported as a hook failure in the
# transcript. A notification is best-effort decoration, so every branch here
# falls back to a default and exits 0.

command -v terminal-notifier >/dev/null 2>&1 || exit 0

payload=$(cat)

message=$(jq -r '.message // empty' <<<"$payload" 2>/dev/null)
[ -n "$message" ] || message="Claude Code needs your input."

cwd=$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"
project=$(basename "$cwd")

# Clicking the banner focuses the terminal Claude is waiting in. macOS sets
# __CFBundleIdentifier on the whole process tree launched from an app bundle,
# so this names the real host (Ghostty here, iTerm or VS Code elsewhere) with
# no lookup table. It is absent when Claude Code was not launched from a bundle
# — over ssh, from cron — and then the flag is simply left off.
#
# Deliberately -activate and NOT -sender. -sender would additionally swap the
# banner's icon to that app, which is the nicer look, but it hangs: measured on
# macOS 26.6.1 with terminal-notifier 2.0.0, naming a running app made it block
# indefinitely (2/2 for Ghostty and for Claude), while a non-running app and a
# bogus id both returned instantly. The host terminal is by definition running.
# terminal-notifier has no timeout of its own and Claude Code waits on hook
# commands, so that hang would stall the turn to win an icon.
activate=()
[ -n "${__CFBundleIdentifier:-}" ] && activate=(-activate "$__CFBundleIdentifier")

# -group replaces the previous banner for the same project instead of stacking
# a new one on every prompt — Notification can fire several times in a turn.
terminal-notifier \
  -title "Claude Code" \
  -subtitle "$project" \
  -message "$message" \
  -group "claude-code-$project" \
  "${activate[@]}" \
  -sound default >/dev/null 2>&1

exit 0
