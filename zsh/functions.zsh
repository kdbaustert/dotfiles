#!/usr/bin/env zsh

# Extract most know archives with one command
extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar e $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# GIT ADD, COMMIT & PUSH
function acp() {
  git add .
  git commit -m "$1"
  git push
}

function compress() {
  tar cvzf $1.tar.gz $1
}

# MAKE FOLDER AND CD INTO IT
mcd() {
  mkdir -p "$@" && cd "$@"
}

# CHECK SHELL
shell() {
  ps | grep $(echo $$) | awk '{ print $4 }'
}

# Create a data URL from a file
function dataurl() {
  local mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

#Create a new WordPress project install
install_wp() {

  if [ "$1" != "" ]; then
    PROJECT_NAME=$1

    # Main projects directory
    cd ~/Development

    #Create directory & cd into it
    mkdir $PROJECT_NAME
    cd $PROJECT_NAME

    # Create gitignore
    wp_gitignore

    echo "Setting up WordPress core.."

    wp core download
    wp core config \
      --dbname=$PROJECT_NAME \
      --dbuser="root" \
      --dbpass="root" \
      --dbprefix="wp_"

    wp db create

    echo "Running valet secure.."

    valet secure

    wp core install \
      --url="https://${PROJECT_NAME}.test" \
      --title="$PROJECT_NAME" \
      --admin_user="kenny" \
      --admin_password="password" \
      --admin_email="kenny@growwithom.com"

    # delete default installed plugins and themes we don't need
    echo "Cleaning up WordPress junk"

    wp plugin delete hello akismet
    wp theme delete twentynineteen twentyseventeen

    echo "New WordPress install complete"

    echo "https://${PROJECT_NAME}.test"

  else
    echo "Please enter a project name"
  fi
}

# Reload the zsh session, rebuilding the completion dump from scratch.
# (Adapted from OMZ:plugins/zsh_reload.)
#
# Use this after installing something whose completions you want *now* — the
# normal path only re-scans once every 24h (see zsh_compinit in zsh/zinit.zsh).
#
# The dump path must match the one zsh_compinit uses, or this would rebuild a
# file nothing reads: it previously wrote "$ZSH_CACHE_DIR/zcomp-$HOST" while
# compinit read ~/.zcompdump, so `zreload` never actually refreshed anything.
zreload() {
  local dump="${ZINIT[ZCOMPDUMP_PATH]:-${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/zcompdump}"
  autoload -Uz compinit zrecompile

  # Drop the old dump so compinit does a full, unconditional rescan.
  command rm -f "$dump" "$dump.zwc"
  compinit -i -d "$dump"

  # .zshrc byte-compiles itself (and the modules) on each start, so only the
  # dump needs an explicit recompile here.
  zrecompile -p "$dump" && command rm -f "$dump.zwc.old"

  # Use $SHELL if available; remove leading dash if login shell
  [[ -n "$SHELL" ]] && exec ${SHELL#-} || exec zsh
}

# Fuzzy-cd into a subdirectory (renamed from `fd` so it no longer shadows the
# `fd` binary that fzf/eza/etc. rely on). `z`/`zi` from zoxide cover most cases.
fcd() {
  local dir
  dir=$(find "${1:-.}" -path '*/\.*' -prune \
    -o -type d -print 2>/dev/null | fzf +m) &&
    cd "$dir"
}

# Full-disk ClamAV scan (aliased to `clamf`). Reports only — nothing is
# deleted or quarantined, so a false positive can't cost you a real file.
#
# Uses clamscan, NOT clamdscan: clamd runs as $USER and can't read most of
# the system, so a daemon-based full scan would silently skip nearly all of
# it. Root + the standalone scanner is the only combination that sees /.
#
# The /System/Volumes exclusion is the one that matters on macOS — the data
# volume is firmlinked in at /System/Volumes/Data, so without it every file
# on the disk gets scanned twice.
#
# Optional args are scan targets; with none it scans /. Passing a path is
# useful for a deep scan of one tree with the same reporting (and is how the
# verdict logic below gets tested without sitting through a full run).
clamfull() {
  local log="$HOME/clamav-full-scan.log"
  local tmp; tmp=$(mktemp)
  local -a targets
  if (( $# )); then targets=("$@"); else targets=(/); fi

  # Pre-create as $USER so the root scan appends to a file we still own,
  # rather than leaving a root-owned log in the home directory.
  [[ -f "$log" ]] || : >"$log"

  echo "Scanning ${targets[*]} — a full / scan takes hours. Log: $log"

  # --alert-exceeds-max is the clamscan equivalent of clamd.conf's
  # AlertExceedsMax; without it, files past the size/count limits are skipped
  # silently and the scan still says OK. It's a CLI flag only — the clamd.conf
  # setting does NOT apply here, since this runs the standalone scanner.
  #
  # caffeinate -i: don't let the machine idle-sleep mid-scan.
  sudo caffeinate -i clamscan -r -i \
    --alert-exceeds-max \
    --exclude-dir='^/dev' \
    --exclude-dir='^/Volumes' \
    --exclude-dir='^/System/Volumes' \
    --max-filesize=1000M \
    --max-scansize=1000M \
    --max-files=100000 \
    --log="$log" \
    "${targets[@]}" | tee "$tmp"

  # rc from clamscan, not tee. clamscan exits 1 on a detection, 2 on error.
  local rc=${pipestatus[1]}

  # "Heuristics.Limits.Exceeded.*" hits mean "too big to scan", NOT "infected".
  # clamscan keeps them out of its own "Infected files" tally but clamdscan does
  # not, and either way they push the exit code to 2 — so split them out here
  # rather than trusting the summary line.
  # NB: `grep -c` prints 0 *and* exits 1 when nothing matches, so the obvious
  # `$(grep -c ... || echo 0)` yields the two-line string "0\n0" and blows up
  # the arithmetic below. Assign first, then correct only on command failure.
  local total skipped real
  total=$(grep -c 'FOUND$' "$tmp" 2>/dev/null) || total=0
  skipped=$(grep -c 'Heuristics\.Limits\.Exceeded' "$tmp" 2>/dev/null) || skipped=0
  real=$(( total - skipped ))
  rm -f "$tmp"

  # Order matters. clamscan exits 2 — normally "error" — when a file merely
  # exceeds the limits, so checking rc first would report a big git pack as a
  # failed scan. Real detections are decided by the parsed output, not rc.
  if [[ $real -gt 0 ]]; then
    echo "INFECTED: $real detection(s). See $log"
    rc=1
  elif [[ $rc -gt 1 && $skipped -eq 0 ]]; then
    echo "Scan ended with errors (exit $rc). See $log"
  else
    echo "Clean — no infections found."
    rc=0
  fi
  (( skipped > 0 )) && \
    echo "Note: $skipped file(s) too large/complex to scan — grep 'Limits.Exceeded' $log"

  return $rc
}
