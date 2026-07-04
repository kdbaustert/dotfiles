#!/usr/bin/env zsh
#==============================================================================
#  notify.zsh — desktop notification when a long command finishes in Rio
#
#  Rio already raises native notifications for OSC 9 / OSC 777 escapes, but it
#  has no hook to fire one when an ordinary command completes. This adds that:
#  when a foreground command runs longer than a threshold AND Rio is not the
#  frontmost app (i.e. you've tabbed away), we post a notification via
#  terminal-notifier. Clicking it focuses Rio.
#
#  Tunables (export before this file is sourced, or at runtime):
#    RIO_NOTIFY_THRESHOLD   seconds a command must run to notify   (default 15)
#    RIO_NOTIFY_IGNORE      space-separated commands to never notify for
#    RIO_NOTIFY_DISABLE     set to any value to disable entirely
#==============================================================================

# Only meaningful in an interactive Rio session with terminal-notifier present.
[[ -o interactive ]] || return 0
[[ "$TERM" == rio* || "$TERM_PROGRAM" == rio ]] || return 0
command -v terminal-notifier &>/dev/null || return 0

: "${RIO_NOTIFY_THRESHOLD:=15}"
# Interactive / long-lived programs where a "finished" ping is just noise.
# An array so matching is exact per-element (a scalar would match substrings).
if (( ! ${+RIO_NOTIFY_IGNORE} )); then
  typeset -ga RIO_NOTIFY_IGNORE=(
    nvim vim vi nano less more man ssh tmux screen
    top htop btop watch fzf lazygit atuin bat
  )
fi

zmodload -F zsh/datetime b:strftime 2>/dev/null  # provides $EPOCHSECONDS
autoload -Uz add-zsh-hook

# Bundle ID of whatever app is frontmost, via LaunchServices (no AppleScript
# prompt, ~a few ms). Empty on failure.
_rio_front_bundleid() {
  local asn
  asn=$(lsappinfo front 2>/dev/null) || return 1
  lsappinfo info -only bundleID "$asn" 2>/dev/null | sed -E 's/.*=\"?([^"]*)\"?$/\1/'
}

# preexec: stamp the start time and remember the command line.
_rio_notify_preexec() {
  _RIO_NOTIFY_CMD="$1"
  _RIO_NOTIFY_START=$EPOCHSECONDS
}

# precmd: runs before each prompt. Capture $? first — it's the exit status of
# the command that just finished.
_rio_notify_precmd() {
  local exit_status=$?

  [[ -n "$RIO_NOTIFY_DISABLE" ]] && return
  [[ -z "$_RIO_NOTIFY_START" ]] && return   # nothing ran (empty prompt / Ctrl-C at prompt)

  local elapsed=$(( EPOCHSECONDS - _RIO_NOTIFY_START ))
  local cmd="$_RIO_NOTIFY_CMD"
  unset _RIO_NOTIFY_START _RIO_NOTIFY_CMD

  (( elapsed < RIO_NOTIFY_THRESHOLD )) && return

  # Skip ignored commands (match on the first word of the command line).
  local first="${${(z)cmd}[1]}"
  first="${first:t}"                        # basename, e.g. /usr/bin/ssh -> ssh
  if (( ${RIO_NOTIFY_IGNORE[(Ie)$first]} )); then return; fi

  # Don't nag if Rio is already the window you're looking at.
  [[ "$(_rio_front_bundleid)" == com.raphaelamorim.rio ]] && return

  # Format elapsed time as e.g. 1m03s / 42s.
  local human
  if (( elapsed >= 60 )); then
    human="$(( elapsed / 60 ))m$(printf '%02d' $(( elapsed % 60 )))s"
  else
    human="${elapsed}s"
  fi

  local icon title
  if (( exit_status == 0 )); then
    icon="✅"; title="Done in ${human}"
  else
    icon="❌"; title="Failed (${exit_status}) after ${human}"
  fi

  terminal-notifier \
    -title "${icon} ${title}" \
    -subtitle "${cmd}" \
    -message "${PWD/#$HOME/~}" \
    -sender com.raphaelamorim.rio \
    -activate com.raphaelamorim.rio \
    &>/dev/null
}

add-zsh-hook preexec _rio_notify_preexec
add-zsh-hook precmd  _rio_notify_precmd
