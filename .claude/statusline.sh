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
# It prints three rows, one per window:
#
#   Current session  ███████░░░░░░░  52%  2h 14m left
#   Current week     ███████████░░░  81%  4d 9h left
#   Context window   ████░░░░░░░░░░  31%  312K of 1.0M · Opus 5
#
# The row order is deliberate and doubles as a fallback. Multi-line status
# lines render in full here, but if a future version ever clipped to the first
# line, the one that survives is the 5-hour window — the number that actually
# decides whether you can keep working.
#
# `Current session` and `Current week` are Claude Code's own names for these
# windows, taken from what `/usage` prints, so the two never disagree about
# which bar is which. `/usage` also floors its percentages rather than
# rounding, and so does this, for the same reason.
#
# Countdowns rather than reset clock times: "resets 14:30" needs a subtraction
# before it means anything, and the question being asked is always "how long
# have I got", never "at what o'clock".
#
# Claude Code re-runs this on *every* render — it is on the interactive path in
# exactly the way `.zshrc` is, and is budgeted the same way. Hence: one jq
# process, and nothing else. No git, no `date`, no per-field subshell. jq does
# the arithmetic, the countdown, the bars and the ANSI, and prints the finished
# block. `exec` so the shell doesn't linger waiting on it.
#
# The input schema below was read off the 2.1.235 binary rather than the docs,
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
# Colors are voltage (themes/voltage.md) as 24-bit escapes. Not tput/ANSI-16:
# the palette's greens and oranges are not in the 16-color set, and the whole
# point of the heat ramp is that 78% and 92% look different at a glance. The
# empty half of each bar is drawn in `black` rather than `subtle`, so the track
# sits *behind* the label instead of competing with it.
#==============================================================================

# Best-effort, like the notification hook: a status line that errors just puts
# a stack trace where the usage numbers should be. No jq, no line.
command -v jq >/dev/null 2>&1 || exit 0

exec jq -r '
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

  # One ramp for all three bars, so they read the same way without a legend.
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

  # Both accepted forms of resets_at, normalised to epoch seconds.
  def secs($v):
    if $v == null then null
    else try (if ($v | type) == "number" then $v else ($v | fromdateiso8601) end)
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

  .model.display_name as $model
  | [
      (.rate_limits.five_hour
       | select(. and .used_percentage != null)
       | row("Current session"; .used_percentage; countdown(.resets_at))),

      (.rate_limits.seven_day
       | select(. and .used_percentage != null)
       | row("Current week"; .used_percentage; countdown(.resets_at))),

      (.context_window
       | select(. and .used_percentage != null)
       | row("Context window"; .used_percentage;
             "\(tokens(.total_input_tokens // 0)) of \(tokens(.context_window_size // 0))"
             + (if $model then " · \($model)" else "" end)))
    ]
  | join("\n")
'
