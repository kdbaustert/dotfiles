#==============================================================================
#  osc7.zsh — report the shell's working directory to the terminal (OSC 7)
#------------------------------------------------------------------------------
#  "New tab opens in the same directory" requires the terminal to know where the
#  shell actually is. Terminals learn that one of two ways:
#
#    1. Inspect the foreground process on their own pty and read its cwd.
#    2. Be told — the shell emits an OSC 7 escape sequence on every directory
#       change, carrying a file:// URI.
#
#  Route 1 is a guess, and it silently breaks whenever anything sits between the
#  terminal and the shell on a second pty: an agent that wraps the shell, mosh,
#  or a session multiplexer. The terminal reads the wrapper's cwd and opens the
#  new tab somewhere stale, with no error to explain it. (Kiro CLI used to do
#  exactly this here, which is what sent iTerm2 and Rio to the wrong directory
#  until it was removed.)
#
#  Route 2 is authoritative — the shell states where it is, and escape sequences
#  travel through any wrapper untouched. Ghostty emits OSC 7 from its own
#  injected shell integration, but that is Ghostty-only and rides on a ZDOTDIR
#  handoff. Emitting it here covers Ghostty, iTerm2 and Rio alike and keeps the
#  behavior independent of any vendor's integration. A duplicate report under
#  Ghostty is harmless: OSC 7 is idempotent state, not an event, so Ghostty
#  simply sees the same path twice.
#==============================================================================

# Percent-encode everything outside the URI "unreserved" set (plus '/', which is
# a legal path separator and must stay literal).
#
# LC_ALL=C is load-bearing, not hygiene: it makes ${#PWD} and $PWD[i] operate on
# BYTES. A multibyte character in a path has to be encoded one byte at a time —
# encoding it as a single "character" would emit a URI no terminal can decode.
_osc7_report_cwd() {
  emulate -L zsh
  local LC_ALL=C
  local enc="" c hex i

  for (( i = 1; i <= ${#PWD}; i++ )); do
    c=$PWD[i]
    if [[ $c == [A-Za-z0-9/._~-] ]]; then
      enc+=$c
    else
      printf -v hex '%%%02X' "'$c"   # "'x" is printf's "numeric value of x"
      enc+=$hex
    fi
  done

  # The host field is how a terminal decides the path is local and safe to
  # reuse; Rio logs "ignoring OSC 7 for non-local host" and drops the report
  # when it fails to match. $HOST is zsh's gethostname(), which is exactly what
  # the terminals compare against.
  printf '\033]7;file://%s%s\a' "$HOST" "$enc"
}

# chpwd covers every directory change (cd, pushd/popd, zoxide); the explicit
# call reports the directory the shell started in, which no hook would fire for.
if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _osc7_report_cwd
  _osc7_report_cwd
fi
