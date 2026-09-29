#!/usr/bin/env bash
#
# Splices the StevenBlack "unified + porn" blocklist into /etc/hosts between
# #BLOCKLIST-BEGIN# / #BLOCKLIST-END# markers. Re-running it swaps in a fresh
# copy of the list, which makes it the refresh command too:
#
#     ./setup/hosts.sh
#
# Spliced rather than symlinked or tracked. FlyEnv owns its own marker block in
# the same file (#X-HOSTS-BEGIN# … #X-HOSTS-END#) and rewrites it whenever a
# local site is added, so a symlink into this repo would have FlyEnv editing a
# tracked file — the hazard CLAUDE.md warns about. A tracked copy of the list
# itself would be ~150k lines, 4 MB, and stale within a week. So only this
# script is tracked: everything outside the markers, FlyEnv's block and Apple's
# localhost lines included, is carried through untouched.
#
# No scheduled refresh. /etc/hosts is root-owned, so keeping it current would
# take a root LaunchDaemon holding a curl-to-root-file pipeline, which is a
# worse trade than a list that is a few weeks old. Run this by hand instead.
#
# To undo it, delete the lines from #BLOCKLIST-BEGIN# to #BLOCKLIST-END#
# inclusive; nothing else in the file depends on them.
set -uo pipefail

LIST_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
HOSTS=/etc/hosts
BEGIN_MARKER="#BLOCKLIST-BEGIN#"
END_MARKER="#BLOCKLIST-END#"

# A truncated download still parses as a valid hosts file, just a nearly empty
# one, and installing it would quietly turn the blocking off. The real list is
# ~150k entries; well under that means something went wrong upstream or on the
# way down.
MIN_ENTRIES=50000

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

if ! curl -fsSL -o "$tmp_dir/upstream" "$LIST_URL"; then
  echo "Could not download $LIST_URL — /etc/hosts left unchanged." >&2
  exit 1
fi

# Only the 0.0.0.0 entries. Upstream's own header re-declares localhost and
# friends, which Apple's lines above the markers already cover, and ends with a
# self-referential "0.0.0.0 0.0.0.0" that blocks nothing. Trailing comments are
# stripped so every line is a bare "0.0.0.0 host".
grep '^0\.0\.0\.0 ' "$tmp_dir/upstream" \
  | grep -v '^0\.0\.0\.0 0\.0\.0\.0$' \
  | sed 's/[[:space:]]*#.*$//' >"$tmp_dir/entries"

entry_count="$(wc -l <"$tmp_dir/entries" | tr -d ' ')"
if [ "$entry_count" -lt "$MIN_ENTRIES" ]; then
  echo "Only $entry_count entries downloaded (expected $MIN_ENTRIES+) — /etc/hosts left unchanged." >&2
  exit 1
fi

# awk rather than sed for the strip: it prints every kept line with a newline,
# which also repairs a file whose last line has none — FlyEnv leaves its
# #X-HOSTS-END# marker that way, and a block appended straight after it would
# land on the same line.
{
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    index($0, begin) == 1 { skipping = 1 }
    !skipping { print }
    index($0, end) == 1 { skipping = 0 }
  ' "$HOSTS"
  echo "$BEGIN_MARKER StevenBlack/hosts unified + porn, fetched $(date +%Y-%m-%d)"
  cat "$tmp_dir/entries"
  echo "$END_MARKER"
} >"$tmp_dir/hosts.new"

# The date on the BEGIN line differs on every run, so compare without it; an
# unchanged list then needs no sudo and no cache flush.
if diff -q \
  <(grep -v "^$BEGIN_MARKER" "$HOSTS") \
  <(grep -v "^$BEGIN_MARKER" "$tmp_dir/hosts.new") >/dev/null; then
  echo "Blocklist already current ($entry_count entries)."
  exit 0
fi

# cp onto the existing file rather than mv: it keeps /etc/hosts's own owner,
# mode and inode, where mv would install a file owned by the temp dir's user.
if ! sudo cp "$HOSTS" "$HOSTS.bak" || ! sudo cp "$tmp_dir/hosts.new" "$HOSTS"; then
  echo "Could not write $HOSTS — left as it was (previous copy, if any, at $HOSTS.bak)." >&2
  exit 1
fi

# macOS caches resolver answers in mDNSResponder, so the new entries only take
# effect once it is told to drop them. Guarded on the binary rather than on the
# OS, so the script still runs clean anywhere else.
if command -v dscacheutil >/dev/null 2>&1; then
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
fi

echo "Blocklist installed: $entry_count entries (previous file at $HOSTS.bak)."
