#!/usr/bin/env bash
#==============================================================================
#  Claude Code status line — plan usage on screen at all times
#==============================================================================
# Wired from ~/.claude/settings.json:
#
#   "statusLine": { "type": "command",
#     "command": "$HOME/.claude/statusline.sh", "padding": 0 }
#
# settings.json is not tracked in this repo — same story as hooks/notify.sh: it
# is mostly state Claude writes for itself and would fight a symlink. Only this
# script is deployed; the block above is the manual step on a new machine, and
# it is repeated in CLAUDE.md and README.MD.
#
# WHY THIS EXISTS: `/usage` and `/context` both answer the question on demand,
# and by the time you think to ask, the 5-hour window is usually already the
# reason you asked. The status line is the only always-on surface Claude Code
# offers, so the usage windows go here and nothing else competes for the space.
#
# It prints one row per window:
#
#   Current session  ███████░░░░░░░  52%  2h 14m left
#   Current week     ███████████░░░  81%  4d 9h left
#   Fable week       █████░░░░░░░░░  38%  4d 9h left
#   Context window   ████░░░░░░░░░░  31%  312K of 1.0M · Opus 5
#
# The rows are flush — no blank line between them — and that was tried both
# ways. Blank separators are also close to impossible here: Claude Code
# post-processes this script's output as, read off the 2.1.235 binary:
#
#   stdout.trim().split("\n").flatMap(u => u.trim() || []).join("\n")
#
# Every line is trimmed, and a line that trims to empty is *dropped* rather than
# rendered blank, so `join("\n\n")` and separators holding a space, an NBSP or
# a BOM all vanish — every one of them is whitespace to JS `trim()`. The single
# character that survives is U+200B: category Cf, not whitespace, zero columns.
# That is the escape hatch if the block ever wants a gap again; the same
# `.trim()` is also why no row here can be indented.
#
# The row order is deliberate and doubles as a fallback. Multi-line status
# lines render in full here, but if a future version ever clipped to the first
# line, the one that survives is the 5-hour window — the number that actually
# decides whether you can keep working.
#
# `Current session` and `Current week` are Claude Code's own names for these
# windows, taken from what `/usage` prints, so the two never disagree about
# which bar is which. `/usage` also floors its percentages rather than
# rounding, and so does this, for the same reason. `Fable week` is the one
# departure: `/usage` draws that bar as `Current week (Fable)`, which is 20
# columns against a 15-column label field, and widening the field to fit it
# would push every bar right to buy nothing.
#
# Countdowns rather than reset clock times: "resets 14:30" needs a subtraction
# before it means anything, and the question being asked is always "how long
# have I got", never "at what o'clock".
#
# Claude Code re-runs this on *every* render — it is on the interactive path in
# exactly the way `.zshrc` is, and is budgeted the same way. Hence: one jq
# process on the hot path, and nothing else. No git, no `date`, no per-field
# subshell. jq does the arithmetic, the countdown, the bars and the ANSI, and
# prints the finished block. The only other thing that ever runs is the
# refresher below, in the background, at most once per five minutes.
#
# TWO SOURCES, NOT ONE. Claude Code's stdin carries the 5-hour and 7-day windows
# but not the Fable one, and it carries them only when *this session* has seen
# them — so the script also reads a small cache of the `/api/oauth/usage`
# response, the same endpoint `/usage` itself calls. Why both, rather than the
# cache alone: stdin is live, refreshed from the response headers of every
# turn, while the cache is up to five minutes old. Stdin wins when it has a
# window; the cache fills in what stdin lacks.
#
# The Fable window has been "tracked but not forwarded" for a while, and each
# version has moved it without exposing it:
#
#   2.1.258  read off the `anthropic-ratelimit-unified-7d_oi-*` headers into
#            `seven_day_overage_included`, labelled "Fable limit" internally
#            and drawn by `/usage` as `Current week (Fable)` — but the object
#            handed to this script is rebuilt from `five_hour`, `seven_day`
#            and (gateway-only) `spend_limit` alone, so the key is dropped.
#   2.1.266  same builder, same three keys. A new `rate_limits.model_scoped[]`
#            array does carry per-model weekly windows with a server-supplied
#            `display_name` of "Fable", but it lives on the usage snapshot
#            handed to the SDK and remote clients, not on the status line's
#            stdin. 2.1.266 also started persisting the `/usage` response as
#            `cachedUsageUtilization` in ~/.claude.json, but only after
#            `/usage` is opened and only for an hour, so it is not a source an
#            always-on row can lean on — and parsing an 85KB file per render
#            would blow the budget anyway.
#
# So the row keeps a reader for `seven_day_overage_included` — free, and it
# takes over the day the field is forwarded — and gets its numbers from the
# cache until then.
#
# THE CACHE. `$XDG_CACHE_HOME/claude-usage.json` is the endpoint's JSON plus a
# `fetched_at` epoch stamp, written atomically (tmp + mv) so a render never
# reads a half-written file. jq reads it with `--slurpfile` in the *same*
# process that renders the rows, so the hot path is still one jq; a missing
# file is fed as /dev/null, which slurps to `[]`, so nothing has to exist for
# the script to work. Two thresholds, both borrowed from Claude Code's own
# `/usage` code so the two agree about freshness:
#
#   5 minutes  the endpoint's client-side TTL (`rxo` in the 2.1.266 binary).
#              Older than this and jq appends a `REFRESH` marker line, which
#              the shell strips and answers by spawning the refresher.
#   1 hour     the persisted-cache lifetime (`nxo`). Older than this and the
#              cached rows are hidden rather than shown stale — the usual
#              cause is an expired OAuth token, which Claude Code refreshes on
#              its own; the row returns once it has.
#
# THE REFRESHER is the only part that costs anything, and it never runs on the
# hot path. It is backgrounded with stdin, stdout and stderr all pointed at
# /dev/null, and that is load-bearing: Claude Code reads this script's stdout
# to EOF, and a child holding the pipe open would freeze the status line for
# the length of the fetch. The token comes from the `Claude Code-credentials`
# keychain item Claude Code itself writes (via `security`, which is how Claude
# Code reads it too, so the ACL is already there), and reaches curl through
# `-K -` on stdin rather than on the command line, so it never sits in `ps`
# output for the duration of the request. A lock directory (`mkdir` is atomic)
# stops a slow fetch from being duplicated by every render in the meantime;
# one older than two minutes is treated as left by a killed refresher and
# removed. On any failure the refresher still restamps `fetched_at` over the
# previous data, so a dead endpoint costs one attempt per five minutes rather
# than one per render — and the stale-hiding rule above keeps old numbers from
# lingering on screen.
#
# The stdin schema below was read off the 2.1.235 binary rather than the docs,
# because these details are easy to get wrong and every one fails silently:
#
#   .rate_limits            absent entirely on API-key auth — it is built from
#                           `five_hour`/`seven_day` only when a subscription
#                           reports them, so every field here must be optional
#                           and a missing window drops its whole row.
#   .rate_limits.*.used_percentage    0-100 (utilization × 100), not a fraction.
#   .rate_limits.*.resets_at          ISO 8601 string, nullable. A *different*
#                           Claude Code schema carries the same key as epoch
#                           seconds, so `secs` accepts both rather than
#                           betting on which one shows up.
#   .context_window.used_percentage   0-100, already rounded and clamped by the
#                           caller — and null until the first turn has usage.
#
# And the cache, i.e. the `/api/oauth/usage` response (schema from 2.1.269):
#
#   .five_hour / .seven_day .utilization is 0-100 here too, and .resets_at is
#                           an ISO string. It was a 0-1 *fraction* on 2.1.266
#                           and this script scaled it ×100; 2.1.269 returns
#                           5.0 and 28.0 for 5% and 28%, and its own `/usage`
#                           floors the value as-is (`Math.floor(a.utilization)`
#                           in the binary) while the header-derived path now
#                           multiplies *its* fraction by 100 to match. So no
#                           scaling: the ×100 is what drew 500% and a bar
#                           five times the width of the terminal.
#   .limits[]               the per-model windows. `.percent` is already 0-100,
#                           `.scope.model.display_name` is the label ("Fable"),
#                           and entries without a model scope are other kinds
#                           of limit and are skipped.
#
# Colors are voltage (themes/voltage.md) as 24-bit escapes. Not tput/ANSI-16:
# the palette's greens and oranges are not in the 16-color set, and the whole
# point of the heat ramp is that 78% and 92% look different at a glance. The
# empty half of each bar is drawn in `black` rather than `subtle`, so the track
# sits *behind* the label instead of competing with it.
#==============================================================================

# Best-effort, like the notification hook: a status line that errors just puts
# a stack trace where the usage numbers should be. No jq, no line.
command -v jq >/dev/null 2>&1 || exit 0

cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage.json"

refresh() {
  local lock="$cache.lock" tmp="$cache.tmp" token body
  mkdir -p "${cache%/*}"
  [ -d "$lock" ] && find "$lock" -maxdepth 0 -mmin +2 -exec rmdir {} \; 2>/dev/null
  mkdir "$lock" 2>/dev/null || return
  token=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null \
    | jq -r '.claudeAiOauth.accessToken // empty')
  body=''
  if [ -n "$token" ]; then
    body=$(curl -sf -m 5 -K - <<EOF
url = "https://api.anthropic.com/api/oauth/usage"
header = "Authorization: Bearer $token"
header = "anthropic-beta: oauth-2025-04-20"
header = "Content-Type: application/json"
EOF
    ) || body=''
  fi
  # New data if the fetch parsed, else the old data, restamped either way.
  local old=$cache; [ -r "$cache" ] || old=/dev/null
  jq -n --arg body "$body" --argjson t "$(date +%s)" --slurpfile old "$old" \
    '(($body | fromjson?) // $old[0] // {}) + {fetched_at: $t}' \
    >"$tmp" 2>/dev/null && mv -f "$tmp" "$cache"
  rmdir "$lock" 2>/dev/null
}

cache_in=$cache; [ -r "$cache" ] || cache_in=/dev/null
out=$(jq -r --slurpfile c "$cache_in" '
  def fg($r; $g; $b): "\u001b[38;2;\($r);\($g);\($b)m";
  def off: "\u001b[0m";

  def subtle:  fg(107; 107; 107);
  def track:   fg( 57;  58;  61);
  def green:   fg(179; 224;  83);
  def yellow:  fg(249; 233;   6);
  def orange:  fg(255; 154;  77);
  def red:     fg(255;  77;  94);

  # jq returns null for `"x" * 0`, which would poison every string it touches.
  def rep($s; $n): if $n > 0 then ($s * $n) else "" end;
  def padr($s; $n): $s + rep(" "; $n - ($s | length));
  def padl($s; $n): rep(" "; $n - ($s | length)) + $s;

  # One ramp for every bar, so they read the same way without a legend.
  def heat($p):
    if   $p >= 90 then red
    elif $p >= 75 then orange
    elif $p >= 50 then yellow
    else green
    end;

  # floor, not round, so the bar only fills completely at a genuine 100% —
  # a full bar at 97% is the one reading that would make you stop early. The
  # max() keeps any non-zero usage showing at least one cell.
  def bar($p; $w):
    (if $p <= 0 then 0 else ([$p / 100 * $w | floor, 1] | max) end) as $n
    | "\(heat($p))\(rep("█"; $n))\(track)\(rep("░"; $w - $n))\(off)";

  # Both accepted forms of resets_at, normalised to epoch seconds. The two
  # subs are for the cache: the endpoint writes `23:09:59.873787+00:00`, and
  # jq 1.8 fromdateiso8601 takes only whole seconds ending in `Z`, so without
  # them every cached row silently lost its countdown (try/catch ate the
  # parse error). Stdin already sends `Z`, and the subs are no-ops on it.
  def secs($v):
    if $v == null then null
    else try (if ($v | type) == "number" then $v
              else ($v | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z")
                       | fromdateiso8601) end)
         catch null
    end;

  def countdown($v):
    secs($v) as $at
    | if $at == null then null
      else (($at - now) | floor) as $s
        | if   $s <= 0    then "resetting"
          elif $s >= 86400 then "\($s / 86400 | floor)d \(($s % 86400) / 3600 | floor)h left"
          elif $s >= 3600  then "\($s / 3600  | floor)h \(($s % 3600)  / 60   | floor)m left"
          else                  "\([$s / 60 | ceil, 1] | max)m left"
          end
      end;

  def tokens($n):
    if   $n >= 1000000 then "\(($n / 100000 | floor) / 10)M"
    elif $n >= 1000    then "\($n / 1000 | floor)K"
    else "\($n)"
    end;

  def row($label; $p; $tail):
    ($p | floor) as $v
    | "\(subtle)\(padr($label; 15))\(off) \(bar($v; 14)) \(heat($v))\(padl("\($v)%"; 4))\(off)"
      + (if $tail then "  \(subtle)\($tail)\(off)" else "" end);

  # The cache, or {} when the file is missing (/dev/null slurps to []).
  ($c[0] // {}) as $cache
  | ($cache.fetched_at // 0) as $at
  | ($at > now - 3600) as $fresh
  | ($at < now - 300) as $stale

  # A cached window reshaped to the stdin one, so `row` needs only one form.
  # Empty, not null, when absent — `//` then falls through cleanly.
  | def cached($k):
      if $fresh then
        $cache[$k]
        | select(. and .utilization != null)
        | {used_percentage: .utilization, resets_at}
      else empty end;

  .model.display_name as $model
  | [
      ((.rate_limits.five_hour // cached("five_hour"))
       | select(. and .used_percentage != null)
       | row("Current session"; .used_percentage; countdown(.resets_at))),

      ((.rate_limits.seven_day // cached("seven_day"))
       | select(. and .used_percentage != null)
       | row("Current week"; .used_percentage; countdown(.resets_at))),

      # Stdin first, should the key ever be forwarded; the cache otherwise.
      ((.rate_limits.seven_day_overage_included
        | select(. and .used_percentage != null)
        | row("Fable week"; .used_percentage; countdown(.resets_at)))
       // (if $fresh then
             $cache.limits[]?
             | select(.scope.model.display_name and .percent != null)
             | row("\(.scope.model.display_name) week"; .percent; countdown(.resets_at))
           else empty end)),

      (.context_window
       | select(. and .used_percentage != null)
       | row("Context window"; .used_percentage;
             "\(tokens(.total_input_tokens // 0)) of \(tokens(.context_window_size // 0))"
             + (if $model then " · \($model)" else "" end))),

      (if $stale then "REFRESH" else empty end)
    ]
  | join("\n")
')

# The marker rides on the last line so the strip is two parameter expansions,
# not a process. It is emitted only when the cache is past its five minutes.
case $out in
  *$'\n'REFRESH | REFRESH)
    out=${out%REFRESH}
    out=${out%$'\n'}
    refresh </dev/null >/dev/null 2>&1 &
    ;;
esac

printf '%s\n' "$out"
