#!/usr/bin/env bash
#==============================================================================
#  Resume a Claude Code session on its own once the usage limit resets
#==============================================================================
# Two halves in one file, the same split statusline.sh uses for --refresh:
#
#   (no args)  the StopFailure hook. Claude Code runs it when a turn dies on an
#              API error, and with the `rate_limit` matcher below that means
#              the plan's usage limit. It writes a marker naming the session
#              and nothing else; it cannot wait for the reset itself, because
#              Claude Code ignores a StopFailure hook's output and a hook that
#              sleeps for hours just holds the session open.
#   --sweep    run by the usage-refresh LaunchAgent (and the systemd service on
#              Linux) every 5 minutes, straight after the cache refresh. For
#              each marker, once the limits have room again, it resumes that
#              session headless with a "carry on" prompt.
#
# Wired from ~/.claude/settings.json, beside whatever StopFailure entry is
# already there rather than in place of it:
#
#   "StopFailure": [{ "matcher": "rate_limit", "hooks": [{ "type": "command",
#     "command": "$HOME/.claude/hooks/resume-after-limit.sh" }] }]
#
# settings.json is not tracked (see notify.sh's header for why), so those lines
# are the manual step on a new machine, repeated in CLAUDE.md.
#
# WHAT "ROOM AGAIN" MEANS. The sweep reads ~/.cache/claude-usage.json, the
# status line's cache, rather than doing its own date math on resets_at. Two
# conditions, both required:
#
#   - the cache was written after the marker. A cache from before the limit hit
#     can still read 97%, and resuming on that would just hit the wall again.
#   - no limit in it reads 100. Every window counts, the per-model weekly ones
#     included, because the marker does not say which window was hit. That is
#     conservative: a full Fable week holds back a session that never used
#     Fable, until that week resets too.
#
# The refresher restamps the cache even when its fetch fails, so an old reading
# can pass the first check. The cost of that is one wasted resume: the run hits
# the limit straight away, this hook writes the marker again, and the next sweep
# tries again. A rejected request is not billed.
#
# WHAT THE RESUME IS. `claude --resume <id> -p`, run from the session's own cwd
# through a login zsh. Headless, so it does not appear in the desktop app or a
# terminal while it runs; its output goes to a .log beside the marker, and a
# banner says it started. It runs under settings.json's defaultMode (auto).
# The login shell is load-bearing: launchd starts jobs with a four-entry PATH,
# and the resumed Claude's Bash tool would inherit it with no Homebrew, no rg
# and no claude. `.zprofile` is what builds the real PATH, and only a login
# shell reads it.
#
# It runs in the foreground, one marker after another. launchd kills a job's
# leftover children when the job exits, and foreground also means the next
# 5-minute tick cannot start a second resume of the same session while the
# first is still going. The cache does not refresh during a long resume; a live
# session's status line refreshes it on its own.
#
# The marker is removed *before* the resume starts, so a resume that hits the
# limit again re-arms itself through this same hook.
#
# NOT RESUMED: a session whose transcript was written to more than a minute
# after the marker. That means I already picked it up by hand, and a second
# writer on the same transcript would interleave with mine. The minute of slack
# is there because the API error lands in the transcript around the time the
# hook fires, and the docs do not say which comes first. A marker whose cwd or
# transcript no longer exists (a removed worktree) is dropped.
#
# No `set -e`, and every path exits 0, like notify.sh: a hook that exits
# non-zero shows up as a hook failure in the transcript, and launchd records a
# failed job forever after.

dir="${XDG_CACHE_HOME:-$HOME/.cache}"
markers="$dir/claude-resume"
cache="$dir/claude-usage.json"

prompt='Your previous turn ended because the usage limit was reached. The limit has reset. Carry on with the task from where it stopped. If it was already finished, say so and stop.'

command -v jq >/dev/null 2>&1 || exit 0

#------------------------------------------------------------------------------
# Hook half
#------------------------------------------------------------------------------

# @stdin  the StopFailure payload (session_id, cwd, transcript_path, error)
# @output writes $markers/<session_id>.json
record_limited_session() {
  local payload id
  payload=$(cat)

  [ "$(jq -r '.error // empty' <<<"$payload")" = rate_limit ] || return

  # The id becomes a file name. A UUID is all Claude Code hands out, and
  # anything else could carry a slash out of $markers.
  id=$(jq -r '.session_id // empty' <<<"$payload")
  [[ $id =~ ^[0-9a-fA-F-]{36}$ ]] || return

  mkdir -p "$markers"
  jq '{cwd, transcript: .transcript_path}' <<<"$payload" >"$markers/$id.json"
}

#------------------------------------------------------------------------------
# Sweep half
#------------------------------------------------------------------------------

# @param $1 marker file
# @return 0 when the cache is newer than the marker and no limit reads 100
limits_reset_since() {
  [ "$cache" -nt "$1" ] || return 1

  jq -e '[.five_hour.utilization, .seven_day.utilization, .limits[]?.percent]
    | map(. // 0) | max < 100' "$cache" >/dev/null 2>&1
}

# `date -r <file>` prints a file's mtime on both BSD and GNU date, which is
# why it is used here instead of stat, whose flags differ between the two.
#
# @param $1 marker file
# @param $2 transcript path
# @return 0 when the transcript changed more than a minute after the marker
session_continued_since() {
  local marked written
  marked=$(date -r "$1" +%s)
  written=$(date -r "$2" +%s)

  ((written > marked + 60))
}

# @param $1 the session's cwd
notify_resumed() {
  local message
  message="Resumed $(basename "$1") after the usage limit reset."

  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title 'Claude Code' -message "$message" >/dev/null 2>&1
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send 'Claude Code' "$message" >/dev/null 2>&1
  fi
}

# @param $1 session id
# @param $2 the session's cwd
# @output appends the headless run's output to $markers/<id>.log
resume_session() {
  local id=$1 cwd=$2

  notify_resumed "$cwd"

  (cd "$cwd" && exec zsh -lc 'exec claude --resume "$1" -p "$2"' zsh "$id" "$prompt") \
    >>"$markers/$id.log" 2>&1 </dev/null
}

# @output resumes, drops or leaves each marker in $markers
sweep_limited_sessions() {
  local marker id cwd transcript

  for marker in "$markers"/*.json; do
    [ -f "$marker" ] || continue

    id=$(basename "$marker" .json)
    cwd=$(jq -r '.cwd // empty' "$marker" 2>/dev/null)
    transcript=$(jq -r '.transcript // empty' "$marker" 2>/dev/null)

    if [ ! -d "$cwd" ] || [ ! -f "$transcript" ]; then
      rm -f "$marker"
      continue
    fi

    limits_reset_since "$marker" || continue

    if session_continued_since "$marker" "$transcript"; then
      rm -f "$marker"
      continue
    fi

    rm -f "$marker"
    resume_session "$id" "$cwd"
  done
}

if [ "${1:-}" = "--sweep" ]; then
  sweep_limited_sessions
  exit 0
fi

record_limited_session
exit 0
